# Fix AWS CLI PATH and Configure Script
# This script refreshes PATH and helps configure AWS CLI

Write-Host "=== AWS CLI PATH Fix and Configuration ===" -ForegroundColor Green
Write-Host ""

# Step 1: Refresh PATH
Write-Host "Step 1: Refreshing PATH environment variable..." -ForegroundColor Cyan
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Step 2: Check if AWS CLI is accessible
Write-Host "Step 2: Checking AWS CLI..." -ForegroundColor Cyan
$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"

if (Test-Path $awsPath) {
    Write-Host "[OK] AWS CLI found at: $awsPath" -ForegroundColor Green
    
    # Try to use aws command
    try {
        $awsVersion = aws --version 2>&1
        Write-Host "[OK] AWS CLI is accessible: $awsVersion" -ForegroundColor Green
    } catch {
        Write-Host "[INFO] AWS CLI not in PATH, using full path..." -ForegroundColor Yellow
        # Add to current session PATH
        $env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
        
        # Verify again
        try {
            $awsVersion = aws --version 2>&1
            Write-Host "[OK] AWS CLI is now accessible: $awsVersion" -ForegroundColor Green
        } catch {
            Write-Host "[WARNING] Still having PATH issues. Using direct path..." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[ERROR] AWS CLI not found at expected location!" -ForegroundColor Red
    Write-Host "Please verify AWS CLI installation." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Step 3: Starting AWS CLI configuration..." -ForegroundColor Cyan
Write-Host ""
Write-Host "You will be prompted to enter:" -ForegroundColor Yellow
Write-Host "  1. AWS Access Key ID" -ForegroundColor White
Write-Host "  2. AWS Secret Access Key" -ForegroundColor White
Write-Host "  3. Default region name (e.g., us-east-1)" -ForegroundColor White
Write-Host "  4. Default output format (json, yaml, text, table)" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter to continue..." -ForegroundColor Gray
Read-Host

# Run aws configure
Write-Host ""
Write-Host "Starting configuration..." -ForegroundColor Green
Write-Host ""

# Try with aws command first, fallback to full path
try {
    aws configure
} catch {
    Write-Host "Using full path to AWS CLI..." -ForegroundColor Yellow
    & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" configure
}

Write-Host ""
Write-Host "=== Verifying Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Verify configuration
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
    }
} catch {
    Write-Host "[WARNING] Could not verify automatically." -ForegroundColor Yellow
    Write-Host "Please run 'aws sts get-caller-identity' manually to verify." -ForegroundColor White
}

Write-Host ""
Write-Host "=== Important Note ===" -ForegroundColor Yellow
Write-Host "If you still get 'aws not recognized' errors in new terminals:" -ForegroundColor White
Write-Host "1. Close and reopen your PowerShell terminal" -ForegroundColor Gray
Write-Host "2. Or restart your computer" -ForegroundColor Gray
Write-Host "3. Or run this command to permanently add to PATH:" -ForegroundColor Gray
Write-Host '   [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Program Files\Amazon\AWSCLIV2", "User")' -ForegroundColor DarkGray
Write-Host ""





