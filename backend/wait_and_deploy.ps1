# Wait for environment to be ready, then deploy
Write-Host "Checking environment status..." -ForegroundColor Cyan

# Check status
$status = eb status 2>&1 | Select-String "Status:"
Write-Host $status

# Wait for environment to be ready
Write-Host "`nWaiting for environment to be ready..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes..." -ForegroundColor Yellow

$maxAttempts = 60  # 60 attempts = 10 minutes (10 seconds per check)
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "`nAttempt $attempt/$maxAttempts - Checking status..." -ForegroundColor Gray
    
    $statusOutput = eb status 2>&1 | Out-String
    $statusLine = $statusOutput | Select-String "Status:"
    
    if ($statusLine -match "Status:\s+Ready") {
        Write-Host "`n✅ Environment is Ready! Proceeding with deployment..." -ForegroundColor Green
        break
    }
    elseif ($statusLine -match "Status:\s+Launching") {
        Write-Host "Environment is still launching... waiting 10 seconds" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
    elseif ($statusLine -match "Status:\s+Updating") {
        Write-Host "Environment is updating... waiting 10 seconds" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
    else {
        Write-Host "Current status: $statusLine" -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

if ($attempt -ge $maxAttempts) {
    Write-Host "`n❌ Timeout: Environment did not become ready after 10 minutes" -ForegroundColor Red
    Write-Host "Please check the AWS Console for environment status" -ForegroundColor Yellow
    exit 1
}

# Now deploy
Write-Host "`n🚀 Starting deployment..." -ForegroundColor Cyan
Write-Host "This will:" -ForegroundColor White
Write-Host "  1. Package your application" -ForegroundColor White
Write-Host "  2. Upload to S3" -ForegroundColor White
Write-Host "  3. Deploy to Elastic Beanstalk" -ForegroundColor White
Write-Host "  4. Download optimized database from S3" -ForegroundColor White
Write-Host "  5. Start the application" -ForegroundColor White
Write-Host ""

eb deploy

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Deployment completed successfully!" -ForegroundColor Green
    Write-Host "`nChecking final status..." -ForegroundColor Cyan
    eb status
    Write-Host "`nYou can view logs with: eb logs" -ForegroundColor Yellow
    Write-Host "You can SSH into the instance with: eb ssh" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ Deployment failed. Check the logs above for details." -ForegroundColor Red
    Write-Host "View logs with: eb logs" -ForegroundColor Yellow
}
