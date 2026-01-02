#!/bin/bash
# Create database indexes for trips table
# This script follows REDEPLOYMENT_GUIDE.md instructions

echo "=== Creating Database Indexes ==="
echo ""
echo "This will take 5-10 minutes for large datasets..."
echo ""

# Stop the web service
echo "Stopping web service..."
sudo systemctl stop web.service

# Navigate to application directory
cd /var/app/current

# Create indexes
echo "Creating indexes..."
sudo sqlite3 nyc_taxi.db << 'EOF'
CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);
CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);
CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);
CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);
EOF

# Set permissions
echo "Setting permissions..."
sudo chown webapp:webapp nyc_taxi.db

# Start the web service
echo "Starting web service..."
sudo systemctl start web.service

echo ""
echo "=== Index Creation Complete ==="
echo ""
echo "Verifying indexes..."
sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"

