# Create indexes locally and upload to S3
# This avoids disk space issues on the server

Write-Host "=== Creating Indexes Locally ===" -ForegroundColor Cyan
Write-Host ""

$DB_PATH = ".\nyc_taxi.db"

# Check if database exists
if (-not (Test-Path $DB_PATH)) {
    Write-Host "Error: Database file not found at $DB_PATH" -ForegroundColor Red
    Write-Host "Please ensure you're in the backend directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "Database found: $DB_PATH" -ForegroundColor Green
$dbSize = (Get-Item $DB_PATH).Length / 1GB
Write-Host "Database size: $([math]::Round($dbSize, 2)) GB" -ForegroundColor Gray
Write-Host ""

# Check existing indexes
Write-Host "Checking existing indexes..." -ForegroundColor Yellow
$existingIndexes = sqlite3 $DB_PATH "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
Write-Host "Existing indexes: $($existingIndexes.Count)" -ForegroundColor Gray
Write-Host ""

# Apply PRAGMA settings
Write-Host "1. Applying SQLite optimizations..." -ForegroundColor Yellow
sqlite3 $DB_PATH "PRAGMA journal_mode=WAL;"
sqlite3 $DB_PATH "PRAGMA cache_size=-256000;"
sqlite3 $DB_PATH "PRAGMA synchronous=NORMAL;"
sqlite3 $DB_PATH "ANALYZE;"
Write-Host "✅ PRAGMA settings applied" -ForegroundColor Green
Write-Host ""

# Create indexes one by one
Write-Host "2. Creating indexes..." -ForegroundColor Yellow
Write-Host ""

# Index 1: Revenue covering (if not exists)
if ($existingIndexes -notcontains "idx_revenue_covering") {
    Write-Host "[1/5] Creating idx_revenue_covering..." -ForegroundColor Cyan
    sqlite3 $DB_PATH "CREATE INDEX IF NOT EXISTS idx_revenue_covering ON trips(tpep_pickup_datetime, pulocationid, total_amount, fare_amount, tip_amount);"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Index 1/5 created: idx_revenue_covering" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create idx_revenue_covering" -ForegroundColor Red
    }
} else {
    Write-Host "[1/5] idx_revenue_covering already exists" -ForegroundColor Gray
}
Write-Host ""

# Index 2: Efficiency timeseries (if not exists)
if ($existingIndexes -notcontains "idx_efficiency_timeseries") {
    Write-Host "[2/5] Creating idx_efficiency_timeseries..." -ForegroundColor Cyan
    sqlite3 $DB_PATH "CREATE INDEX IF NOT EXISTS idx_efficiency_timeseries ON trips(tpep_pickup_datetime, total_amount, tpep_dropoff_datetime);"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Index 2/5 created: idx_efficiency_timeseries" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create idx_efficiency_timeseries" -ForegroundColor Red
    }
} else {
    Write-Host "[2/5] idx_efficiency_timeseries already exists" -ForegroundColor Gray
}
Write-Host ""

# Index 3: Zone revenue (if not exists)
if ($existingIndexes -notcontains "idx_zone_revenue") {
    Write-Host "[3/5] Creating idx_zone_revenue..." -ForegroundColor Cyan
    sqlite3 $DB_PATH "CREATE INDEX IF NOT EXISTS idx_zone_revenue ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Index 3/5 created: idx_zone_revenue" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create idx_zone_revenue" -ForegroundColor Red
    }
} else {
    Write-Host "[3/5] idx_zone_revenue already exists" -ForegroundColor Gray
}
Write-Host ""

# Index 4: Wait time demand (if not exists)
if ($existingIndexes -notcontains "idx_wait_time_demand") {
    Write-Host "[4/5] Creating idx_wait_time_demand..." -ForegroundColor Cyan
    sqlite3 $DB_PATH "CREATE INDEX IF NOT EXISTS idx_wait_time_demand ON trips(pulocationid, tpep_pickup_datetime);"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Index 4/5 created: idx_wait_time_demand" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create idx_wait_time_demand" -ForegroundColor Red
    }
} else {
    Write-Host "[4/5] idx_wait_time_demand already exists" -ForegroundColor Gray
}
Write-Host ""

# Index 5: Wait time supply (if not exists)
if ($existingIndexes -notcontains "idx_wait_time_supply") {
    Write-Host "[5/5] Creating idx_wait_time_supply..." -ForegroundColor Cyan
    sqlite3 $DB_PATH "CREATE INDEX IF NOT EXISTS idx_wait_time_supply ON trips(dolocationid, tpep_dropoff_datetime);"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Index 5/5 created: idx_wait_time_supply" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create idx_wait_time_supply" -ForegroundColor Red
    }
} else {
    Write-Host "[5/5] idx_wait_time_supply already exists" -ForegroundColor Gray
}
Write-Host ""

# Verify indexes
Write-Host "3. Verifying indexes..." -ForegroundColor Yellow
$indexCount = sqlite3 $DB_PATH "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
Write-Host "Total indexes on trips table: $indexCount" -ForegroundColor Green
Write-Host ""

Write-Host "All indexes:" -ForegroundColor Yellow
sqlite3 $DB_PATH "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips' ORDER BY name;"
Write-Host ""

# Check new database size
$newDbSize = (Get-Item $DB_PATH).Length / 1GB
Write-Host "New database size: $([math]::Round($newDbSize, 2)) GB" -ForegroundColor Gray
Write-Host "Size increase: $([math]::Round(($newDbSize - $dbSize), 2)) GB" -ForegroundColor Gray
Write-Host ""

# Ask to upload
Write-Host "=== Upload to S3? ===" -ForegroundColor Cyan
$upload = Read-Host "Upload optimized database to S3? (y/n)"

if ($upload -eq "y" -or $upload -eq "Y") {
    Write-Host "Uploading to S3..." -ForegroundColor Yellow
    aws s3 cp $DB_PATH s3://nyc-taxi-data-800155829166/nyc_taxi.db
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database uploaded successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. SSH into server: eb ssh" -ForegroundColor White
        Write-Host "2. Stop service: sudo systemctl stop web.service" -ForegroundColor White
        Write-Host "3. Download: sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db" -ForegroundColor White
        Write-Host "4. Set permissions: sudo chown webapp:webapp nyc_taxi.db" -ForegroundColor White
        Write-Host "5. Start service: sudo systemctl start web.service" -ForegroundColor White
    } else {
        Write-Host "❌ Upload failed" -ForegroundColor Red
    }
} else {
    Write-Host "Skipping upload. You can upload later with:" -ForegroundColor Yellow
    Write-Host "aws s3 cp .\nyc_taxi.db s3://nyc-taxi-data-800155829166/nyc_taxi.db" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Complete ===" -ForegroundColor Green

