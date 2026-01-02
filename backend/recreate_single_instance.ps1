# Script to terminate current environment and recreate as Single Instance with t3.medium
# This is faster than load-balanced environments

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Recreating Environment as Single Instance" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check current status
Write-Host "Step 1: Checking current environment status..." -ForegroundColor Yellow
$status = eb status 2>&1 | Out-String
Write-Host $status

# Step 2: Terminate current environment
Write-Host "`nStep 2: Terminating current environment..." -ForegroundColor Yellow
Write-Host "This will delete the current environment and all its resources." -ForegroundColor Gray
Write-Host "Press Ctrl+C to cancel, or wait 5 seconds to continue..." -ForegroundColor Gray
Start-Sleep -Seconds 5

eb terminate nyc-taxi-api-env --force

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠️  Termination may have failed or environment doesn't exist" -ForegroundColor Yellow
    Write-Host "Continuing with environment creation..." -ForegroundColor Yellow
}

# Step 3: Wait for termination to complete
Write-Host "`nStep 3: Waiting for termination to complete..." -ForegroundColor Yellow
Write-Host "This may take 2-5 minutes..." -ForegroundColor Gray

$maxWait = 20  # Wait up to 20 attempts (5 minutes)
$attempt = 0

while ($attempt -lt $maxWait) {
    $attempt++
    $checkOutput = eb list 2>&1 | Out-String
    
    if ($checkOutput -notmatch "nyc-taxi-api-env") {
        Write-Host "✅ Environment terminated successfully" -ForegroundColor Green
        break
    }
    
    Write-Host "Waiting for termination... ($attempt/$maxWait)" -ForegroundColor Gray
    Start-Sleep -Seconds 15
}

# Step 4: Create new environment as Single Instance
Write-Host "`nStep 4: Creating new environment as Single Instance with t3.medium..." -ForegroundColor Yellow
Write-Host "Configuration:" -ForegroundColor White
Write-Host "  - Environment Type: Single Instance (faster launch)" -ForegroundColor White
Write-Host "  - Instance Type: t3.medium" -ForegroundColor White
Write-Host "  - Availability Zone: Auto (AWS will choose best AZ)" -ForegroundColor White
Write-Host ""

# Create environment with single instance and t3.medium
# Using --single flag for single instance (faster)
# Using --instance-type t3.medium for the instance size
eb create nyc-taxi-api-env --single --instance-type t3.medium

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Environment creation started!" -ForegroundColor Green
    Write-Host "`nThis will take 5-10 minutes. Monitor progress with:" -ForegroundColor Yellow
    Write-Host "  eb status" -ForegroundColor White
    Write-Host "  eb events" -ForegroundColor White
    Write-Host ""
    Write-Host "Once environment is Ready, deploy with:" -ForegroundColor Yellow
    Write-Host "  eb deploy" -ForegroundColor White
} else {
    Write-Host "`n❌ Environment creation failed. Check the error above." -ForegroundColor Red
}

