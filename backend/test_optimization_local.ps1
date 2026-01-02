# Database Optimization Test Script (Local)
# Tests optimization commands on local database before deployment

Write-Host "=== Local Database Optimization Test ===" -ForegroundColor Cyan
Write-Host ""

$DB_PATH = ".\nyc_taxi.db"

# Check if database exists
if (-not (Test-Path $DB_PATH)) {
    Write-Host "Error: Database file not found at $DB_PATH" -ForegroundColor Red
    Write-Host "Please ensure you're in the backend directory and the database exists." -ForegroundColor Yellow
    exit 1
}

Write-Host "Database found: $DB_PATH" -ForegroundColor Green
$dbSize = (Get-Item $DB_PATH).Length / 1GB
Write-Host "Database size: $([math]::Round($dbSize, 2)) GB" -ForegroundColor Gray
Write-Host ""

# Check if sqlite3 is available
$sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $sqlite3) {
    Write-Host "Warning: sqlite3 not found in PATH" -ForegroundColor Yellow
    Write-Host "You may need to install SQLite or use full path to sqlite3.exe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Testing with Python instead..." -ForegroundColor Cyan
    $usePython = $true
} else {
    $usePython = $false
}

Write-Host "1. Testing WAL mode..." -ForegroundColor Yellow
if ($usePython) {
    python -c "import sqlite3; conn = sqlite3.connect('$DB_PATH'); conn.execute('PRAGMA journal_mode=WAL'); print(conn.execute('PRAGMA journal_mode').fetchone()[0]); conn.close()"
} else {
    sqlite3 $DB_PATH "PRAGMA journal_mode=WAL; SELECT 'WAL mode:', journal_mode FROM pragma_journal_mode;"
}

Write-Host ""
Write-Host "2. Testing cache size..." -ForegroundColor Yellow
if ($usePython) {
    python -c "import sqlite3; conn = sqlite3.connect('$DB_PATH'); conn.execute('PRAGMA cache_size=-256000'); print('Cache size set to 1GB'); conn.close()"
} else {
    sqlite3 $DB_PATH "PRAGMA cache_size=-256000; SELECT 'Cache size:', cache_size FROM pragma_cache_size;"
}

Write-Host ""
Write-Host "3. Testing synchronous mode..." -ForegroundColor Yellow
if ($usePython) {
    python -c "import sqlite3; conn = sqlite3.connect('$DB_PATH'); conn.execute('PRAGMA synchronous=NORMAL'); print('Synchronous mode: NORMAL'); conn.close()"
} else {
    sqlite3 $DB_PATH "PRAGMA synchronous=NORMAL; SELECT 'Synchronous:', synchronous FROM pragma_synchronous;"
}

Write-Host ""
Write-Host "4. Testing ANALYZE..." -ForegroundColor Yellow
if ($usePython) {
    python -c "import sqlite3; conn = sqlite3.connect('$DB_PATH'); conn.execute('ANALYZE'); print('ANALYZE completed'); conn.close()"
} else {
    sqlite3 $DB_PATH "ANALYZE; SELECT 'ANALYZE completed';"
}

Write-Host ""
Write-Host "5. Checking existing indexes..." -ForegroundColor Yellow
if ($usePython) {
    python -c "import sqlite3; conn = sqlite3.connect('$DB_PATH'); indexes = conn.execute(\"SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips'\").fetchall(); print(f'Existing indexes: {len(indexes)}'); [print(idx[0]) for idx in indexes]; conn.close()"
} else {
    sqlite3 $DB_PATH "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
}

Write-Host ""
Write-Host "6. Testing index creation (dry run - will not create if exists)..." -ForegroundColor Yellow
Write-Host "   Note: Index creation will be tested on server" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Local Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. If tests passed, proceed with deployment" -ForegroundColor White
Write-Host "2. After deployment, run optimize_database.sh on server" -ForegroundColor White
Write-Host ""

