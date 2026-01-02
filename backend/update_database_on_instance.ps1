# Script to update database on EC2 instance after rollback
# This script stops the service, downloads the new database from S3,
# sets proper permissions, verifies it, and restarts the service

Write-Host "`n=== Updating Database on EC2 Instance ===" -ForegroundColor Cyan
Write-Host "`nThis script will:" -ForegroundColor Yellow
Write-Host "  1. Check environment status" -ForegroundColor White
Write-Host "  2. Stop the web service" -ForegroundColor White
Write-Host "  3. Download new database from S3" -ForegroundColor White
Write-Host "  4. Set proper permissions" -ForegroundColor White
Write-Host "  5. Verify database" -ForegroundColor White
Write-Host "  6. Restart the service" -ForegroundColor White
Write-Host "  7. Test endpoints" -ForegroundColor White

# S3 bucket and database path
$S3_BUCKET = "nyc-taxi-data-800155829166"
$DB_NAME = "nyc_taxi.db"
$DB_PATH = "/var/app/current/$DB_NAME"

Write-Host "`n=== Step 1: Checking Environment Status ===" -ForegroundColor Cyan
eb status

Write-Host "`n=== Step 2: Connecting to EC2 Instance ===" -ForegroundColor Cyan
Write-Host "You'll need to run these commands on the EC2 instance:" -ForegroundColor Yellow
Write-Host "`n--- Copy and paste these commands into your SSH session ---`n" -ForegroundColor Green

$commands = @"
# Stop the web service
echo "Stopping web service..."
sudo systemctl stop web.service
sleep 2

# Navigate to application directory
cd /var/app/current

# Backup existing database (optional)
if [ -f "$DB_NAME" ]; then
    echo "Backing up existing database..."
    sudo cp $DB_NAME ${DB_NAME}.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backup created"
fi

# Download new database from S3
echo "Downloading new database from S3..."
sudo aws s3 cp s3://$S3_BUCKET/$DB_NAME ./$DB_NAME

# Check if download was successful
if [ ! -f "$DB_NAME" ]; then
    echo "ERROR: Database download failed!"
    exit 1
fi

# Get file size
DB_SIZE=\$(du -h $DB_NAME | cut -f1)
echo "Database downloaded successfully. Size: \$DB_SIZE"

# Set proper permissions
echo "Setting permissions..."
sudo chown webapp:webapp $DB_NAME
sudo chmod 664 $DB_NAME

# Verify database
echo "Verifying database..."
TRIP_COUNT=\$(sqlite3 $DB_NAME 'SELECT COUNT(*) FROM trips;')
INDEX_COUNT=\$(sqlite3 $DB_NAME "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")

echo "Database verification:"
echo "  - Trip records: \$TRIP_COUNT"
echo "  - Indexes on trips table: \$INDEX_COUNT"

# Check database integrity
echo "Checking database integrity..."
sqlite3 $DB_NAME "PRAGMA integrity_check;" | head -1

# Start the web service
echo "Starting web service..."
sudo systemctl start web.service
sleep 5

# Check service status
echo "Checking service status..."
sudo systemctl status web.service --no-pager | head -10

# Test health endpoint
echo "Testing health endpoint..."
sleep 3
curl -s http://localhost:8000/health || echo "Health check failed - service may still be starting"

echo ""
echo "=== Database Update Complete ===" 
echo "You can now test the API endpoints"
"@

Write-Host $commands -ForegroundColor White

Write-Host "`n=== Alternative: Automated Script ===" -ForegroundColor Cyan
Write-Host "If you prefer, I can create a script file on the server.`n" -ForegroundColor Yellow

$response = Read-Host "Do you want to create an automated script on the server? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host "`nCreating update script on server..." -ForegroundColor Cyan
    
    $scriptContent = @"
#!/bin/bash
# Automated database update script

set -e  # Exit on error

DB_NAME="$DB_NAME"
DB_PATH="/var/app/current/\$DB_NAME"
S3_BUCKET="$S3_BUCKET"

echo "=== Stopping web service ==="
sudo systemctl stop web.service
sleep 2

echo "=== Navigating to application directory ==="
cd /var/app/current

echo "=== Backing up existing database ==="
if [ -f "\$DB_NAME" ]; then
    sudo cp \$DB_NAME \${DB_NAME}.backup.\$(date +%Y%m%d_%H%M%S)
    echo "Backup created"
fi

echo "=== Downloading new database from S3 ==="
sudo aws s3 cp s3://\$S3_BUCKET/\$DB_NAME ./\$DB_NAME

if [ ! -f "\$DB_NAME" ]; then
    echo "ERROR: Database download failed!"
    exit 1
fi

DB_SIZE=\$(du -h \$DB_NAME | cut -f1)
echo "Database downloaded successfully. Size: \$DB_SIZE"

echo "=== Setting permissions ==="
sudo chown webapp:webapp \$DB_NAME
sudo chmod 664 \$DB_NAME

echo "=== Verifying database ==="
TRIP_COUNT=\$(sqlite3 \$DB_NAME 'SELECT COUNT(*) FROM trips;')
INDEX_COUNT=\$(sqlite3 \$DB_NAME "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")

echo "Database verification:"
echo "  - Trip records: \$TRIP_COUNT"
echo "  - Indexes on trips table: \$INDEX_COUNT"

echo "=== Checking database integrity ==="
sqlite3 \$DB_NAME "PRAGMA integrity_check;" | head -1

echo "=== Starting web service ==="
sudo systemctl start web.service
sleep 5

echo "=== Checking service status ==="
sudo systemctl status web.service --no-pager | head -10

echo "=== Testing health endpoint ==="
sleep 3
curl -s http://localhost:8000/health || echo "Health check failed - service may still be starting"

echo ""
echo "=== Database Update Complete ==="
"@

    # Create a temporary file with the script
    $tempScript = "update_db_$(Get-Date -Format 'yyyyMMdd_HHmmss').sh"
    $scriptContent | Out-File -FilePath $tempScript -Encoding UTF8
    
    Write-Host "`nScript created: $tempScript" -ForegroundColor Green
    Write-Host "To upload and run it on the server:" -ForegroundColor Yellow
    Write-Host "  1. SSH into the instance: eb ssh" -ForegroundColor White
    Write-Host "  2. Upload the script (or copy-paste the content)" -ForegroundColor White
    Write-Host "  3. Make it executable: chmod +x update_db_*.sh" -ForegroundColor White
    Write-Host "  4. Run it: ./update_db_*.sh" -ForegroundColor White
    Write-Host "`nOr use the manual commands shown above.`n" -ForegroundColor Yellow
} else {
    Write-Host "`nUse the manual commands shown above when you SSH into the instance.`n" -ForegroundColor Yellow
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Wait for environment status to be 'Ready' (not 'Updating')" -ForegroundColor White
Write-Host "2. SSH into the instance: eb ssh" -ForegroundColor White
Write-Host "3. Run the commands shown above (or use the automated script)" -ForegroundColor White
Write-Host "4. Verify the API is working: curl https://hellosyntasa.vercel.app/api/v1/efficiency/timeseries" -ForegroundColor White
Write-Host ""

