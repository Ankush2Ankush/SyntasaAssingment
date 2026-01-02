# Refresh PATH to include AWS CLI
# Run this script in your PowerShell terminal if AWS CLI is not recognized

Write-Host "Refreshing PATH environment variable..." -ForegroundColor Cyan

# Refresh PATH from system and user environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Verify AWS CLI is accessible
Write-Host ""
Write-Host "Checking AWS CLI..." -ForegroundColor Cyan
try {
    $awsVersion = aws --version 2>&1
    Write-Host "[SUCCESS] AWS CLI is now accessible!" -ForegroundColor Green
    Write-Host "Version: $awsVersion" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now run: aws configure" -ForegroundColor Yellow
} catch {
    Write-Host "[ERROR] AWS CLI still not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Close and reopen your PowerShell terminal" -ForegroundColor White
    Write-Host "2. Or restart your computer" -ForegroundColor White
    Write-Host "3. Or manually add to PATH:" -ForegroundColor White
    Write-Host "   [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';C:\Program Files\Amazon\AWSCLIV2', 'User')" -ForegroundColor Gray
}

Write-Host ""




