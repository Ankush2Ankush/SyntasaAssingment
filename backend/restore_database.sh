#!/bin/bash
# Restore database after deployment
# Following REDEPLOYMENT_GUIDE.md Step 4

echo "=== Restoring Database from S3 ==="
echo ""

# Stop the web service
echo "Stopping web service..."
sudo systemctl stop web.service

# Navigate to application directory
cd /var/app/current

# Download database from S3
echo "Downloading database from S3..."
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db

# Set correct permissions
echo "Setting permissions..."
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db

# Start the web service
echo "Starting web service..."
sudo systemctl start web.service
sleep 10

# Verify database restored
echo "Verifying database..."
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'

# Test the endpoint
echo "Testing health endpoint..."
curl http://localhost:8000/health

echo ""
echo "=== Database Restoration Complete ==="

