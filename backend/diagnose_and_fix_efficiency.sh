#!/bin/bash
# Diagnose and fix efficiency endpoint timeout issues

echo "=== Diagnosing Efficiency Endpoint Issues ==="
echo ""

# 1. Check database file
echo "1. Checking database file..."
cd /var/app/current
ls -lh nyc_taxi.db
echo ""

# 2. Check if indexes exist (using sudo to avoid permission issues)
echo "2. Checking for indexes on trips table..."
INDEXES=$(sudo sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';")
if [ -z "$INDEXES" ]; then
    echo "❌ NO INDEXES FOUND - This is why queries are slow!"
    echo ""
    echo "3. Creating indexes (this will take 10-20 minutes)..."
    echo "   Stopping web service first..."
    sudo systemctl stop web.service
    sleep 3
    
    echo "   Creating index 1/6: idx_pickup_datetime..."
    sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);"
    echo "   ✅ Index 1/6 done"
    
    echo "   Creating index 2/6: idx_dropoff_datetime..."
    sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);"
    echo "   ✅ Index 2/6 done"
    
    echo "   Creating index 3/6: idx_pulocationid..."
    sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);"
    echo "   ✅ Index 3/6 done"
    
    echo "   Creating index 4/6: idx_dolocationid..."
    sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);"
    echo "   ✅ Index 4/6 done"
    
    echo "   Creating index 5/6: idx_pickup_location_time..."
    sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);"
    echo "   ✅ Index 5/6 done"
    
    echo "   Creating index 6/6: idx_dropoff_location_time..."
    sudo sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);"
    echo "   ✅ Index 6/6 done"
    
    echo ""
    echo "   Setting permissions..."
    sudo chown webapp:webapp nyc_taxi.db
    sudo chmod 664 nyc_taxi.db
    
    echo "   Starting web service..."
    sudo systemctl start web.service
    sleep 10
    
    echo ""
    echo "   Verifying indexes were created..."
    sudo sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
else
    echo "✅ Indexes found:"
    echo "$INDEXES"
    echo ""
    echo "3. Indexes already exist. Checking if web service needs restart..."
fi

echo ""
echo "4. Testing endpoints..."
echo ""
echo "=== Health Endpoint ==="
curl http://localhost:8000/health
echo ""
echo ""

echo "=== Efficiency Timeseries Endpoint (with 60s timeout) ==="
time curl --max-time 60 http://localhost:8000/api/v1/efficiency/timeseries | head -c 500
echo ""
echo ""

echo "=== Done ==="
echo ""
echo "If the efficiency endpoint still times out, the query might need optimization."
echo "The query groups 15M rows by hour, which can be slow even with indexes."


