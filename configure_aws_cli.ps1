# AWS CLI Configuration Helper Script
# This script helps you configure AWS CLI with your credentials

Write-Host "=== AWS CLI Configuration Helper ===" -ForegroundColor Green
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
Write-Host "Current AWS Configuration:" -ForegroundColor Cyan
aws configure list

Write-Host ""
Write-Host "=== Configuration Options ===" -ForegroundColor Green
Write-Host ""
Write-Host "Do you have AWS credentials ready?" -ForegroundColor Yellow
Write-Host ""
Write-Host "If YES, you need:" -ForegroundColor Cyan
Write-Host "  1. AWS Access Key ID" -ForegroundColor White
Write-Host "  2. AWS Secret Access Key" -ForegroundColor White
Write-Host "  3. Default region (e.g., us-east-1, us-west-2)" -ForegroundColor White
Write-Host "  4. Default output format (json, yaml, text, table)" -ForegroundColor White
Write-Host ""
Write-Host "If NO, follow these steps to get AWS credentials:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Step 1: Create AWS Account (if you don't have one)" -ForegroundColor Yellow
Write-Host "  - Go to: https://aws.amazon.com/" -ForegroundColor White
Write-Host "  - Click 'Create an AWS Account'" -ForegroundColor White
Write-Host "  - Follow the registration process" -ForegroundColor White
Write-Host ""
Write-Host "Step 2: Create IAM User and Access Keys" -ForegroundColor Yellow
Write-Host "  1. Log in to AWS Console: https://console.aws.amazon.com/" -ForegroundColor White
Write-Host "  2. Go to IAM (Identity and Access Management)" -ForegroundColor White
Write-Host "  3. Click 'Users' in the left sidebar" -ForegroundColor White
Write-Host "  4. Click 'Create user'" -ForegroundColor White
Write-Host "  5. Enter username (e.g., 'deployment-user')" -ForegroundColor White
Write-Host "  6. Click 'Next'" -ForegroundColor White
Write-Host "  7. Select 'Attach policies directly'" -ForegroundColor White
Write-Host "  8. Choose one of:" -ForegroundColor White
Write-Host "     - AdministratorAccess (full access - for testing)" -ForegroundColor Gray
Write-Host "     - PowerUserAccess (most services, no IAM)" -ForegroundColor Gray
Write-Host "     - Or create custom policy for specific services" -ForegroundColor Gray
Write-Host "  9. Click 'Next' → 'Create user'" -ForegroundColor White
Write-Host "  10. Click on the created user" -ForegroundColor White
Write-Host "  11. Go to 'Security credentials' tab" -ForegroundColor White
Write-Host "  12. Click 'Create access key'" -ForegroundColor White
Write-Host "  13. Select 'Command Line Interface (CLI)'" -ForegroundColor White
Write-Host "  14. Click 'Next' → 'Create access key'" -ForegroundColor White
Write-Host "  15. IMPORTANT: Copy and save:" -ForegroundColor Red
Write-Host "      - Access Key ID" -ForegroundColor Red
Write-Host "      - Secret Access Key (shown only once!)" -ForegroundColor Red
Write-Host ""
Write-Host "Step 3: Choose AWS Region" -ForegroundColor Yellow
Write-Host "  Common regions:" -ForegroundColor White
Write-Host "    - us-east-1 (N. Virginia) - Recommended, cheapest" -ForegroundColor Gray
Write-Host "    - us-west-2 (Oregon)" -ForegroundColor Gray
Write-Host "    - eu-west-1 (Ireland)" -ForegroundColor Gray
Write-Host "    - ap-south-1 (Mumbai)" -ForegroundColor Gray
Write-Host ""
Write-Host "=== Ready to Configure? ===" -ForegroundColor Green
Write-Host ""
Write-Host "When you have your credentials ready, run:" -ForegroundColor Yellow
Write-Host "  aws configure" -ForegroundColor White
Write-Host ""
Write-Host "Or run this script again and it will guide you interactively." -ForegroundColor Gray
Write-Host ""
Write-Host "Would you like to configure AWS CLI now? (Y/N)" -ForegroundColor Cyan
$response = Read-Host

if ($response -eq "Y" -or $response -eq "y" -or $response -eq "yes") {
    Write-Host ""
    Write-Host "Starting AWS CLI configuration..." -ForegroundColor Green
    Write-Host "Follow the prompts below:" -ForegroundColor Yellow
    Write-Host ""
    aws configure
    Write-Host ""
    Write-Host "Verifying configuration..." -ForegroundColor Cyan
    try {
        $identity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] AWS CLI is configured correctly!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Your AWS Account Information:" -ForegroundColor Cyan
            $identity
        } else {
            Write-Host "[ERROR] Configuration failed. Please check your credentials." -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Could not verify configuration." -ForegroundColor Red
        Write-Host "Please run 'aws configure' again and check your credentials." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Configuration cancelled. Run 'aws configure' when ready." -ForegroundColor Yellow
}

Write-Host ""




