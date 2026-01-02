# Fix SSH Connection Issues
# This script diagnoses and helps fix SSH connection problems

Write-Host "=== SSH Connection Troubleshooting ===" -ForegroundColor Cyan
Write-Host ""

# Get instance details
Write-Host "1. Checking instance status..." -ForegroundColor Yellow
$instanceInfo = aws ec2 describe-instances `
    --filters "Name=tag:elasticbeanstalk:environment-name,Values=nyc-taxi-api-env" `
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,PublicDnsName]' `
    --output text

if ([string]::IsNullOrWhiteSpace($instanceInfo) -or $instanceInfo -eq "None") {
    Write-Host "❌ Could not find instance" -ForegroundColor Red
    exit 1
}

$instanceId, $state, $publicIp, $publicDns = $instanceInfo -split "`t"

Write-Host "Instance ID: $instanceId" -ForegroundColor Green
Write-Host "State: $state" -ForegroundColor $(if ($state -eq "running") { "Green" } else { "Yellow" })
Write-Host "Public IP: $publicIp" -ForegroundColor Green
Write-Host "Public DNS: $publicDns" -ForegroundColor Green
Write-Host ""

if ($state -ne "running") {
    Write-Host "⚠️  Instance is not running. State: $state" -ForegroundColor Yellow
    Write-Host "Wait for instance to be running, then try SSH again." -ForegroundColor Yellow
    exit 1
}

# Check SSH key
Write-Host "2. Checking SSH key..." -ForegroundColor Yellow
$sshKey = "C:\Users\ankush\.ssh\aws-eb"
if (Test-Path $sshKey) {
    Write-Host "✅ SSH key exists: $sshKey" -ForegroundColor Green
} else {
    Write-Host "❌ SSH key not found: $sshKey" -ForegroundColor Red
    Write-Host "Creating new key pair..." -ForegroundColor Yellow
    Write-Host "Run: eb ssh (it will prompt to create a key)" -ForegroundColor Cyan
    exit 1
}
Write-Host ""

# Test connectivity
Write-Host "3. Testing connectivity to port 22..." -ForegroundColor Yellow
$testResult = Test-NetConnection -ComputerName $publicIp -Port 22 -WarningAction SilentlyContinue
if ($testResult.TcpTestSucceeded) {
    Write-Host "✅ Port 22 is open and accessible" -ForegroundColor Green
} else {
    Write-Host "❌ Port 22 is not accessible" -ForegroundColor Red
    Write-Host "This could be a security group issue." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Check security group rules:" -ForegroundColor Cyan
    Write-Host "aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text" -ForegroundColor White
}
Write-Host ""

# Provide SSH commands
Write-Host "4. SSH Connection Options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option A: Direct SSH (with verbose output for debugging):" -ForegroundColor Cyan
Write-Host "ssh -v -i $sshKey ec2-user@$publicIp" -ForegroundColor White
Write-Host ""
Write-Host "Option B: SSH with timeout (fails faster if stuck):" -ForegroundColor Cyan
Write-Host "ssh -o ConnectTimeout=10 -i $sshKey ec2-user@$publicIp" -ForegroundColor White
Write-Host ""
Write-Host "Option C: Try with different user:" -ForegroundColor Cyan
Write-Host "ssh -i $sshKey root@$publicIp" -ForegroundColor White
Write-Host ""

# Check security group
Write-Host "5. Checking security group rules..." -ForegroundColor Yellow
$sgId = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text
if ($sgId) {
    Write-Host "Security Group: $sgId" -ForegroundColor Green
    $sshRule = aws ec2 describe-security-groups --group-ids $sgId --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]' --output json | ConvertFrom-Json
    if ($sshRule) {
        Write-Host "✅ SSH rule (port 22) exists" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No SSH rule found. Adding SSH access..." -ForegroundColor Yellow
        Write-Host "Run this to add SSH access:" -ForegroundColor Cyan
        Write-Host "aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0" -ForegroundColor White
    }
}
Write-Host ""

Write-Host "=== Troubleshooting Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Try SSH with verbose output to see where it's getting stuck:" -ForegroundColor Cyan
Write-Host "ssh -v -i $sshKey ec2-user@$publicIp" -ForegroundColor White


