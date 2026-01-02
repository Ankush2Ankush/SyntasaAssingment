# Test database and API endpoints (local and public)

Write-Host "`n=== Testing Database and API Endpoints ===" -ForegroundColor Cyan
Write-Host ""

# Check if database exists
$dbPath = ".\nyc_taxi.db"
if (-not (Test-Path $dbPath)) {
    Write-Host "❌ Error: Database file not found at $dbPath" -ForegroundColor Red
    exit 1
}

# Database Status
Write-Host "1. Database Status" -ForegroundColor Yellow
Write-Host "   File: $dbPath" -ForegroundColor Gray
$dbSize = (Get-Item $dbPath).Length / 1GB
Write-Host "   Size: $([math]::Round($dbSize, 2)) GB" -ForegroundColor Gray
Write-Host ""

# Check trip count
Write-Host "2. Checking trip count..." -ForegroundColor Yellow
$tripCount = sqlite3 $dbPath "SELECT COUNT(*) FROM trips;"
Write-Host "   Total trips: $tripCount" -ForegroundColor Green

# Check January trips
$januaryCount = sqlite3 $dbPath "SELECT COUNT(*) FROM trips WHERE tpep_pickup_datetime >= '2025-01-01' AND tpep_pickup_datetime < '2025-02-01';"
Write-Host "   January trips: $januaryCount" -ForegroundColor Green

# Check non-January trips (should be 0 if reduced)
$nonJanuaryCount = sqlite3 $dbPath "SELECT COUNT(*) FROM trips WHERE tpep_pickup_datetime < '2025-01-01' OR tpep_pickup_datetime >= '2025-02-01';"
if ($nonJanuaryCount -eq 0) {
    Write-Host "   ✅ Database contains only January data" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Non-January trips found: $nonJanuaryCount" -ForegroundColor Yellow
}
Write-Host ""

# Check indexes
Write-Host "3. Checking indexes..." -ForegroundColor Yellow
$indexes = sqlite3 $dbPath "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
if ($indexes) {
    $indexCount = ($indexes -split "`n" | Where-Object { $_ -ne "" }).Count
    Write-Host "   ✅ Found $indexCount indexes:" -ForegroundColor Green
    $indexes -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object { Write-Host "      - $_" -ForegroundColor Gray }
} else {
    Write-Host "   ⚠️  No indexes found" -ForegroundColor Yellow
}
Write-Host ""

# Test local API server
Write-Host "4. Testing Local API Server" -ForegroundColor Yellow
Write-Host "   Checking if server is running on http://localhost:8000..." -ForegroundColor Gray

$serverRunning = $false
$overviewResponse = $null
$efficiencyResponse = $null

try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "   ✅ Server is running" -ForegroundColor Green
        Write-Host "   Health check: $($healthResponse.Content)" -ForegroundColor Gray
        $serverRunning = $true
    }
} catch {
    Write-Host "   ❌ Server is not running or not accessible" -ForegroundColor Red
    Write-Host "   Start the server with: uvicorn app.main:app --host 0.0.0.0 --port 8000" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Skipping local API tests..." -ForegroundColor Yellow
}

if ($serverRunning) {
    Write-Host ""
    Write-Host "   Testing Overview endpoint..." -ForegroundColor Cyan
    try {
        $overviewStart = Get-Date
        $overviewResponse = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/overview" -TimeoutSec 300 -UseBasicParsing -ErrorAction Stop
        $overviewTime = ((Get-Date) - $overviewStart).TotalSeconds
        if ($overviewResponse.StatusCode -eq 200) {
            $overviewData = $overviewResponse.Content | ConvertFrom-Json
            Write-Host "   ✅ Overview endpoint working" -ForegroundColor Green
            Write-Host "   Response time: $([math]::Round($overviewTime, 2)) seconds" -ForegroundColor Gray
            Write-Host "   Total trips: $($overviewData.data.total_trips)" -ForegroundColor Gray
            Write-Host "   Date range: $($overviewData.data.start_date) to $($overviewData.data.end_date)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   ❌ Overview endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "   Testing Efficiency Timeseries endpoint..." -ForegroundColor Cyan
    try {
        $efficiencyStart = Get-Date
        $efficiencyResponse = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/efficiency/timeseries" -TimeoutSec 300 -UseBasicParsing -ErrorAction Stop
        $efficiencyTime = ((Get-Date) - $efficiencyStart).TotalSeconds
        if ($efficiencyResponse.StatusCode -eq 200) {
            $efficiencyData = $efficiencyResponse.Content | ConvertFrom-Json
            $dataPoints = ($efficiencyData.data | Measure-Object).Count
            Write-Host "   ✅ Efficiency Timeseries endpoint working" -ForegroundColor Green
            Write-Host "   Response time: $([math]::Round($efficiencyTime, 2)) seconds" -ForegroundColor Gray
            Write-Host "   Data points returned: $dataPoints" -ForegroundColor Gray
            if ($efficiencyTime -lt 30) {
                Write-Host "   ✅ Performance: Excellent (< 30 seconds)" -ForegroundColor Green
            } elseif ($efficiencyTime -lt 60) {
                Write-Host "   ⚠️  Performance: Good (30-60 seconds)" -ForegroundColor Yellow
            } else {
                Write-Host "   ⚠️  Performance: Slow (> 60 seconds) - indexes may help" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "   ❌ Efficiency Timeseries endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Message -like "*timeout*") {
            Write-Host "   ⚠️  Request timed out - indexes may be needed" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host ""
    Write-Host "   Skipping local API tests (server not running)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "5. Testing Public Vercel Endpoint" -ForegroundColor Yellow
Write-Host "   Testing: https://hellosyntasa.vercel.app/api/v1/efficiency/timeseries" -ForegroundColor Gray
Write-Host ""

$vercelResponse = $null
try {
    $vercelStart = Get-Date
    $vercelResponse = Invoke-WebRequest -Uri "https://hellosyntasa.vercel.app/api/v1/efficiency/timeseries" -TimeoutSec 300 -UseBasicParsing -ErrorAction Stop
    $vercelTime = ((Get-Date) - $vercelStart).TotalSeconds
    
    if ($vercelResponse.StatusCode -eq 200) {
        $vercelData = $vercelResponse.Content | ConvertFrom-Json
        $dataPoints = ($vercelData.data | Measure-Object).Count
        Write-Host "   ✅ Public endpoint working" -ForegroundColor Green
        Write-Host "   Status: $($vercelResponse.StatusCode)" -ForegroundColor Gray
        Write-Host "   Response time: $([math]::Round($vercelTime, 2)) seconds" -ForegroundColor Gray
        Write-Host "   Data points returned: $dataPoints" -ForegroundColor Gray
        
        if ($vercelTime -lt 30) {
            Write-Host "   ✅ Performance: Excellent" -ForegroundColor Green
        } elseif ($vercelTime -lt 60) {
            Write-Host "   ⚠️  Performance: Good" -ForegroundColor Yellow
        } else {
            Write-Host "   ⚠️  Performance: Slow - may need optimization" -ForegroundColor Yellow
        }
        
        # Show sample data
        if ($vercelData.data.Count -gt 0) {
            Write-Host ""
            Write-Host "   Sample data (first 3 records):" -ForegroundColor Cyan
            $vercelData.data | Select-Object -First 3 | ForEach-Object {
                Write-Host "      Hour: $($_.hour), Trips: $($_.total_trips), Revenue: $([math]::Round($_.total_revenue, 2))" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "   ❌ Public endpoint failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   Status Code: $statusCode" -ForegroundColor Yellow
        
        if ($statusCode -eq 504) {
            Write-Host "   ⚠️  Gateway Timeout - Backend query is taking too long" -ForegroundColor Yellow
            Write-Host "   Solution: Create indexes on the database" -ForegroundColor Yellow
        } elseif ($statusCode -eq 502) {
            Write-Host "   ⚠️  Bad Gateway - Backend server may be down or unreachable" -ForegroundColor Yellow
        } elseif ($statusCode -eq 500) {
            Write-Host "   ⚠️  Internal Server Error - Check backend logs" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host ""

# Summary
Write-Host "Database:" -ForegroundColor Yellow
Write-Host "  - Size: $([math]::Round($dbSize, 2)) GB" -ForegroundColor White
Write-Host "  - Trips: $tripCount" -ForegroundColor White
Write-Host "  - January only: $(if ($nonJanuaryCount -eq 0) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host "  - Indexes: $(if ($indexes) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host ""

if ($serverRunning) {
    Write-Host "Local API:" -ForegroundColor Yellow
    Write-Host "  - Server: Running" -ForegroundColor Green
    Write-Host "  - Overview: $(if ($overviewResponse.StatusCode -eq 200) { 'Working' } else { 'Failed' })" -ForegroundColor $(if ($overviewResponse.StatusCode -eq 200) { 'Green' } else { 'Red' })
    Write-Host "  - Efficiency: $(if ($efficiencyResponse.StatusCode -eq 200) { 'Working' } else { 'Failed' })" -ForegroundColor $(if ($efficiencyResponse.StatusCode -eq 200) { 'Green' } else { 'Red' })
    Write-Host ""
}

Write-Host "Public API:" -ForegroundColor Yellow
Write-Host "  - Efficiency Timeseries: $(if ($vercelResponse.StatusCode -eq 200) { 'Working' } else { 'Failed' })" -ForegroundColor $(if ($vercelResponse.StatusCode -eq 200) { 'Green' } else { 'Red' })
Write-Host ""

Write-Host "=== Complete ===" -ForegroundColor Green
Write-Host ""

