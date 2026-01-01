# Phase 1.2: Create Deployment Package Script
# This script creates a deployment package excluding unnecessary files

Write-Host "=== Phase 1.2: Creating Deployment Package ===" -ForegroundColor Green
Write-Host ""

# Check if we're in the project root
if (-not (Test-Path "data") -or -not (Test-Path "backend")) {
    Write-Host "[ERROR] Please run this script from the project root (D:\Syntasa)" -ForegroundColor Red
    exit 1
}

# Create deployment directory
$deployDir = "deployment"
if (Test-Path $deployDir) {
    Write-Host "Removing existing deployment directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $deployDir
}

Write-Host "Creating deployment directory..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $deployDir | Out-Null

# Read exclude patterns
$excludePatterns = @(
    ".git",
    ".gitignore",
    "venv",
    "__pycache__",
    "node_modules",
    "*.db",
    "*.log",
    ".env",
    ".DS_Store",
    "Thumbs.db",
    "*.md",
    "localhost.har",
    "*.docx",
    "*.pdf",
    "deployment",
    "configure_aws_cli.ps1",
    "configure_aws_now.ps1",
    "fix_aws_path_and_configure.ps1",
    "refresh_aws_path.ps1",
    "setup_aws_credentials.ps1"
)

Write-Host ""
Write-Host "Copying project files (excluding unnecessary files)..." -ForegroundColor Cyan

# Copy backend folder
Write-Host "  Copying backend..." -ForegroundColor Gray
Copy-Item -Recurse -Path "backend" -Destination "$deployDir\backend" -Exclude @("venv", "__pycache__", "*.pyc", "*.db", "*.log", ".pytest_cache")

# Copy frontend folder (for reference, but we'll deploy separately)
Write-Host "  Copying frontend..." -ForegroundColor Gray
Copy-Item -Recurse -Path "frontend" -Destination "$deployDir\frontend" -Exclude @("node_modules", "dist", "build")

# Copy data folder (IMPORTANT - must be included!)
Write-Host "  Copying data folder (with parquet files)..." -ForegroundColor Gray
Copy-Item -Recurse -Path "data" -Destination "$deployDir\data"

# Copy root files
Write-Host "  Copying root configuration files..." -ForegroundColor Gray
$rootFiles = @("requirements.txt", ".gitignore")
foreach ($file in $rootFiles) {
    if (Test-Path $file) {
        Copy-Item $file -Destination "$deployDir\" -ErrorAction SilentlyContinue
    }
}

# Verify data files are present
Write-Host ""
Write-Host "Verifying data files in deployment package..." -ForegroundColor Cyan
$requiredFiles = @(
    "yellow_tripdata_2025-01.parquet",
    "yellow_tripdata_2025-02.parquet",
    "yellow_tripdata_2025-03.parquet",
    "yellow_tripdata_2025-04.parquet",
    "taxi_zone_lookup.csv"
)

$allPresent = $true
foreach ($file in $requiredFiles) {
    $filePath = Join-Path "$deployDir\data" $file
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
    Write-Host "[ERROR] Some data files are missing from deployment package!" -ForegroundColor Red
    exit 1
}

# Calculate deployment package size
$totalSize = (Get-ChildItem -Path $deployDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host ""
Write-Host "=== Deployment Package Created Successfully ===" -ForegroundColor Green
Write-Host "  Location: $deployDir\" -ForegroundColor White
Write-Host "  Total Size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "Package Contents:" -ForegroundColor Cyan
Write-Host "  - backend/ (application code)" -ForegroundColor Gray
Write-Host "  - frontend/ (for reference)" -ForegroundColor Gray
Write-Host "  - data/ (parquet files - REQUIRED for ETL)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next: Proceed to Phase 2 (AWS Backend Deployment)" -ForegroundColor Yellow
Write-Host ""


