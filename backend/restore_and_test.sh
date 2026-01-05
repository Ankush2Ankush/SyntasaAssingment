#!/bin/bash
# Complete database restoration and testing script
# Run this in your SSH session

echo "=== Restoring Database and Testing Endpoints ==="
echo ""

# Stop service
echo "1. Stopping web service..."
sudo systemctl stop web.service
echo "✅ Service stopped"
echo ""

# Download database from S3
echo "2. Downloading database from S3 (5.4 GB)..."
echo "   This will take 10-15 minutes..."
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
if [ $? -eq 0 ]; then
    echo "✅ Database downloaded"
else
    echo "❌ Download failed"
    exit 1
fi
echo ""

# Set permissions
echo "3. Setting permissions..."
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
echo "✅ Permissions set"
echo ""

# Verify database
echo "4. Verifying database..."
TRIP_COUNT=$(sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;')
INDEX_COUNT=$(sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")
echo "Trips: $TRIP_COUNT"
echo "Indexes: $INDEX_COUNT"
echo ""

# Start service
echo "5. Starting web service..."
sudo systemctl start web.service
sleep 10
echo "✅ Service started"
echo ""

# Test endpoints
echo "6. Testing endpoints..."
echo ""
echo "=== Health Endpoint ==="
curl http://localhost:8000/health
echo ""
echo ""

echo "=== Overview Endpoint (should be fast with indexes) ==="
time curl --max-time 300 http://localhost:8000/api/v1/overview | head -c 200
echo ""
echo ""

echo "=== Efficiency Timeseries Endpoint (the one that was timing out) ==="
time curl --max-time 300 http://localhost:8000/api/v1/efficiency/timeseries | head -c 200
echo ""
echo ""

echo "=== Testing Complete ==="
echo "✅ All endpoints tested"
echo ""
echo "Now test from Vercel frontend:"
echo "https://hellosyntasa.vercel.app/api/v1/efficiency/timeseries"



