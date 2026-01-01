# Prerequisites Setup Script for Deployment
# This script checks and helps set up all prerequisites for Method 1 deployment

Write-Host "=== Deployment Prerequisites Setup ===" -ForegroundColor Green
Write-Host ""

$allGood = $true

# 1. Check Python
Write-Host "1. Checking Python..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python 3\.(1[1-9]|[2-9][0-9])") {
        Write-Host "   [OK] $pythonVersion" -ForegroundColor Green
    } else {
        Write-Host "   [WARNING] Python version: $pythonVersion" -ForegroundColor Yellow
        Write-Host "   [INFO] Python 3.11+ recommended" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [ERROR] Python not found!" -ForegroundColor Red
    Write-Host "   [INFO] Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    $allGood = $false
}

# 2. Check Node.js
Write-Host ""
Write-Host "2. Checking Node.js..." -ForegroundColor Cyan
$nodeFound = $false
try {
    $nodeVersion = node --version 2>&1
    if ($nodeVersion -and $nodeVersion -match "v(1[8-9]|[2-9][0-9])") {
        Write-Host "   [OK] $nodeVersion" -ForegroundColor Green
        $nodeFound = $true
    }
} catch {
    # Try alternative method
    try {
        if (Test-Path "C:\Program Files\nodejs\node.exe") {
            $nodeVersion = & "C:\Program Files\nodejs\node.exe" --version 2>&1
            if ($nodeVersion -match "v(1[8-9]|[2-9][0-9])") {
                Write-Host "   [OK] $nodeVersion" -ForegroundColor Green
                $nodeFound = $true
            }
        }
    } catch {
        # Continue to error handling
    }
}

if (-not $nodeFound) {
    Write-Host "   [WARNING] Could not determine Node.js version" -ForegroundColor Yellow
    Write-Host "   [INFO] Node.js 18+ recommended" -ForegroundColor Yellow
}

try {
    $npmVersion = npm --version 2>&1
    if ($npmVersion) {
        Write-Host "   [OK] npm $npmVersion" -ForegroundColor Green
        if (-not $nodeFound) {
            Write-Host "   [INFO] Node.js appears to be installed (npm found)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   [ERROR] npm not found!" -ForegroundColor Red
    Write-Host "   [INFO] Download Node.js from: https://nodejs.org/" -ForegroundColor Yellow
    $allGood = $false
}

# 3. Check AWS CLI
Write-Host ""
Write-Host "3. Checking AWS CLI..." -ForegroundColor Cyan
try {
    $awsVersion = aws --version 2>&1
    Write-Host "   [OK] $awsVersion" -ForegroundColor Green
    
    # Check if configured
    Write-Host "   Checking AWS configuration..." -ForegroundColor Gray
    $awsConfigured = $false
    try {
        $awsIdentity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [OK] AWS CLI is configured" -ForegroundColor Green
            $awsConfigured = $true
        } else {
            Write-Host "   [WARNING] AWS CLI not configured" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   [WARNING] AWS CLI not configured" -ForegroundColor Yellow
    }
    
    if (-not $awsConfigured) {
        Write-Host ""
        Write-Host "   To configure AWS CLI, run:" -ForegroundColor Yellow
        Write-Host "   aws configure" -ForegroundColor White
        Write-Host ""
        Write-Host "   You'll need:" -ForegroundColor Yellow
        Write-Host "   - AWS Access Key ID" -ForegroundColor Gray
        Write-Host "   - AWS Secret Access Key" -ForegroundColor Gray
        Write-Host "   - Default region (e.g., us-east-1)" -ForegroundColor Gray
        Write-Host "   - Default output format (json)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   [ERROR] AWS CLI not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "   To install AWS CLI, choose one of the following methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Method 1: Download and install MSI (Recommended)" -ForegroundColor Cyan
    Write-Host "   1. Download from: https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor White
    Write-Host "   2. Run the installer as Administrator" -ForegroundColor White
    Write-Host "   3. Restart your terminal after installation" -ForegroundColor White
    Write-Host ""
    Write-Host "   Method 2: Using Chocolatey (requires admin PowerShell)" -ForegroundColor Cyan
    Write-Host "   Run PowerShell as Administrator, then:" -ForegroundColor White
    Write-Host "   choco install awscli -y" -ForegroundColor White
    Write-Host ""
    Write-Host "   Method 3: Using winget (Windows 10/11)" -ForegroundColor Cyan
    Write-Host "   Run PowerShell as Administrator, then:" -ForegroundColor White
    Write-Host "   winget install Amazon.AWSCLI" -ForegroundColor White
    Write-Host ""
    $allGood = $false
}

# 4. Check Git
Write-Host ""
Write-Host "4. Checking Git..." -ForegroundColor Cyan
try {
    $gitVersion = git --version 2>&1
    Write-Host "   [OK] $gitVersion" -ForegroundColor Green
    
    # Check if in git repository
    $gitRemote = git remote -v 2>&1
    if ($gitRemote) {
        Write-Host "   [OK] Git repository configured" -ForegroundColor Green
        Write-Host "   Remote: $(($gitRemote -split "`n")[0])" -ForegroundColor Gray
    } else {
        Write-Host "   [WARNING] No git remote configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [ERROR] Git not found!" -ForegroundColor Red
    Write-Host "   [INFO] Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
    $allGood = $false
}

# 5. Check for large files in git
Write-Host ""
Write-Host "5. Checking Git repository for large files..." -ForegroundColor Cyan
$largeFiles = git ls-files | Select-String -Pattern "\.db$|\.parquet$"
if ($largeFiles) {
    Write-Host "   [ERROR] Large files found in git!" -ForegroundColor Red
    Write-Host "   Files:" -ForegroundColor Yellow
    $largeFiles | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }
    Write-Host "   [INFO] These files should be removed from git history" -ForegroundColor Yellow
    $allGood = $false
} else {
    Write-Host "   [OK] No large files in git repository" -ForegroundColor Green
}

# 6. Check data files
Write-Host ""
Write-Host "6. Checking data files..." -ForegroundColor Cyan
$dataPath = "data"
$requiredFiles = @(
    "yellow_tripdata_2025-01.parquet",
    "yellow_tripdata_2025-02.parquet",
    "yellow_tripdata_2025-03.parquet",
    "yellow_tripdata_2025-04.parquet",
    "taxi_zone_lookup.csv"
)

$allFilesPresent = $true
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $dataPath $file
    if (Test-Path $filePath) {
        $fileSize = (Get-Item $filePath).Length / 1MB
        Write-Host "   [OK] $file ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Missing: $file" -ForegroundColor Red
        $allFilesPresent = $false
        $allGood = $false
    }
}

# 7. Check EB CLI (optional but recommended)
Write-Host ""
Write-Host "7. Checking Elastic Beanstalk CLI (optional)..." -ForegroundColor Cyan
try {
    $ebVersion = eb --version 2>&1
    Write-Host "   [OK] $ebVersion" -ForegroundColor Green
} catch {
    Write-Host "   [INFO] EB CLI not installed (optional for Elastic Beanstalk deployment)" -ForegroundColor Yellow
    Write-Host "   Install with: pip install awsebcli" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Green
if ($allGood) {
    Write-Host "[SUCCESS] All prerequisites are ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. If AWS CLI not configured, run: aws configure" -ForegroundColor White
    Write-Host "2. Review deployment guide: DEPLOYMENT_GUIDE_METHOD1.md" -ForegroundColor White
    Write-Host "3. Run deployment helper: cd backend; .\deploy_helper.ps1" -ForegroundColor White
} else {
    Write-Host "[ACTION REQUIRED] Some prerequisites are missing or need configuration" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please fix the issues above before proceeding with deployment." -ForegroundColor Yellow
}

Write-Host ""

