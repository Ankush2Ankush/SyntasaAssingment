# Quick fix script to check and restore backend database
Write-Host "`n=== Quick Backend Fix ===" -ForegroundColor Cyan
Write-Host "`nChecking backend status...`n" -ForegroundColor Yellow

$backendUrl = "http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com"

# Test health
try {
    $health = Invoke-WebRequest -Uri "$backendUrl/health" -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend is not accessible" -ForegroundColor Red
    exit 1
}

# Test overview
try {
    $overview = Invoke-WebRequest -Uri "$backendUrl/api/v1/overview" -TimeoutSec 30 -UseBasicParsing
    Write-Host "✅ Overview endpoint working" -ForegroundColor Green
    Write-Host "Backend is healthy!" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "❌ Overview endpoint failing (500 error)" -ForegroundColor Red
    Write-Host "`nDatabase likely needs to be restored.`n" -ForegroundColor Yellow
}

Write-Host "Run these commands in SSH to fix:" -ForegroundColor Cyan
Write-Host "`neb ssh`n" -ForegroundColor White
Write-Host "Then run:" -ForegroundColor Yellow
Write-Host "cd /var/app/current" -ForegroundColor Gray
Write-Host "ls -lh nyc_taxi.db" -ForegroundColor Gray
Write-Host "sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;' 2>&1" -ForegroundColor Gray
Write-Host "`nIf database is missing or empty, restore it:" -ForegroundColor Yellow
Write-Host "sudo systemctl stop web.service" -ForegroundColor Gray
Write-Host "sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db" -ForegroundColor Gray
Write-Host "sudo chown webapp:webapp nyc_taxi.db" -ForegroundColor Gray
Write-Host "sudo chmod 664 nyc_taxi.db" -ForegroundColor Gray
Write-Host "sudo systemctl start web.service" -ForegroundColor Gray
Write-Host "sleep 10" -ForegroundColor Gray
Write-Host "curl http://localhost:8000/api/v1/overview | head -c 200`n" -ForegroundColor Gray

