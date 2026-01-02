#!/bin/bash
# Check if database indexes exist

echo "=== Checking Database Indexes ==="
echo ""

cd /var/app/current

echo "Indexes on 'trips' table:"
sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"

echo ""
echo "Expected indexes:"
echo "- idx_pickup_datetime"
echo "- idx_dropoff_datetime"
echo "- idx_pulocationid"
echo "- idx_dolocationid"
echo "- idx_pickup_location_time"
echo "- idx_dropoff_location_time"

