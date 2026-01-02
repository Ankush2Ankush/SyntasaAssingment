# Start EC2 Instance After Storage Increase
# This script starts the EC2 instance after you've increased storage

Write-Host "=== Starting EC2 Instance ===" -ForegroundColor Cyan
Write-Host ""

# Get instance ID
Write-Host "Finding EC2 instance for environment: nyc-taxi-api-env..." -ForegroundColor Yellow
$instanceId = aws ec2 describe-instances `
    --filters "Name=tag:elasticbeanstalk:environment-name,Values=nyc-taxi-api-env" `
    --query 'Reservations[0].Instances[0].InstanceId' `
    --output text

if ([string]::IsNullOrWhiteSpace($instanceId) -or $instanceId -eq "None") {
    Write-Host "❌ Could not find instance for environment: nyc-taxi-api-env" -ForegroundColor Red
    exit 1
}

Write-Host "Found instance: $instanceId" -ForegroundColor Green
Write-Host ""

# Start the instance
Write-Host "Starting instance..." -ForegroundColor Yellow
aws ec2 start-instances --instance-ids $instanceId

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Instance start initiated!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Wait 2-3 minutes for instance to start" -ForegroundColor White
    Write-Host "2. SSH into instance: eb ssh" -ForegroundColor White
    Write-Host "3. Extend filesystem if not done:" -ForegroundColor White
    Write-Host "   sudo growpart /dev/nvme0n1 1" -ForegroundColor Gray
    Write-Host "   sudo xfs_growfs / || sudo resize2fs /dev/nvme0n1p1" -ForegroundColor Gray
    Write-Host "4. Verify space: df -h" -ForegroundColor White
    Write-Host "5. Download database from S3" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Failed to start instance" -ForegroundColor Red
    exit 1
}

