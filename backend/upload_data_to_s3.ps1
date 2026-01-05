# Script to upload data files to S3 for Elastic Beanstalk deployment
# Run this script once before deploying to upload data files to S3

param(
    [Parameter(Mandatory=$true)]
    [string]$BucketName,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$DataPath = "..\data"
)

Write-Host "=== Upload Data Files to S3 ===" -ForegroundColor Green
Write-Host ""

# Check if AWS CLI is available
try {
    $awsVersion = aws --version 2>&1
    Write-Host "AWS CLI found: $awsVersion" -ForegroundColor Cyan
} catch {
    Write-Host "[ERROR] AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Check if bucket exists
Write-Host "Checking if bucket exists: $BucketName" -ForegroundColor Cyan
$bucketCheck = aws s3 ls "s3://$BucketName" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Bucket does not exist. Creating bucket..." -ForegroundColor Yellow
    aws s3 mb "s3://$BucketName" --region $Region
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to create bucket. Please create it manually or check permissions." -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Bucket created successfully" -ForegroundColor Green
} else {
    Write-Host "[OK] Bucket exists" -ForegroundColor Green
}

# Check if data directory exists
if (-not (Test-Path $DataPath)) {
    Write-Host "[ERROR] Data directory not found: $DataPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Uploading data files to s3://$BucketName/data/..." -ForegroundColor Cyan
Write-Host ""

# Upload parquet files
$parquetFiles = @(
    "yellow_tripdata_2025-01.parquet",
    "yellow_tripdata_2025-02.parquet",
    "yellow_tripdata_2025-03.parquet",
    "yellow_tripdata_2025-04.parquet"
)

foreach ($file in $parquetFiles) {
    $filePath = Join-Path $DataPath $file
    if (Test-Path $filePath) {
        Write-Host "  Uploading $file..." -ForegroundColor Gray
        aws s3 cp $filePath "s3://$BucketName/data/$file"
        if ($LASTEXITCODE -eq 0) {
            $fileSize = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
            Write-Host "    [OK] $file ($fileSize MB)" -ForegroundColor Green
        } else {
            Write-Host "    [ERROR] Failed to upload $file" -ForegroundColor Red
        }
    } else {
        Write-Host "    [WARNING] File not found: $file" -ForegroundColor Yellow
    }
}

# Upload CSV file
$csvFile = "taxi_zone_lookup.csv"
$csvPath = Join-Path $DataPath $csvFile
if (Test-Path $csvPath) {
    Write-Host "  Uploading $csvFile..." -ForegroundColor Gray
    aws s3 cp $csvPath "s3://$BucketName/data/$csvFile"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] $csvFile" -ForegroundColor Green
    } else {
        Write-Host "    [ERROR] Failed to upload $csvFile" -ForegroundColor Red
    }
} else {
    Write-Host "    [WARNING] File not found: $csvFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Upload Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Set S3_DATA_BUCKET environment variable in Elastic Beanstalk:" -ForegroundColor White
Write-Host "   eb setenv S3_DATA_BUCKET=$BucketName" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Ensure your EC2 instance role has S3 read permissions:" -ForegroundColor White
Write-Host "   Attach policy: AmazonS3ReadOnlyAccess" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Deploy your application:" -ForegroundColor White
Write-Host "   eb deploy" -ForegroundColor Gray
Write-Host ""




