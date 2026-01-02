# Monitor Elastic Beanstalk Deployment
# Run this script to monitor the deployment progress

Write-Host "Monitoring deployment for: nyc-taxi-api-env" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

$envName = "nyc-taxi-api-env"
$checkInterval = 30  # Check every 30 seconds

while ($true) {
    $status = eb status $envName 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Current Status:" -ForegroundColor Green
        $status | Select-String -Pattern "Status:|Health:|CNAME:" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor White
        }
        
        # Check if environment is ready
        if ($status -match "Status: Ready") {
            Write-Host "`n✅ Environment is Ready!" -ForegroundColor Green
            Write-Host "Deployment completed successfully!" -ForegroundColor Green
            
            # Get the URL
            $cname = ($status | Select-String -Pattern "CNAME: (.+)").Matches.Groups[1].Value
            if ($cname -and $cname -ne "UNKNOWN") {
                Write-Host "`n🌐 Application URL: http://$cname" -ForegroundColor Cyan
            }
            
            break
        }
        
        # Check if there's an error
        if ($status -match "Status: (Degraded|Severe|Error)") {
            Write-Host "`n⚠️  Environment has issues. Check logs:" -ForegroundColor Yellow
            Write-Host "   eb logs $envName" -ForegroundColor White
            break
        }
    } else {
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Error checking status" -ForegroundColor Red
    }
    
    Write-Host "`nWaiting $checkInterval seconds before next check..." -ForegroundColor Gray
    Start-Sleep -Seconds $checkInterval
}

Write-Host "`nMonitoring stopped." -ForegroundColor Yellow
