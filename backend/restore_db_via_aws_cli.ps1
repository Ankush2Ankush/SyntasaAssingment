# Restore database using AWS Systems Manager Run Command
# Alternative to SSH when SSH is not working

Write-Host "=== Restore Database via AWS Systems Manager ===" -ForegroundColor Cyan
Write-Host ""

# Get instance ID
Write-Host "Finding EC2 instance..." -ForegroundColor Yellow
$instanceId = aws ec2 describe-instances `
    --filters "Name=tag:elasticbeanstalk:environment-name,Values=nyc-taxi-api-env" "Name=instance-state-name,Values=running" `
    --query 'Reservations[0].Instances[0].InstanceId' `
    --output text

if ([string]::IsNullOrWhiteSpace($instanceId) -or $instanceId -eq "None") {
    Write-Host "❌ Could not find running instance" -ForegroundColor Red
    exit 1
}

Write-Host "Found instance: $instanceId" -ForegroundColor Green
Write-Host ""

# Check if SSM agent is online
Write-Host "Checking SSM agent status..." -ForegroundColor Yellow
$ssmStatus = aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$instanceId" --query 'InstanceInformationList[0].PingStatus' --output text

if ($ssmStatus -ne "Online") {
    Write-Host "⚠️  SSM Agent is not online. Cannot use Systems Manager." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Use direct SSH with instance IP:" -ForegroundColor Cyan
    Write-Host ""
    
    # Get instance IP
    $instanceIp = aws ec2 describe-instances `
        --instance-ids $instanceId `
        --query 'Reservations[0].Instances[0].PublicIpAddress' `
        --output text
    
    Write-Host "Instance IP: $instanceIp" -ForegroundColor Green
    Write-Host ""
    Write-Host "SSH command:" -ForegroundColor Yellow
    Write-Host "ssh -i C:\Users\ankush\.ssh\aws-eb ec2-user@$instanceIp" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run these commands in SSH:" -ForegroundColor Yellow
    Write-Host "sudo systemctl stop web.service" -ForegroundColor White
    Write-Host "cd /var/app/current" -ForegroundColor White
    Write-Host "sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db" -ForegroundColor White
    Write-Host "sudo chown webapp:webapp nyc_taxi.db" -ForegroundColor White
    Write-Host "sudo chmod 664 nyc_taxi.db" -ForegroundColor White
    Write-Host "sudo systemctl start web.service" -ForegroundColor White
    exit 0
}

Write-Host "✅ SSM Agent is online" -ForegroundColor Green
Write-Host ""
Write-Host "Running database restoration command..." -ForegroundColor Yellow

# Run command via SSM
$commandId = aws ssm send-command `
    --instance-ids $instanceId `
    --document-name "AWS-RunShellScript" `
    --parameters "commands=['sudo systemctl stop web.service','cd /var/app/current','sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db','sudo chown webapp:webapp nyc_taxi.db','sudo chmod 664 nyc_taxi.db','sudo systemctl start web.service','sleep 10','sqlite3 nyc_taxi.db \"SELECT COUNT(*) FROM trips;\"','curl http://localhost:8000/health']" `
    --query 'Command.CommandId' `
    --output text

if ($commandId) {
    Write-Host "✅ Command sent. Command ID: $commandId" -ForegroundColor Green
    Write-Host ""
    Write-Host "Checking command status..." -ForegroundColor Yellow
    Write-Host "Run this to check status:" -ForegroundColor Cyan
    Write-Host "aws ssm get-command-invocation --command-id $commandId --instance-id $instanceId" -ForegroundColor White
} else {
    Write-Host "❌ Failed to send command" -ForegroundColor Red
    exit 1
}



