# Quick IAM Permissions Check and Guide
# This script helps identify and fix IAM permission issues

Write-Host "=== IAM Permissions Check for Elastic Beanstalk ===" -ForegroundColor Green
Write-Host ""

# Check current user
Write-Host "Checking current AWS user..." -ForegroundColor Cyan
try {
    $identity = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "  User: $($identity.Arn)" -ForegroundColor White
    Write-Host "  Account: $($identity.Account)" -ForegroundColor White
} catch {
    Write-Host "  [ERROR] Could not get user identity" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Issue Detected ===" -ForegroundColor Yellow
Write-Host "Your IAM user doesn't have permissions to create IAM roles." -ForegroundColor Yellow
Write-Host ""
Write-Host "Required permissions:" -ForegroundColor Cyan
Write-Host "  - iam:CreateRole" -ForegroundColor White
Write-Host "  - iam:PassRole" -ForegroundColor White
Write-Host "  - iam:CreateInstanceProfile" -ForegroundColor White
Write-Host ""

Write-Host "=== Solutions ===" -ForegroundColor Green
Write-Host ""
Write-Host "Option 1: Add PowerUserAccess Policy (Quickest)" -ForegroundColor Cyan
Write-Host "  1. Go to: https://console.aws.amazon.com/iam/" -ForegroundColor White
Write-Host "  2. Users → deployment-user → Add permissions" -ForegroundColor White
Write-Host "  3. Attach policy: PowerUserAccess" -ForegroundColor White
Write-Host "  4. Click Add permissions" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: Add IAMFullAccess Policy" -ForegroundColor Cyan
Write-Host "  1. Same as above, but attach: IAMFullAccess" -ForegroundColor White
Write-Host "  2. This gives full IAM access (use with caution)" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3: Create Roles Manually" -ForegroundColor Cyan
Write-Host "  See: FIX_IAM_PERMISSIONS.md for detailed steps" -ForegroundColor White
Write-Host ""
Write-Host "Option 4: Use Existing Roles" -ForegroundColor Cyan
Write-Host "  If roles exist, specify them:" -ForegroundColor White
Write-Host "  eb create nyc-taxi-api-env --service-role aws-elasticbeanstalk-service-role --instance-profile aws-elasticbeanstalk-ec2-role" -ForegroundColor Gray
Write-Host ""

# Check if roles exist
Write-Host "Checking if roles already exist..." -ForegroundColor Cyan
try {
    $serviceRole = aws iam get-role --role-name aws-elasticbeanstalk-service-role 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] aws-elasticbeanstalk-service-role exists" -ForegroundColor Green
    } else {
        Write-Host "  [NOT FOUND] aws-elasticbeanstalk-service-role" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [NOT FOUND] aws-elasticbeanstalk-service-role" -ForegroundColor Yellow
}

try {
    $ec2Role = aws iam get-role --role-name aws-elasticbeanstalk-ec2-role 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] aws-elasticbeanstalk-ec2-role exists" -ForegroundColor Green
    } else {
        Write-Host "  [NOT FOUND] aws-elasticbeanstalk-ec2-role" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [NOT FOUND] aws-elasticbeanstalk-ec2-role" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Fix IAM permissions using one of the options above" -ForegroundColor White
Write-Host "2. Wait 1-2 minutes for permissions to propagate" -ForegroundColor White
Write-Host "3. Retry: eb create nyc-taxi-api-env" -ForegroundColor White
Write-Host ""


