#!/bin/bash
# Automated database update script for EC2 instance
# This script stops the service, downloads the new database from S3,
# sets proper permissions, verifies it, and restarts the service

set -e  # Exit on error

DB_NAME="nyc_taxi.db"
DB_PATH="/var/app/current/$DB_NAME"
S3_BUCKET="nyc-taxi-data-800155829166"

echo "=== Database Update Script ==="
echo "This will update the database on the EC2 instance"
echo ""

# Step 1: Stop the web service
echo "=== Step 1: Stopping web service ==="
sudo systemctl stop web.service
sleep 2
echo "Service stopped"
echo ""

# Step 2: Navigate to application directory
echo "=== Step 2: Navigating to application directory ==="
cd /var/app/current
pwd
echo ""

# Step 3: Backup existing database (optional but recommended)
echo "=== Step 3: Backing up existing database ==="
if [ -f "$DB_NAME" ]; then
    BACKUP_NAME="${DB_NAME}.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$DB_NAME" "$BACKUP_NAME"
    echo "Backup created: $BACKUP_NAME"
    ls -lh "$BACKUP_NAME"
else
    echo "No existing database found (this is OK for first-time setup)"
fi
echo ""

# Step 4: Download new database from S3
echo "=== Step 4: Downloading new database from S3 ==="
echo "Source: s3://$S3_BUCKET/$DB_NAME"
echo "Destination: $DB_PATH"
sudo aws s3 cp "s3://$S3_BUCKET/$DB_NAME" "./$DB_NAME"

# Check if download was successful
if [ ! -f "$DB_NAME" ]; then
    echo "ERROR: Database download failed!"
    exit 1
fi

DB_SIZE=$(du -h "$DB_NAME" | cut -f1)
echo "Database downloaded successfully. Size: $DB_SIZE"
ls -lh "$DB_NAME"
echo ""

# Step 5: Set proper permissions
echo "=== Step 5: Setting permissions ==="
sudo chown webapp:webapp "$DB_NAME"
sudo chmod 664 "$DB_NAME"
echo "Permissions set:"
ls -lh "$DB_NAME"
echo ""

# Step 6: Verify database
echo "=== Step 6: Verifying database ==="
TRIP_COUNT=$(sqlite3 "$DB_NAME" 'SELECT COUNT(*) FROM trips;')
INDEX_COUNT=$(sqlite3 "$DB_NAME" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")

echo "Database verification:"
echo "  - Trip records: $TRIP_COUNT"
echo "  - Indexes on trips table: $INDEX_COUNT"

# Check database integrity
echo ""
echo "Checking database integrity..."
INTEGRITY_CHECK=$(sqlite3 "$DB_NAME" "PRAGMA integrity_check;" | head -1)
echo "  - Integrity: $INTEGRITY_CHECK"

if [ "$INTEGRITY_CHECK" != "ok" ]; then
    echo "WARNING: Database integrity check failed!"
    echo "You may want to restore from backup"
fi
echo ""

# Step 7: Start the web service
echo "=== Step 7: Starting web service ==="
sudo systemctl start web.service
sleep 5
echo "Service started"
echo ""

# Step 8: Check service status
echo "=== Step 8: Checking service status ==="
sudo systemctl status web.service --no-pager | head -15
echo ""

# Step 9: Test health endpoint
echo "=== Step 9: Testing health endpoint ==="
sleep 3
HEALTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:8000/health || echo "FAILED")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
RESPONSE_BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Health check passed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
else
    echo "✗ Health check failed or service still starting"
    echo "Response: $HEALTH_RESPONSE"
    echo "You may need to wait a bit longer and check logs"
fi
echo ""

# Step 10: Summary
echo "=== Database Update Complete ==="
echo ""
echo "Summary:"
echo "  - Database: $DB_NAME"
echo "  - Size: $DB_SIZE"
echo "  - Trip records: $TRIP_COUNT"
echo "  - Indexes: $INDEX_COUNT"
echo "  - Service status: $(sudo systemctl is-active web.service)"
echo ""
echo "Next steps:"
echo "  1. Test the API: curl http://localhost:8000/api/v1/overview"
echo "  2. Test public endpoint: curl https://hellosyntasa.vercel.app/api/v1/efficiency/timeseries"
echo "  3. Check logs if needed: sudo journalctl -u web.service -n 50"
echo ""

