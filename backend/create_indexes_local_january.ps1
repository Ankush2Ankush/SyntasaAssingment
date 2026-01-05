# Create indexes on local database for January data
# This script creates all necessary indexes on the local nyc_taxi.db file
# After running this, upload the indexed database to S3 via AWS Console

Write-Host "`n=== Creating Indexes on Local Database ===" -ForegroundColor Cyan
Write-Host ""

# Check if database file exists
$dbPath = ".\nyc_taxi.db"
if (-not (Test-Path $dbPath)) {
    Write-Host "❌ Error: Database file not found at $dbPath" -ForegroundColor Red
    Write-Host "Please run this script from the backend directory where nyc_taxi.db is located" -ForegroundColor Yellow
    exit 1
}

# Get database size before indexing
$dbSizeBefore = (Get-Item $dbPath).Length / 1GB
Write-Host "1. Database file found: $dbPath" -ForegroundColor Green
Write-Host "   Size before indexing: $([math]::Round($dbSizeBefore, 2)) GB" -ForegroundColor Gray
Write-Host ""

# Check if sqlite3 is available
try {
    $null = sqlite3 --version
    Write-Host "2. SQLite3 found" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: sqlite3 not found. Please install SQLite or add it to PATH" -ForegroundColor Red
    exit 1
}

# Check current trip count
Write-Host "3. Checking database status..." -ForegroundColor Yellow
$tripCount = sqlite3 $dbPath "SELECT COUNT(*) FROM trips;"
Write-Host "   Trip count: $tripCount" -ForegroundColor Gray
Write-Host ""

# Check if indexes already exist
Write-Host "4. Checking for existing indexes..." -ForegroundColor Yellow
$existingIndexes = sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
if ($existingIndexes) {
    Write-Host "   ⚠️  Existing indexes found:" -ForegroundColor Yellow
    $existingIndexes | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
    Write-Host ""
    $response = Read-Host "   Do you want to recreate them? (y/n)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "   Skipping index creation." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "   Dropping existing indexes..." -ForegroundColor Yellow
    sqlite3 $dbPath "DROP INDEX IF EXISTS idx_pickup_datetime;"
    sqlite3 $dbPath "DROP INDEX IF EXISTS idx_dropoff_datetime;"
    sqlite3 $dbPath "DROP INDEX IF EXISTS idx_pulocationid;"
    sqlite3 $dbPath "DROP INDEX IF EXISTS idx_dolocationid;"
    sqlite3 $dbPath "DROP INDEX IF EXISTS idx_pickup_location_time;"
    sqlite3 $dbPath "DROP INDEX IF EXISTS idx_dropoff_location_time;"
    Write-Host "   ✅ Existing indexes dropped" -ForegroundColor Green
    Write-Host ""
}

# Create indexes
Write-Host "5. Creating indexes (this will take 5-15 minutes for January data)..." -ForegroundColor Yellow
Write-Host ""

$startTime = Get-Date

Write-Host "   Creating index 1/6: idx_pickup_datetime (critical for efficiency endpoint)..." -ForegroundColor Cyan
sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Index 1/6 done" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to create index 1/6" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "   Creating index 2/6: idx_dropoff_datetime..." -ForegroundColor Cyan
sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Index 2/6 done" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to create index 2/6" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "   Creating index 3/6: idx_pulocationid..." -ForegroundColor Cyan
sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Index 3/6 done" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to create index 3/6" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "   Creating index 4/6: idx_dolocationid..." -ForegroundColor Cyan
sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Index 4/6 done" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to create index 4/6" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "   Creating index 5/6: idx_pickup_location_time (composite)..." -ForegroundColor Cyan
sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Index 5/6 done" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to create index 5/6" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "   Creating index 6/6: idx_dropoff_location_time (composite)..." -ForegroundColor Cyan
sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Index 6/6 done" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to create index 6/6" -ForegroundColor Red
    exit 1
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalMinutes
Write-Host ""
Write-Host "   ⏱️  Total time: $([math]::Round($duration, 2)) minutes" -ForegroundColor Gray
Write-Host ""

# Verify indexes
Write-Host "6. Verifying indexes were created..." -ForegroundColor Yellow
$indexes = sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
if ($indexes) {
    Write-Host "   ✅ Created indexes:" -ForegroundColor Green
    $indexes | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
} else {
    Write-Host "   ❌ No indexes found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check database size after indexing
Write-Host "7. Checking database size after indexing..." -ForegroundColor Yellow
$dbSizeAfter = (Get-Item $dbPath).Length / 1GB
$sizeIncrease = $dbSizeAfter - $dbSizeBefore
Write-Host "   Size before: $([math]::Round($dbSizeBefore, 2)) GB" -ForegroundColor Gray
Write-Host "   Size after:  $([math]::Round($dbSizeAfter, 2)) GB" -ForegroundColor Gray
Write-Host "   Increase:    $([math]::Round($sizeIncrease, 2)) GB" -ForegroundColor Gray
Write-Host ""

# Run ANALYZE for query optimizer
Write-Host "8. Running ANALYZE for query optimizer..." -ForegroundColor Yellow
sqlite3 $dbPath "ANALYZE;"
Write-Host "   ✅ ANALYZE complete" -ForegroundColor Green
Write-Host ""

Write-Host "=== Index Creation Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "✅ All 6 indexes created successfully" -ForegroundColor Green
Write-Host "✅ Database optimized for January data queries" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Upload the indexed database to S3:" -ForegroundColor Yellow
Write-Host "   - Go to AWS Console → S3 → nyc-taxi-data-800155829166" -ForegroundColor White
Write-Host "   - Click 'Upload' → Select: $((Get-Item $dbPath).FullName)" -ForegroundColor White
Write-Host "   - Replace the existing nyc_taxi.db file" -ForegroundColor White
Write-Host ""
Write-Host "2. After upload, restore on EC2 instance:" -ForegroundColor Yellow
Write-Host "   - SSH into server: eb ssh" -ForegroundColor White
Write-Host "   - Run: sudo systemctl stop web.service" -ForegroundColor White
Write-Host "   - Run: cd /var/app/current" -ForegroundColor White
Write-Host "   - Run: sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db" -ForegroundColor White
Write-Host "   - Run: sudo chown webapp:webapp nyc_taxi.db" -ForegroundColor White
Write-Host "   - Run: sudo chmod 664 nyc_taxi.db" -ForegroundColor White
Write-Host "   - Run: sudo systemctl start web.service" -ForegroundColor White
Write-Host ""
Write-Host "Database file location: $((Get-Item $dbPath).FullName)" -ForegroundColor Gray
Write-Host ""



