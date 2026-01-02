# Fast method: Create new table with January data only
# This is much faster than DELETE on large datasets

Write-Host "`n=== Fast Method: Create January-Only Database ===" -ForegroundColor Cyan
Write-Host ""

# Check if database file exists
$dbPath = ".\nyc_taxi.db"
if (-not (Test-Path $dbPath)) {
    Write-Host "❌ Error: Database file not found at $dbPath" -ForegroundColor Red
    exit 1
}

# Check if sqlite3 is available
try {
    $null = sqlite3 --version
} catch {
    Write-Host "❌ Error: sqlite3 not found" -ForegroundColor Red
    exit 1
}

# Get current status
$dbSizeBefore = (Get-Item $dbPath).Length / 1GB
Write-Host "1. Current database status:" -ForegroundColor Yellow
Write-Host "   Size: $([math]::Round($dbSizeBefore, 2)) GB" -ForegroundColor Gray

$tripCountBefore = sqlite3 $dbPath "SELECT COUNT(*) FROM trips;"
$januaryCount = sqlite3 $dbPath "SELECT COUNT(*) FROM trips WHERE tpep_pickup_datetime >= '2025-01-01' AND tpep_pickup_datetime < '2025-02-01';"

Write-Host "   Total trips: $tripCountBefore" -ForegroundColor Gray
Write-Host "   January trips: $januaryCount" -ForegroundColor Green
Write-Host ""

# Check if the DELETE is still running
Write-Host "2. Checking if previous operation is still running..." -ForegroundColor Yellow
Write-Host "   If the DELETE is stuck, you can:" -ForegroundColor Yellow
Write-Host "   - Press Ctrl+C to cancel" -ForegroundColor White
Write-Host "   - Close the terminal and restart" -ForegroundColor White
Write-Host "   - Use this fast method instead`n" -ForegroundColor White

# Fast method: Create new table with January data
Write-Host "3. Fast Method: Creating new table with January data only..." -ForegroundColor Cyan
Write-Host "   This method:" -ForegroundColor Gray
Write-Host "   - Creates a new table with only January data" -ForegroundColor Gray
Write-Host "   - Drops the old table" -ForegroundColor Gray
Write-Host "   - Renames the new table" -ForegroundColor Gray
Write-Host "   - Much faster than DELETE (5-10 minutes vs 20+ minutes)" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "   Proceed with fast method? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "   Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n   Step 1: Creating temporary table with January data..." -ForegroundColor Cyan
Write-Host "   This will take 5-10 minutes for 3.7M rows..." -ForegroundColor Gray
$startTime = Get-Date

# Create new table with January data (single line SQL)
$sqlCommand = "CREATE TABLE trips_january AS SELECT * FROM trips WHERE tpep_pickup_datetime >= '2025-01-01' AND tpep_pickup_datetime < '2025-02-01';"
echo $sqlCommand | sqlite3 $dbPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to create new table" -ForegroundColor Red
    exit 1
}

$createTime = (Get-Date) - $startTime
Write-Host "   ✅ New table created in $([math]::Round($createTime.TotalMinutes, 2)) minutes" -ForegroundColor Green

# Verify count
$newCount = sqlite3 $dbPath "SELECT COUNT(*) FROM trips_january;"
Write-Host "   Verified: $newCount trips in new table" -ForegroundColor Green
Write-Host ""

Write-Host "   Step 2: Dropping old table..." -ForegroundColor Cyan
sqlite3 $dbPath "DROP TABLE trips;"
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to drop old table" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Old table dropped" -ForegroundColor Green
Write-Host ""

Write-Host "   Step 3: Renaming new table..." -ForegroundColor Cyan
sqlite3 $dbPath "ALTER TABLE trips_january RENAME TO trips;"
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to rename table" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ Table renamed" -ForegroundColor Green
Write-Host ""

Write-Host "   Step 4: Running VACUUM to reclaim space..." -ForegroundColor Cyan
Write-Host "   This will take 5-10 minutes..." -ForegroundColor Gray
$vacuumStart = Get-Date
sqlite3 $dbPath "VACUUM;"
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ VACUUM failed" -ForegroundColor Red
    exit 1
}
$vacuumTime = (Get-Date) - $vacuumStart
Write-Host "   ✅ VACUUM complete in $([math]::Round($vacuumTime.TotalMinutes, 2)) minutes" -ForegroundColor Green
Write-Host ""

# Check final size
$dbSizeAfter = (Get-Item $dbPath).Length / 1GB
$sizeReduction = $dbSizeBefore - $dbSizeAfter
Write-Host "4. Database after reduction:" -ForegroundColor Yellow
Write-Host "   Size before: $([math]::Round($dbSizeBefore, 2)) GB" -ForegroundColor Gray
Write-Host "   Size after:  $([math]::Round($dbSizeAfter, 2)) GB" -ForegroundColor Green
Write-Host "   Reduction:   $([math]::Round($sizeReduction, 2)) GB" -ForegroundColor Green
Write-Host ""

# Ask to create indexes
Write-Host "5. Create indexes now?" -ForegroundColor Yellow
Write-Host "   This will add ~500MB-800MB but make queries 10-100x faster" -ForegroundColor Gray
$createIndexes = Read-Host "   Create indexes? (y/n)"
Write-Host ""

if ($createIndexes -eq 'y' -or $createIndexes -eq 'Y') {
    Write-Host "Creating indexes (5-10 minutes)..." -ForegroundColor Cyan
    Write-Host ""
    
    $indexStart = Get-Date
    
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);"
    Write-Host "   ✅ Index 1/6: idx_pickup_datetime" -ForegroundColor Green
    
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);"
    Write-Host "   ✅ Index 2/6: idx_dropoff_datetime" -ForegroundColor Green
    
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);"
    Write-Host "   ✅ Index 3/6: idx_pulocationid" -ForegroundColor Green
    
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);"
    Write-Host "   ✅ Index 4/6: idx_dolocationid" -ForegroundColor Green
    
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);"
    Write-Host "   ✅ Index 5/6: idx_pickup_location_time" -ForegroundColor Green
    
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);"
    Write-Host "   ✅ Index 6/6: idx_dropoff_location_time" -ForegroundColor Green
    
    $indexTime = (Get-Date) - $indexStart
    Write-Host ""
    Write-Host "   ✅ All indexes created in $([math]::Round($indexTime.TotalMinutes, 2)) minutes" -ForegroundColor Green
    
    # Run ANALYZE
    Write-Host "`n   Running ANALYZE..." -ForegroundColor Cyan
    sqlite3 $dbPath "ANALYZE;"
    Write-Host "   ✅ ANALYZE complete" -ForegroundColor Green
    
    # Check final size
    $dbSizeFinal = (Get-Item $dbPath).Length / 1GB
    Write-Host "`n6. Final database size:" -ForegroundColor Yellow
    Write-Host "   Size with indexes: $([math]::Round($dbSizeFinal, 2)) GB" -ForegroundColor Green
}

Write-Host "`n=== Complete ===" -ForegroundColor Green
Write-Host "✅ Database reduced to January data only" -ForegroundColor Green
Write-Host "✅ Ready to upload to S3" -ForegroundColor Green
Write-Host ""

