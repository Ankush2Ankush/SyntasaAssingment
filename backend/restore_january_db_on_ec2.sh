#!/bin/bash
# Restore January-only optimized database on EC2 instance
# Run this via SSH after uploading to S3

echo "=== Restoring January-Optimized Database ==="
echo ""

# Stop service
echo "1. Stopping web service..."
sudo systemctl stop web.service
sleep 3
echo "✅ Service stopped"
echo ""

# Navigate to app directory
cd /var/app/current

# Check current database
echo "2. Checking current database..."
if [ -f "nyc_taxi.db" ]; then
    CURRENT_SIZE=$(ls -lh nyc_taxi.db | awk '{print $5}')
    CURRENT_COUNT=$(sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips;" 2>/dev/null || echo "0")
    echo "   Current size: $CURRENT_SIZE"
    echo "   Current trips: $CURRENT_COUNT"
else
    echo "   No existing database found"
fi
echo ""

# Download from S3
echo "3. Downloading optimized database from S3..."
echo "   This will take 2-5 minutes for 951 MB..."
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db

if [ $? -eq 0 ]; then
    echo "✅ Database downloaded"
else
    echo "❌ Download failed"
    exit 1
fi
echo ""

# Set permissions
echo "4. Setting permissions..."
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
echo "✅ Permissions set"
echo ""

# Verify database
echo "5. Verifying database..."
NEW_SIZE=$(ls -lh nyc_taxi.db | awk '{print $5}')
TRIP_COUNT=$(sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips;")
INDEX_COUNT=$(sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")

echo "   New size: $NEW_SIZE"
echo "   Trip count: $TRIP_COUNT"
echo "   Index count: $INDEX_COUNT"
echo ""

# Verify it's January data only
NON_JAN_COUNT=$(sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips WHERE tpep_pickup_datetime < '2025-01-01' OR tpep_pickup_datetime >= '2025-02-01';")
if [ "$NON_JAN_COUNT" -eq 0 ]; then
    echo "   ✅ Database contains only January data"
else
    echo "   ⚠️  Warning: Found $NON_JAN_COUNT non-January trips"
fi
echo ""

# Start service
echo "6. Starting web service..."
sudo systemctl start web.service
sleep 10
echo "✅ Service started"
echo ""

# Check service status
echo "7. Checking service status..."
sudo systemctl status web.service --no-pager | head -10
echo ""

# Test endpoints
echo "8. Testing endpoints..."
echo ""
echo "=== Health Endpoint ==="
curl http://localhost:8000/health
echo ""
echo ""

echo "=== Overview Endpoint ==="
time curl --max-time 60 http://localhost:8000/api/v1/overview | head -c 300
echo ""
echo ""

echo "=== Efficiency Timeseries Endpoint ==="
time curl --max-time 60 http://localhost:8000/api/v1/efficiency/timeseries | head -c 500
echo ""
echo ""

echo "=== Complete ==="
echo ""
echo "✅ Database restored successfully"
echo "✅ Service restarted"
echo ""
echo "Next: Test the public endpoint:"
echo "https://hellosyntasa.vercel.app/api/v1/efficiency/timeseries"



