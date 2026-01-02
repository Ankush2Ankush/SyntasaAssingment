# Reduce database to January data only, then create indexes
# This will significantly reduce database size and make indexing faster

Write-Host "`n=== Reducing Database to January Data Only ===" -ForegroundColor Cyan
Write-Host ""

# Check if database file exists
$dbPath = ".\nyc_taxi.db"
if (-not (Test-Path $dbPath)) {
    Write-Host "❌ Error: Database file not found at $dbPath" -ForegroundColor Red
    Write-Host "Please run this script from the backend directory where nyc_taxi.db is located" -ForegroundColor Yellow
    exit 1
}

# Get database size before
$dbSizeBefore = (Get-Item $dbPath).Length / 1GB
Write-Host "1. Current database status:" -ForegroundColor Yellow
Write-Host "   File: $dbPath" -ForegroundColor Gray
Write-Host "   Size: $([math]::Round($dbSizeBefore, 2)) GB" -ForegroundColor Gray

# Check current trip count
Write-Host "`n2. Checking current trip count..." -ForegroundColor Yellow
$tripCountBefore = sqlite3 $dbPath "SELECT COUNT(*) FROM trips;"
Write-Host "   Total trips: $tripCountBefore" -ForegroundColor Gray

# Check January trip count
$januaryCount = sqlite3 $dbPath "SELECT COUNT(*) FROM trips WHERE tpep_pickup_datetime >= '2025-01-01' AND tpep_pickup_datetime < '2025-02-01';"
Write-Host "   January trips: $januaryCount" -ForegroundColor Green
Write-Host "   Trips to delete: $($tripCountBefore - $januaryCount)" -ForegroundColor Yellow
Write-Host ""

# Confirm deletion
Write-Host "⚠️  WARNING: This will DELETE all trips outside January 2025!" -ForegroundColor Red
Write-Host "   This action cannot be undone!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "   Are you sure you want to proceed? (type 'yes' to continue)"
if ($confirm -ne 'yes') {
    Write-Host "   Operation cancelled." -ForegroundColor Yellow
    exit 0
}

# Check if sqlite3 is available
try {
    $null = sqlite3 --version
} catch {
    Write-Host "❌ Error: sqlite3 not found. Please install SQLite or add it to PATH" -ForegroundColor Red
    exit 1
}

# Delete non-January data
Write-Host "`n3. Deleting trips outside January 2025..." -ForegroundColor Yellow
Write-Host "   This may take 5-15 minutes..." -ForegroundColor Gray

$startTime = Get-Date
sqlite3 $dbPath "DELETE FROM trips WHERE tpep_pickup_datetime < '2025-01-01' OR tpep_pickup_datetime >= '2025-02-01';"
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Failed to delete trips" -ForegroundColor Red
    exit 1
}

$deleteTime = (Get-Date) - $startTime
Write-Host "   ✅ Deletion complete in $([math]::Round($deleteTime.TotalMinutes, 2)) minutes" -ForegroundColor Green

# Verify deletion
Write-Host "`n4. Verifying deletion..." -ForegroundColor Yellow
$tripCountAfter = sqlite3 $dbPath "SELECT COUNT(*) FROM trips;"
Write-Host "   Remaining trips: $tripCountAfter" -ForegroundColor Green

if ($tripCountAfter -ne $januaryCount) {
    Write-Host "   ⚠️  Warning: Trip count doesn't match expected January count" -ForegroundColor Yellow
}

# Vacuum to reclaim space
Write-Host "`n5. Running VACUUM to reclaim space..." -ForegroundColor Yellow
Write-Host "   This will take 5-10 minutes..." -ForegroundColor Gray

$vacuumStart = Get-Date
sqlite3 $dbPath "VACUUM;"
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ VACUUM failed" -ForegroundColor Red
    exit 1
}

$vacuumTime = (Get-Date) - $vacuumStart
Write-Host "   ✅ VACUUM complete in $([math]::Round($vacuumTime.TotalMinutes, 2)) minutes" -ForegroundColor Green

# Check database size after deletion and vacuum
$dbSizeAfter = (Get-Item $dbPath).Length / 1GB
$sizeReduction = $dbSizeBefore - $dbSizeAfter
Write-Host "`n6. Database size after reduction:" -ForegroundColor Yellow
Write-Host "   Size before: $([math]::Round($dbSizeBefore, 2)) GB" -ForegroundColor Gray
Write-Host "   Size after:  $([math]::Round($dbSizeAfter, 2)) GB" -ForegroundColor Green
Write-Host "   Reduction:   $([math]::Round($sizeReduction, 2)) GB" -ForegroundColor Green
Write-Host ""

# Ask to create indexes
Write-Host "7. Create indexes now?" -ForegroundColor Yellow
Write-Host "   This will add ~500MB-800MB but make queries 10-100x faster" -ForegroundColor Gray
$createIndexes = Read-Host "   Create indexes? (y/n)"
Write-Host ""

if ($createIndexes -eq 'y' -or $createIndexes -eq 'Y') {
    Write-Host "Creating indexes (this will take 5-10 minutes for January data)..." -ForegroundColor Cyan
    Write-Host ""
    
    $indexStart = Get-Date
    
    Write-Host "   Creating index 1/6: idx_pickup_datetime..." -ForegroundColor Cyan
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);"
    Write-Host "   ✅ Index 1/6 done" -ForegroundColor Green
    
    Write-Host "   Creating index 2/6: idx_dropoff_datetime..." -ForegroundColor Cyan
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);"
    Write-Host "   ✅ Index 2/6 done" -ForegroundColor Green
    
    Write-Host "   Creating index 3/6: idx_pulocationid..." -ForegroundColor Cyan
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);"
    Write-Host "   ✅ Index 3/6 done" -ForegroundColor Green
    
    Write-Host "   Creating index 4/6: idx_dolocationid..." -ForegroundColor Cyan
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);"
    Write-Host "   ✅ Index 4/6 done" -ForegroundColor Green
    
    Write-Host "   Creating index 5/6: idx_pickup_location_time..." -ForegroundColor Cyan
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);"
    Write-Host "   ✅ Index 5/6 done" -ForegroundColor Green
    
    Write-Host "   Creating index 6/6: idx_dropoff_location_time..." -ForegroundColor Cyan
    sqlite3 $dbPath "CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);"
    Write-Host "   ✅ Index 6/6 done" -ForegroundColor Green
    
    $indexTime = (Get-Date) - $indexStart
    Write-Host ""
    Write-Host "   ✅ All indexes created in $([math]::Round($indexTime.TotalMinutes, 2)) minutes" -ForegroundColor Green
    
    # Run ANALYZE
    Write-Host "`n   Running ANALYZE for query optimizer..." -ForegroundColor Cyan
    sqlite3 $dbPath "ANALYZE;"
    Write-Host "   ✅ ANALYZE complete" -ForegroundColor Green
    
    # Check final size
    $dbSizeFinal = (Get-Item $dbPath).Length / 1GB
    $indexOverhead = $dbSizeFinal - $dbSizeAfter
    Write-Host "`n8. Final database size:" -ForegroundColor Yellow
    Write-Host "   Size after deletion: $([math]::Round($dbSizeAfter, 2)) GB" -ForegroundColor Gray
    Write-Host "   Size with indexes:   $([math]::Round($dbSizeFinal, 2)) GB" -ForegroundColor Green
    Write-Host "   Index overhead:      $([math]::Round($indexOverhead, 2)) GB" -ForegroundColor Gray
    Write-Host ""
    
    # Verify indexes
    Write-Host "9. Verifying indexes..." -ForegroundColor Yellow
    $indexes = sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
    if ($indexes) {
        Write-Host "   ✅ Indexes created:" -ForegroundColor Green
        $indexes | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "Skipping index creation. You can create them later with:" -ForegroundColor Yellow
    Write-Host "  .\create_indexes_local_january.ps1" -ForegroundColor Gray
}

Write-Host "`n=== Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Database reduced to January data only" -ForegroundColor Green
Write-Host "✅ Trip count: $tripCountAfter (down from $tripCountBefore)" -ForegroundColor Green
if ($createIndexes -eq 'y' -or $createIndexes -eq 'Y') {
    Write-Host "✅ All 6 indexes created" -ForegroundColor Green
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Upload to S3 via AWS Console:" -ForegroundColor Yellow
Write-Host "   - Go to S3 → nyc-taxi-data-800155829166" -ForegroundColor White
Write-Host "   - Upload: $((Get-Item $dbPath).FullName)" -ForegroundColor White
Write-Host "   - Replace existing nyc_taxi.db" -ForegroundColor White
Write-Host ""
Write-Host "2. After upload, restore on EC2:" -ForegroundColor Yellow
Write-Host "   eb ssh" -ForegroundColor White
Write-Host "   sudo systemctl stop web.service" -ForegroundColor White
Write-Host "   cd /var/app/current" -ForegroundColor White
Write-Host "   sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db" -ForegroundColor White
Write-Host "   sudo chown webapp:webapp nyc_taxi.db" -ForegroundColor White
Write-Host "   sudo chmod 664 nyc_taxi.db" -ForegroundColor White
Write-Host "   sudo systemctl start web.service" -ForegroundColor White
Write-Host ""


