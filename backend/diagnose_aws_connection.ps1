# AWS Connection Diagnostic Script
# This script helps diagnose AWS connectivity issues

Write-Host "=== AWS Connection Diagnostics ===" -ForegroundColor Green
Write-Host ""

# 1. Check AWS CLI configuration
Write-Host "1. AWS CLI Configuration:" -ForegroundColor Cyan
aws configure list
Write-Host ""

# 2. Test AWS STS (Identity)
Write-Host "2. Testing AWS Identity Service (STS):" -ForegroundColor Cyan
try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] AWS Identity verified" -ForegroundColor Green
        $identity | ConvertFrom-Json | Format-List
    } else {
        Write-Host "[ERROR] Failed to verify AWS identity" -ForegroundColor Red
        $identity
    }
} catch {
    Write-Host "[ERROR] Exception: $_" -ForegroundColor Red
}
Write-Host ""

# 3. Test Elastic Beanstalk API
Write-Host "3. Testing Elastic Beanstalk API:" -ForegroundColor Cyan
try {
    $envs = aws elasticbeanstalk describe-environments --application-name nyc-taxi-api --region us-east-1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Elastic Beanstalk API accessible" -ForegroundColor Green
        $envData = $envs | ConvertFrom-Json
        if ($envData.Environments) {
            Write-Host "Environment Status:" -ForegroundColor Yellow
            $envData.Environments | ForEach-Object {
                Write-Host "  Name: $($_.EnvironmentName)" -ForegroundColor White
                Write-Host "  Status: $($_.Status)" -ForegroundColor White
                Write-Host "  Health: $($_.Health)" -ForegroundColor White
                Write-Host "  Updated: $($_.DateUpdated)" -ForegroundColor White
            }
        }
    } else {
        Write-Host "[ERROR] Failed to access Elastic Beanstalk API" -ForegroundColor Red
        $envs
    }
} catch {
    Write-Host "[ERROR] Exception: $_" -ForegroundColor Red
}
Write-Host ""

# 4. Test Network Connectivity
Write-Host "4. Testing Network Connectivity:" -ForegroundColor Cyan
$endpoints = @(
    "elasticbeanstalk.us-east-1.amazonaws.com",
    "s3.us-east-1.amazonaws.com",
    "sts.us-east-1.amazonaws.com"
)

foreach ($endpoint in $endpoints) {
    Write-Host "  Testing $endpoint..." -ForegroundColor Yellow
    $result = Test-NetConnection -ComputerName $endpoint -Port 443 -WarningAction SilentlyContinue
    if ($result.TcpTestSucceeded) {
        Write-Host "    [OK] Port 443 accessible" -ForegroundColor Green
    } else {
        Write-Host "    [FAIL] Port 443 not accessible" -ForegroundColor Red
    }
}
Write-Host ""

# 5. Check DNS Resolution
Write-Host "5. DNS Resolution:" -ForegroundColor Cyan
try {
    $dns = Resolve-DnsName -Name "elasticbeanstalk.us-east-1.amazonaws.com" -ErrorAction SilentlyContinue
    if ($dns) {
        Write-Host "[OK] DNS resolution successful" -ForegroundColor Green
        $dns | Select-Object Name, IPAddress | Format-Table
    } else {
        Write-Host "[ERROR] DNS resolution failed" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] DNS resolution exception: $_" -ForegroundColor Red
}
Write-Host ""

# 6. Check Proxy Settings
Write-Host "6. Proxy Settings:" -ForegroundColor Cyan
$proxyVars = @("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "NO_PROXY", "no_proxy")
$foundProxy = $false
foreach ($var in $proxyVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        Write-Host "  $var = $value" -ForegroundColor Yellow
        $foundProxy = $true
    }
}
if (-not $foundProxy) {
    Write-Host "[OK] No proxy environment variables set" -ForegroundColor Green
}
Write-Host ""

# 7. Check EB CLI Configuration
Write-Host "7. EB CLI Configuration:" -ForegroundColor Cyan
try {
    $ebVersion = eb --version 2>&1
    Write-Host "[OK] EB CLI installed: $ebVersion" -ForegroundColor Green
    
    if (Test-Path ".elasticbeanstalk") {
        Write-Host "[OK] .elasticbeanstalk directory exists" -ForegroundColor Green
        Get-ChildItem ".elasticbeanstalk" | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor White
        }
    } else {
        Write-Host "[WARNING] .elasticbeanstalk directory not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] EB CLI not found or error: $_" -ForegroundColor Red
}
Write-Host ""

# 8. Recommendations
Write-Host "=== Recommendations ===" -ForegroundColor Green
Write-Host ""
Write-Host "If all tests pass but 'eb deploy' still fails:" -ForegroundColor Yellow
Write-Host "  1. Try deploying again: eb deploy" -ForegroundColor White
Write-Host "  2. Check if deployment is already in progress: eb status" -ForegroundColor White
Write-Host "  3. Wait for current deployment to complete" -ForegroundColor White
Write-Host "  4. If stuck, try: eb abort" -ForegroundColor White
Write-Host ""
Write-Host "If network tests fail:" -ForegroundColor Yellow
Write-Host "  1. Check firewall settings" -ForegroundColor White
Write-Host "  2. Check VPN/proxy configuration" -ForegroundColor White
Write-Host "  3. Try from a different network" -ForegroundColor White
Write-Host ""

