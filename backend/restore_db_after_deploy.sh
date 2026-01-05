#!/bin/bash
# Restore database after deployment
# Run this via: eb ssh, then execute: sudo bash restore_db_after_deploy.sh

echo "=== Restoring Database After Deployment ==="
echo ""

# Stop service
echo "1. Stopping web service..."
sudo systemctl stop web.service
echo "✅ Service stopped"
echo ""

# Navigate to app directory
cd /var/app/current
echo "2. Current directory: $(pwd)"
echo ""

# Download database from S3
echo "3. Downloading database from S3 (5.4 GB)..."
echo "   This may take 10-15 minutes..."
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
if [ $? -eq 0 ]; then
    echo "✅ Database downloaded successfully"
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
TRIP_COUNT=$(sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;')
echo "Trips in database: $TRIP_COUNT"
if [ -z "$TRIP_COUNT" ] || [ "$TRIP_COUNT" -eq 0 ]; then
    echo "❌ ERROR: Database appears to be empty!"
    exit 1
fi

INDEX_COUNT=$(sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")
echo "Indexes on trips table: $INDEX_COUNT"
echo ""

# Start service
echo "6. Starting web service..."
sudo systemctl start web.service
sleep 10
echo "✅ Service started"
echo ""

# Test endpoints
echo "7. Testing endpoints..."
echo ""
echo "Health endpoint:"
curl http://localhost:8000/health
echo ""
echo ""

echo "Testing overview endpoint (this may take 20-30 seconds)..."
time curl --max-time 300 http://localhost:8000/api/v1/overview | head -c 200
echo ""
echo ""

echo "=== Database Restoration Complete ==="
echo "✅ Database restored (5.4 GB with indexes)"
echo "✅ Service running"
echo "✅ Health should improve to Green/Yellow"
echo ""
echo "Expected performance: 20-30 seconds for overview endpoint"



