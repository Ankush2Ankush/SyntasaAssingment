# Start local FastAPI server
# This script activates the virtual environment and starts the server

Write-Host "`n=== Starting FastAPI Server ===" -ForegroundColor Cyan
Write-Host ""

# Check for virtual environment
$venvPath = ".\venv\Scripts\Activate.ps1"
if (-not (Test-Path $venvPath)) {
    $venvPath = ".\.venv\Scripts\Activate.ps1"
}

if (-not (Test-Path $venvPath)) {
    Write-Host "❌ Virtual environment not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create virtual environment" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Virtual environment created" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    & .\venv\Scripts\Activate.ps1
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    & $venvPath
    Write-Host "✅ Virtual environment activated" -ForegroundColor Green
    Write-Host ""
}

# Check if uvicorn is installed
Write-Host "Checking for uvicorn..." -ForegroundColor Yellow
$uvicornCheck = python -c "import uvicorn" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing uvicorn..." -ForegroundColor Yellow
    pip install uvicorn
    Write-Host "✅ Uvicorn installed" -ForegroundColor Green
    Write-Host ""
}

# Start server
Write-Host "Starting FastAPI server..." -ForegroundColor Cyan
Write-Host "Server will be available at: http://localhost:8000" -ForegroundColor Green
Write-Host "API docs at: http://localhost:8000/docs" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload


