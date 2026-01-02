# Restore database after deployment
# Following REDEPLOYMENT_GUIDE.md Step 4

Write-Host "`n=== Restoring Database from S3 ===" -ForegroundColor Cyan
Write-Host "Following REDEPLOYMENT_GUIDE.md Step 4`n" -ForegroundColor Gray

# Commands to run via SSH
$commands = @"
sudo systemctl stop web.service
cd /var/app/current
echo 'Downloading database from S3...'
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
echo 'Setting permissions...'
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
echo 'Starting web service...'
sudo systemctl start web.service
sleep 10
echo 'Verifying database...'
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
echo 'Testing health endpoint...'
curl http://localhost:8000/health
echo ''
echo 'Database restoration complete!'
"@

Write-Host "Executing commands via SSH...`n" -ForegroundColor Yellow
eb ssh --command "$commands"

Write-Host "`n=== Database Restoration Complete ===" -ForegroundColor Green
Write-Host "`nNext: Verify public endpoints (Step 5 in guide)`n" -ForegroundColor Cyan

