# AWS CLI Credentials Setup Script
# This script helps you configure AWS CLI interactively

Write-Host "=== AWS CLI Credentials Configuration ===" -ForegroundColor Green
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    Write-Host "[OK] AWS CLI is installed: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] AWS CLI is not installed!" -ForegroundColor Red
    Write-Host "Please install AWS CLI first." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "You will be prompted to enter your AWS credentials." -ForegroundColor Cyan
Write-Host "Make sure you have the following ready:" -ForegroundColor Yellow
Write-Host "  1. AWS Access Key ID" -ForegroundColor White
Write-Host "  2. AWS Secret Access Key" -ForegroundColor White
Write-Host "  3. Default region (e.g., us-east-1)" -ForegroundColor White
Write-Host "  4. Default output format (json, yaml, text, table)" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter to continue..." -ForegroundColor Gray
Read-Host

Write-Host ""
Write-Host "Starting AWS CLI configuration..." -ForegroundColor Green
Write-Host ""

# Run aws configure
aws configure

Write-Host ""
Write-Host "=== Verifying Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Verify the configuration
try {
    Write-Host "Testing AWS connection..." -ForegroundColor Yellow
    $identity = aws sts get-caller-identity 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] AWS CLI is configured correctly!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your AWS Account Information:" -ForegroundColor Cyan
        $identity | ConvertFrom-Json | Format-List
        Write-Host ""
        Write-Host "Configuration Summary:" -ForegroundColor Cyan
        aws configure list
    } else {
        Write-Host "[ERROR] Configuration verification failed." -ForegroundColor Red
        Write-Host "Error details:" -ForegroundColor Yellow
        $identity
        Write-Host ""
        Write-Host "Please check:" -ForegroundColor Yellow
        Write-Host "  - Access Key ID is correct" -ForegroundColor White
        Write-Host "  - Secret Access Key is correct" -ForegroundColor White
        Write-Host "  - Your IAM user has proper permissions" -ForegroundColor White
        Write-Host "  - Run 'aws configure' again to fix" -ForegroundColor White
    }
} catch {
    Write-Host "[ERROR] Could not verify configuration." -ForegroundColor Red
    Write-Host "Please run 'aws configure' manually and verify your credentials." -ForegroundColor Yellow
}

Write-Host ""


