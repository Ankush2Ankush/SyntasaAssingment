# Test All API Endpoints from Local Machine
# Run this in PowerShell

$baseUrl = "http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com"

Write-Host "=== Testing All API Endpoints ===" -ForegroundColor Cyan
Write-Host "Base URL: $baseUrl" -ForegroundColor Yellow
Write-Host ""

# Test Overview
Write-Host "1. Testing /api/v1/overview" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/overview" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 2 | Select-Object -First 5
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Zones
Write-Host "2. Testing /api/v1/zones/revenue" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/zones/revenue?limit=5" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
    Write-Host "Returned $($response.data.Count) zones"
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "3. Testing /api/v1/zones/net-profit" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/zones/net-profit?idle_cost_per_hour=30" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Efficiency
Write-Host "4. Testing /api/v1/efficiency/timeseries" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/efficiency/timeseries" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "5. Testing /api/v1/efficiency/heatmap" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/efficiency/heatmap" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Surge
Write-Host "6. Testing /api/v1/surge/events" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/surge/events?threshold=0.2" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "7. Testing /api/v1/surge/analysis" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/surge/analysis" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Wait Time
Write-Host "8. Testing /api/v1/wait-time/current" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/wait-time/current" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "9. Testing /api/v1/wait-time/reduction" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/wait-time/reduction" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Congestion
Write-Host "10. Testing /api/v1/congestion/zones" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/congestion/zones" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "11. Testing /api/v1/congestion/throughput" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/congestion/throughput" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Incentives
Write-Host "12. Testing /api/v1/incentives/drivers" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/incentives/drivers" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "13. Testing /api/v1/incentives/efficiency" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/incentives/efficiency" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "14. Testing /api/v1/incentives/misalignment" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/incentives/misalignment" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Variability
Write-Host "15. Testing /api/v1/variability/heatmap" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/variability/heatmap" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Simulation
Write-Host "16. Testing /api/v1/simulation/min-distance" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/v1/simulation/min-distance?threshold=1.0" -Method Get
    Write-Host "✅ Success" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test Health
Write-Host "17. Testing /health" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "✅ Success: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "18. Testing /api/health" -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/health" -Method Get
    Write-Host "✅ Success: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== All Tests Complete ===" -ForegroundColor Cyan

