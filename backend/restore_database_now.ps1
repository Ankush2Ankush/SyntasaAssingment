# Restore database from S3 after deployment
# This script restores the database file that was lost during deployment

Write-Host "=== Restoring Database from S3 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  1. Stop the web service" -ForegroundColor White
Write-Host "  2. Download database from S3 (1.7GB, takes 2-3 minutes)" -ForegroundColor White
Write-Host "  3. Set correct permissions" -ForegroundColor White
Write-Host "  4. Start the web service" -ForegroundColor White
Write-Host "  5. Verify database is restored" -ForegroundColor White
Write-Host ""

# Run commands one by one
Write-Host "Step 1: Stopping web service..." -ForegroundColor Yellow
eb ssh --command "sudo systemctl stop web.service"

Write-Host "Step 2: Downloading database from S3 (this may take 2-3 minutes)..." -ForegroundColor Yellow
eb ssh --command "cd /var/app/current && sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db"

Write-Host "Step 3: Setting permissions..." -ForegroundColor Yellow
eb ssh --command "cd /var/app/current && sudo chown webapp:webapp nyc_taxi.db && sudo chmod 664 nyc_taxi.db"

Write-Host "Step 4: Verifying database..." -ForegroundColor Yellow
eb ssh --command "cd /var/app/current && ls -lh nyc_taxi.db && sqlite3 nyc_taxi.db 'SELECT COUNT(*) as trip_count FROM trips;'"

Write-Host "Step 5: Starting web service..." -ForegroundColor Yellow
eb ssh --command "sudo systemctl start web.service && sleep 10"

Write-Host ""
Write-Host "=== Database Restoration Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Test the endpoint:" -ForegroundColor Yellow
Write-Host "  Invoke-WebRequest -Uri 'http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com/api/v1/overview' -UseBasicParsing" -ForegroundColor White

