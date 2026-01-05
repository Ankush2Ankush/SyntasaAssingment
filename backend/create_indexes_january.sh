#!/bin/bash
# Create indexes for January data optimization
# Run this in your SSH session after deploying the updated code

echo "=== Creating Indexes for January Data ==="
echo ""

# Stop service to unlock database
echo "1. Stopping web service..."
sudo systemctl stop web.service
sleep 3
echo "✅ Service stopped"
echo ""

# Navigate to app directory
cd /var/app/current

# Check current database size
echo "2. Checking database status..."
DB_SIZE=$(ls -lh nyc_taxi.db | awk '{print $5}')
TRIP_COUNT=$(sudo sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;')
echo "Database size: $DB_SIZE"
echo "Trip count: $TRIP_COUNT"
echo ""

# Check if indexes already exist
echo "3. Checking for existing indexes..."
EXISTING_INDEXES=$(sudo sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';")
if [ ! -z "$EXISTING_INDEXES" ]; then
    echo "⚠️  Indexes already exist:"
    echo "$EXISTING_INDEXES"
    echo ""
    read -p "Do you want to recreate them? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping index creation."
        sudo systemctl start web.service
        exit 0
    fi
    echo "Dropping existing indexes..."
    sudo sqlite3 nyc_taxi.db "DROP INDEX IF EXISTS idx_pickup_datetime;"
    sudo sqlite3 nyc_taxi.db "DROP INDEX IF EXISTS idx_dropoff_datetime;"
    sudo sqlite3 nyc_taxi.db "DROP INDEX IF EXISTS idx_pulocationid;"
    sudo sqlite3 nyc_taxi.db "DROP INDEX IF EXISTS idx_dolocationid;"
    sudo sqlite3 nyc_taxi.db "DROP INDEX IF EXISTS idx_pickup_location_time;"
    sudo sqlite3 nyc_taxi.db "DROP INDEX IF EXISTS idx_dropoff_location_time;"
    echo "✅ Existing indexes dropped"
    echo ""
fi

# Create indexes
echo "4. Creating indexes (this will take 5-15 minutes for January data)..."
echo ""

echo "   Creating index 1/6: idx_pickup_datetime (critical for efficiency endpoint)..."
sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);"
echo "   ✅ Index 1/6 done"
echo ""

echo "   Creating index 2/6: idx_dropoff_datetime..."
sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);"
echo "   ✅ Index 2/6 done"
echo ""

echo "   Creating index 3/6: idx_pulocationid..."
sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);"
echo "   ✅ Index 3/6 done"
echo ""

echo "   Creating index 4/6: idx_dolocationid..."
sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);"
echo "   ✅ Index 4/6 done"
echo ""

echo "   Creating index 5/6: idx_pickup_location_time (composite)..."
sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);"
echo "   ✅ Index 5/6 done"
echo ""

echo "   Creating index 6/6: idx_dropoff_location_time (composite)..."
sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);"
echo "   ✅ Index 6/6 done"
echo ""

# Verify indexes
echo "5. Verifying indexes were created..."
INDEXES=$(sudo sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';")
echo "✅ Created indexes:"
echo "$INDEXES"
echo ""

# Set permissions
echo "6. Setting database permissions..."
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
echo "✅ Permissions set"
echo ""

# Check database size after indexing
echo "7. Checking database size after indexing..."
NEW_DB_SIZE=$(ls -lh nyc_taxi.db | awk '{print $5}')
echo "Database size before: $DB_SIZE"
echo "Database size after: $NEW_DB_SIZE"
echo ""

# Start service
echo "8. Starting web service..."
sudo systemctl start web.service
sleep 10
echo "✅ Service started"
echo ""

# Test endpoints
echo "9. Testing endpoints..."
echo ""
echo "=== Health Endpoint ==="
curl http://localhost:8000/health
echo ""
echo ""

echo "=== Overview Endpoint (should be fast now) ==="
time curl --max-time 30 http://localhost:8000/api/v1/overview | head -c 300
echo ""
echo ""

echo "=== Efficiency Timeseries Endpoint (the one that was timing out) ==="
time curl --max-time 60 http://localhost:8000/api/v1/efficiency/timeseries | head -c 500
echo ""
echo ""

echo "=== Done ==="
echo ""
echo "✅ Indexes created successfully!"
echo "✅ All endpoints should now respond quickly (5-30 seconds instead of timing out)"
echo ""
echo "Next steps:"
echo "1. Test the public endpoints from Vercel"
echo "2. Monitor query performance"
echo "3. If still slow, check nginx timeout settings (should be 300s)"



