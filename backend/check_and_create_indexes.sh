#!/bin/bash
# Check and create database indexes
# Run this in your SSH session on EC2

cd /var/app/current

echo "=== Checking Database Indexes ==="
echo ""

# Check existing indexes
echo "Current indexes:"
sqlite3 nyc_taxi.db ".indexes" | grep -E "idx_|trips" || echo "No indexes found"
echo ""

# Create indexes if they don't exist
echo "Creating indexes (this may take a few minutes)..."
echo ""

sqlite3 nyc_taxi.db << 'EOF'
-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);
CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);
CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);
CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);

-- Verify indexes were created
SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';
EOF

echo ""
echo "=== Indexes Created ==="
echo ""
echo "Testing query speed..."
time sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips WHERE tpep_pickup_datetime >= '2025-01-01' AND tpep_pickup_datetime < '2025-05-01';"

echo ""
echo "=== Done ==="

