# Quick AWS CLI Configuration Script
# This refreshes PATH and runs aws configure

# Refresh PATH in current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "=== AWS CLI Configuration ===" -ForegroundColor Green
Write-Host ""

# Verify AWS CLI is accessible
try {
    $version = aws --version 2>&1
    Write-Host "[OK] AWS CLI is ready: $version" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] AWS CLI not found. Trying full path..." -ForegroundColor Red
    $env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
}

Write-Host ""
Write-Host "You will now be prompted to enter your AWS credentials." -ForegroundColor Cyan
Write-Host "Enter:" -ForegroundColor Yellow
Write-Host "  1. AWS Access Key ID" -ForegroundColor White
Write-Host "  2. AWS Secret Access Key" -ForegroundColor White
Write-Host "  3. Default region (e.g., us-east-1)" -ForegroundColor White
Write-Host "  4. Default output format (json recommended)" -ForegroundColor White
Write-Host ""
Write-Host "Starting configuration..." -ForegroundColor Green
Write-Host ""

# Run aws configure
aws configure

Write-Host ""
Write-Host "=== Verifying Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Verify
try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] AWS CLI configured successfully!" -ForegroundColor Green
        Write-Host ""
        $identity | ConvertFrom-Json | Format-List
    } else {
        Write-Host "[ERROR] Configuration failed. Please check your credentials." -ForegroundColor Red
        $identity
    }
} catch {
    Write-Host "[WARNING] Could not verify automatically." -ForegroundColor Yellow
    Write-Host "Run 'aws sts get-caller-identity' to verify manually." -ForegroundColor White
}

Write-Host ""




