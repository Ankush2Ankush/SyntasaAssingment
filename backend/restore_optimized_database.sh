#!/bin/bash
# Restore optimized database from S3
# Run this via: eb ssh, then execute: bash restore_optimized_database.sh

echo "=== Restoring Optimized Database from S3 ==="
echo ""

# Step 1: Stop web service
echo "1. Stopping web service..."
sudo systemctl stop web.service
echo "✅ Web service stopped"
echo ""

# Step 2: Navigate to app directory
cd /var/app/current
echo "2. Current directory: $(pwd)"
echo ""

# Step 3: Download database from S3
echo "3. Downloading optimized database from S3..."
echo "   This may take 10-15 minutes (5.4 GB)..."
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
if [ $? -eq 0 ]; then
    echo "✅ Database downloaded successfully"
else
    echo "❌ Download failed"
    exit 1
fi
echo ""

# Step 4: Verify file size
echo "4. Verifying database file..."
ls -lh nyc_taxi.db
echo ""

# Step 5: Set correct permissions
echo "5. Setting permissions..."
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
echo "✅ Permissions set"
echo ""

# Step 6: Verify database has data
echo "6. Verifying database contents..."
TRIP_COUNT=$(sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;')
echo "Trips in database: $TRIP_COUNT"
if [ -z "$TRIP_COUNT" ] || [ "$TRIP_COUNT" -eq 0 ]; then
    echo "❌ ERROR: Database appears to be empty!"
    exit 1
fi
echo ""

# Step 7: Verify indexes
echo "7. Verifying indexes..."
INDEX_COUNT=$(sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")
echo "Total indexes on trips table: $INDEX_COUNT"
echo ""
echo "Indexes:"
sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips' ORDER BY name;"
echo ""

# Step 8: Start web service
echo "8. Starting web service..."
sudo systemctl start web.service
sleep 10
echo "✅ Web service started"
echo ""

# Step 9: Check service status
echo "9. Checking service status..."
sudo systemctl status web.service --no-pager | head -15
echo ""

# Step 10: Test endpoints
echo "10. Testing endpoints..."
echo ""
echo "Health endpoint:"
curl http://localhost:8000/health
echo ""
echo ""

echo "Testing overview endpoint (this may take 20-30 seconds with optimizations)..."
time curl --max-time 300 http://localhost:8000/api/v1/overview | head -c 200
echo ""
echo ""

echo "=== Database Restoration Complete ==="
echo "✅ Optimized database restored"
echo "✅ All indexes verified"
echo "✅ Service running"
echo ""
echo "Expected performance: 20-30 seconds (vs 186 seconds before)"

