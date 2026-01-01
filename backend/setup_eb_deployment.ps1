# Elastic Beanstalk Deployment Setup Script
# This script prepares the backend for EB deployment

Write-Host "=== Elastic Beanstalk Deployment Setup ===" -ForegroundColor Green
Write-Host ""

# Check if we're in backend directory
if (-not (Test-Path "app") -or -not (Test-Path "run_etl.py")) {
    Write-Host "[ERROR] Please run this script from the backend directory" -ForegroundColor Red
    exit 1
}

# Check if data folder exists (should be copied from parent)
$dataPath = "data"
if (-not (Test-Path $dataPath)) {
    Write-Host "[INFO] Data folder not found. Checking parent directory..." -ForegroundColor Yellow
    $parentDataPath = "..\data"
    if (Test-Path $parentDataPath) {
        Write-Host "Copying data folder from parent directory..." -ForegroundColor Cyan
        Copy-Item -Recurse -Path $parentDataPath -Destination $dataPath
        Write-Host "[OK] Data folder copied" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Data folder not found in parent directory!" -ForegroundColor Red
        Write-Host "Please ensure data/ folder with parquet files exists" -ForegroundColor Yellow
        exit 1
    }
}

# Verify required data files
Write-Host ""
Write-Host "Verifying data files..." -ForegroundColor Cyan
$requiredFiles = @(
    "yellow_tripdata_2025-01.parquet",
    "yellow_tripdata_2025-02.parquet",
    "yellow_tripdata_2025-03.parquet",
    "yellow_tripdata_2025-04.parquet",
    "taxi_zone_lookup.csv"
)

$allPresent = $true
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $dataPath $file
    if (Test-Path $filePath) {
        $size = (Get-Item $filePath).Length / 1MB
        Write-Host "  [OK] $file ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Missing: $file" -ForegroundColor Red
        $allPresent = $false
    }
}

if (-not $allPresent) {
    Write-Host ""
    Write-Host "[ERROR] Some data files are missing!" -ForegroundColor Red
    exit 1
}

# Check .ebextensions directory
if (-not (Test-Path ".ebextensions")) {
    Write-Host ""
    Write-Host "[ERROR] .ebextensions directory not found!" -ForegroundColor Red
    Write-Host "Configuration files should be in .ebextensions/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Initialize EB: eb init" -ForegroundColor White
Write-Host "   - Select region: us-east-1" -ForegroundColor Gray
Write-Host "   - Application name: nyc-taxi-api" -ForegroundColor Gray
Write-Host "   - Platform: Python" -ForegroundColor Gray
Write-Host "   - Python version: 3.11" -ForegroundColor Gray
Write-Host "   - SSH: Yes" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Create environment: eb create nyc-taxi-api-env" -ForegroundColor White
Write-Host "   - Instance type: t3.medium (recommended for ETL)" -ForegroundColor Gray
Write-Host "   - Environment type: Single instance" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Deploy: eb deploy" -ForegroundColor White
Write-Host ""


