# Wait for environment to be ready, then deploy
# This script polls the environment status until it's ready, then deploys

Write-Host "=== Waiting for Environment to be Ready ===" -ForegroundColor Cyan
Write-Host ""

$maxAttempts = 30
$attempt = 0
$ready = $false

while (-not $ready -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "Checking status (attempt $attempt/$maxAttempts)..." -ForegroundColor Yellow
    
    $statusOutput = eb status 2>&1 | Out-String
    
    if ($statusOutput -match "Status:\s+Ready" -and $statusOutput -match "Health:\s+(Green|Yellow)") {
        Write-Host "✅ Environment is Ready!" -ForegroundColor Green
        $ready = $true
        break
    } elseif ($statusOutput -match "Status:\s+(Updating|Launching|Terminating)") {
        Write-Host "⏳ Environment is still: $($matches[1])" -ForegroundColor Yellow
        Write-Host "Waiting 30 seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    } else {
        Write-Host "⚠️  Status unclear, waiting..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
}

if (-not $ready) {
    Write-Host ""
    Write-Host "❌ Environment did not become ready after $maxAttempts attempts" -ForegroundColor Red
    Write-Host "Please check the status manually: eb status" -ForegroundColor Yellow
    Write-Host "Or check in AWS Console" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== Deploying Application ===" -ForegroundColor Cyan
Write-Host ""

eb deploy

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The nginx timeout fix will be applied automatically." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}

