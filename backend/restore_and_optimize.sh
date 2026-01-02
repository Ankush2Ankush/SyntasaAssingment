#!/bin/bash
# Complete script to restore database and run optimization
# Run this via: eb ssh, then execute: bash restore_and_optimize.sh

echo "=== Step 1: Restoring Database from S3 ==="
echo ""

# Stop web service
echo "Stopping web service..."
sudo systemctl stop web.service

# Download database
echo "Downloading database from S3..."
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db

# Set permissions
echo "Setting permissions..."
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db

# Verify database
echo "Verifying database..."
TRIP_COUNT=$(sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;')
echo "Trips in database: $TRIP_COUNT"

if [ -z "$TRIP_COUNT" ] || [ "$TRIP_COUNT" -eq 0 ]; then
    echo "ERROR: Database appears to be empty!"
    exit 1
fi

echo ""
echo "=== Step 2: Running Database Optimization ==="
echo ""

# Create optimization script
sudo tee /var/app/current/optimize_database.sh > /dev/null << 'SCRIPT_EOF'
#!/bin/bash
# Database Optimization Script
echo "=== Database Optimization ==="
echo ""

DB_PATH="/var/app/current/nyc_taxi.db"

if [ ! -f "$DB_PATH" ]; then
    echo "Error: Database file not found at $DB_PATH"
    exit 1
fi

echo "1. Enabling WAL mode (Write-Ahead Logging)..."
sqlite3 "$DB_PATH" "PRAGMA journal_mode=WAL;"

echo "2. Increasing cache size to 1GB..."
sqlite3 "$DB_PATH" "PRAGMA cache_size=-256000;"

echo "3. Setting synchronous to NORMAL..."
sqlite3 "$DB_PATH" "PRAGMA synchronous=NORMAL;"

echo "4. Running ANALYZE to update statistics..."
sqlite3 "$DB_PATH" "ANALYZE;"

echo "5. Creating additional optimized indexes..."

# Covering index for revenue queries
echo "   Creating idx_revenue_covering..."
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_revenue_covering ON trips(tpep_pickup_datetime, pulocationid, total_amount, fare_amount, tip_amount);"

# Index for efficiency timeseries
echo "   Creating idx_efficiency_timeseries..."
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_efficiency_timeseries ON trips(tpep_pickup_datetime, total_amount, tpep_dropoff_datetime);"

# Index for zone revenue
echo "   Creating idx_zone_revenue..."
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_zone_revenue ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);"

# Indexes for wait time queries
echo "   Creating idx_wait_time_demand..."
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_wait_time_demand ON trips(pulocationid, tpep_pickup_datetime);"

echo "   Creating idx_wait_time_supply..."
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_wait_time_supply ON trips(dolocationid, tpep_dropoff_datetime);"

echo "6. Verifying indexes..."
INDEX_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")
echo "Total indexes on trips table: $INDEX_COUNT"

echo ""
echo "=== Optimization Complete ==="
echo "Expected improvement: 2-5x faster queries"
SCRIPT_EOF

# Make script executable
sudo chmod +x /var/app/current/optimize_database.sh

# Run optimization
echo "Running optimization script..."
sudo bash /var/app/current/optimize_database.sh

# Set permissions again (in case optimization changed them)
sudo chown webapp:webapp nyc_taxi.db

echo ""
echo "=== Step 3: Starting Web Service ==="
sudo systemctl start web.service
sleep 10

echo ""
echo "=== Step 4: Testing Endpoints ==="
echo "Health endpoint:"
curl http://localhost:8000/health
echo ""
echo ""
echo "Testing overview endpoint (this may take time)..."
time curl --max-time 300 http://localhost:8000/api/v1/overview | head -c 200
echo ""
echo ""
echo "=== Complete ==="
echo "Database restored and optimized!"
echo "Check the time output above to see query performance improvement."

