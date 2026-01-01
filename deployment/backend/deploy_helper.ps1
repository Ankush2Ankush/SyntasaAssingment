# Deployment Helper Script for Windows
# This script helps prepare the deployment package for AWS

Write-Host "=== NYC Taxi API Deployment Helper ===" -ForegroundColor Green
Write-Host ""

# Check if data folder exists
$dataPath = "..\data"
if (-not (Test-Path $dataPath)) {
    Write-Host "ERROR: data/ folder not found at $dataPath" -ForegroundColor Red
    Write-Host "Please ensure parquet files are in the data/ folder" -ForegroundColor Yellow
    exit 1
}

# Check for required parquet files
$requiredFiles = @(
    "yellow_tripdata_2025-01.parquet",
    "yellow_tripdata_2025-02.parquet",
    "yellow_tripdata_2025-03.parquet",
    "yellow_tripdata_2025-04.parquet",
    "taxi_zone_lookup.csv"
)

Write-Host "Checking for required data files..." -ForegroundColor Cyan
$missingFiles = @()
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $dataPath $file
    if (Test-Path $filePath) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "ERROR: Missing required data files!" -ForegroundColor Red
    exit 1
}

# Check for database file (should NOT be included)
$dbFile = "nyc_taxi.db"
if (Test-Path $dbFile) {
    Write-Host ""
    Write-Host "WARNING: Database file found. It will be generated on server." -ForegroundColor Yellow
}

# Create deployment directory
$deployDir = "deployment"
if (Test-Path $deployDir) {
    Write-Host ""
    Write-Host "Removing existing deployment directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $deployDir
}

Write-Host ""
Write-Host "Creating deployment package..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $deployDir | Out-Null

# Copy backend files
Write-Host "  Copying backend files..." -ForegroundColor Gray
Copy-Item -Recurse -Exclude @("__pycache__", "*.pyc", ".pytest_cache", "venv", ".venv", "*.db", "*.log") -Path "app" -Destination "$deployDir\app"
Copy-Item "run_etl.py" -Destination "$deployDir\"
Copy-Item "requirements.txt" -Destination "$deployDir\"
Copy-Item -Recurse ".ebextensions" -Destination "$deployDir\.ebextensions" -ErrorAction SilentlyContinue

# Copy data folder
Write-Host "  Copying data files..." -ForegroundColor Gray
Copy-Item -Recurse $dataPath -Destination "$deployDir\data"

# Create .ebignore to exclude unnecessary files
Write-Host "  Creating .ebignore..." -ForegroundColor Gray
@"
*.db
*.log
__pycache__/
*.pyc
.pytest_cache/
venv/
.venv/
.git/
.gitignore
*.md
"@ | Out-File -FilePath "$deployDir\.ebignore" -Encoding UTF8

# Create deployment zip
$zipFile = "deploy.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile
}

Write-Host ""
Write-Host "Creating deployment zip file..." -ForegroundColor Cyan
Compress-Archive -Path "$deployDir\*" -DestinationPath $zipFile -Force

$zipSize = (Get-Item $zipFile).Length / 1MB
Write-Host ""
Write-Host "=== Deployment Package Ready ===" -ForegroundColor Green
Write-Host "  Package: $zipFile" -ForegroundColor White
Write-Host "  Size: $([math]::Round($zipSize, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review deployment package contents" -ForegroundColor Gray
Write-Host "  2. Deploy using: eb deploy --source $zipFile" -ForegroundColor Gray
Write-Host "  3. Monitor ETL process in logs: eb logs" -ForegroundColor Gray
Write-Host ""

