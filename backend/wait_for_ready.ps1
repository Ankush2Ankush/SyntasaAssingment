# Wait for environment to be Ready
# Useful after aborting or during deployment

Write-Host "`n=== Waiting for Environment to be Ready ===" -ForegroundColor Cyan
Write-Host ""

$maxWait = 20  # Maximum minutes to wait
$checkInterval = 30  # Check every 30 seconds
$elapsed = 0
$startTime = Get-Date

Write-Host "Monitoring environment status..." -ForegroundColor Yellow
Write-Host "Checking every 30 seconds (max $maxWait minutes)`n" -ForegroundColor Gray

while ($elapsed -lt ($maxWait * 60)) {
    $statusOutput = eb status 2>&1 | Out-String
    
    $minutes = [math]::Floor($elapsed / 60)
    $seconds = $elapsed % 60
    
    if ($statusOutput -match "Status: Ready") {
        Write-Host "`n✅ Environment is Ready!" -ForegroundColor Green
        
        # Check health
        if ($statusOutput -match "Health: Green") {
            Write-Host "✅ Health: Green" -ForegroundColor Green
        } elseif ($statusOutput -match "Health: Yellow") {
            Write-Host "⚠️  Health: Yellow" -ForegroundColor Yellow
        } else {
            Write-Host "⚠️  Health: Red (may be normal if database is missing)" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "Total wait time: $minutes minutes $seconds seconds" -ForegroundColor Gray
        Write-Host ""
        Write-Host "You can now:" -ForegroundColor Cyan
        Write-Host "  - Deploy: eb deploy" -ForegroundColor White
        Write-Host "  - Or restore database if needed" -ForegroundColor White
        Write-Host ""
        exit 0
    } elseif ($statusOutput -match "Status: (Updating|Aborting)") {
        $status = if ($statusOutput -match "Status: Updating") { "Updating" } else { "Aborting" }
        Write-Host "[$minutes m $seconds s] Status: $status (waiting...)" -ForegroundColor Yellow
    } elseif ($statusOutput -match "Status:") {
        Write-Host "[$minutes m $seconds s] $statusOutput" -ForegroundColor Gray
    } else {
        Write-Host "[$minutes m $seconds s] Checking..." -ForegroundColor Gray
    }
    
    Start-Sleep -Seconds $checkInterval
    $elapsed += $checkInterval
}

if ($elapsed -ge ($maxWait * 60)) {
    Write-Host "`n⏱️  Maximum wait time reached ($maxWait minutes)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Environment may be stuck. Options:" -ForegroundColor Yellow
    Write-Host "  1. Check AWS Console → Elastic Beanstalk → Events" -ForegroundColor White
    Write-Host "  2. Check for errors in the Events tab" -ForegroundColor White
    Write-Host "  3. Try: eb abort (if still stuck)" -ForegroundColor White
    Write-Host "  4. Contact AWS support if persistent" -ForegroundColor White
    Write-Host ""
    exit 1
}
