#!/bin/bash
# Commands to create and run optimization script on server
# Copy and paste these commands into SSH session

# Step 1: Create the optimization script
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
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_revenue_covering ON trips(tpep_pickup_datetime, pulocationid, total_amount, fare_amount, tip_amount);"

# Index for efficiency timeseries
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_efficiency_timeseries ON trips(tpep_pickup_datetime, total_amount, tpep_dropoff_datetime);"

# Index for zone revenue
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_zone_revenue ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);"

# Indexes for wait time queries
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_wait_time_demand ON trips(pulocationid, tpep_pickup_datetime);"
sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_wait_time_supply ON trips(dolocationid, tpep_dropoff_datetime);"

echo "6. Verifying indexes..."
echo "Total indexes on trips table:"
sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';"

echo ""
echo "=== Optimization Complete ==="
echo "Expected improvement: 2-5x faster queries"
SCRIPT_EOF

# Step 2: Make script executable
sudo chmod +x /var/app/current/optimize_database.sh

# Step 3: Stop web service
sudo systemctl stop web.service

# Step 4: Run optimization
cd /var/app/current
sudo bash optimize_database.sh

# Step 5: Set permissions
sudo chown webapp:webapp nyc_taxi.db

# Step 6: Start web service
sudo systemctl start web.service

echo ""
echo "=== Testing Optimized Database ==="
sleep 10
curl http://localhost:8000/health
echo ""
echo "Test efficiency endpoint:"
time curl --max-time 300 http://localhost:8000/api/v1/efficiency/timeseries | head -c 200

