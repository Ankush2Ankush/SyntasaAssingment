# Stop EC2 Instance for Storage Increase
# This script stops the EC2 instance so you can increase storage

Write-Host "=== Stopping EC2 Instance ===" -ForegroundColor Cyan
Write-Host ""

# Get instance ID
Write-Host "Finding EC2 instance for environment: nyc-taxi-api-env..." -ForegroundColor Yellow
$instanceId = aws ec2 describe-instances `
    --filters "Name=tag:elasticbeanstalk:environment-name,Values=nyc-taxi-api-env" "Name=instance-state-name,Values=running" `
    --query 'Reservations[0].Instances[0].InstanceId' `
    --output text

if ([string]::IsNullOrWhiteSpace($instanceId) -or $instanceId -eq "None") {
    Write-Host "❌ Could not find running instance for environment: nyc-taxi-api-env" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "1. Environment name is correct" -ForegroundColor White
    Write-Host "2. Instance is actually running" -ForegroundColor White
    Write-Host "3. AWS credentials are configured" -ForegroundColor White
    exit 1
}

Write-Host "Found instance: $instanceId" -ForegroundColor Green
Write-Host ""

# Confirm before stopping
Write-Host "⚠️  WARNING: This will stop the EC2 instance!" -ForegroundColor Yellow
Write-Host "The application will be unavailable until you start it again." -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Do you want to stop instance $instanceId? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Stop the instance
Write-Host ""
Write-Host "Stopping instance..." -ForegroundColor Yellow
aws ec2 stop-instances --instance-ids $instanceId

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Instance stop initiated!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Wait 2-3 minutes for instance to stop" -ForegroundColor White
    Write-Host "2. Go to EC2 Console → Instances → Select instance" -ForegroundColor White
    Write-Host "3. Storage tab → Modify Volume → Increase to 20 GB" -ForegroundColor White
    Write-Host "4. After modification, extend filesystem (see STORAGE_INCREASE_GUIDE.md)" -ForegroundColor White
    Write-Host "5. Start instance again: aws ec2 start-instances --instance-ids $instanceId" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Failed to stop instance" -ForegroundColor Red
    exit 1
}

