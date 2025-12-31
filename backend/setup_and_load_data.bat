@echo off
REM Setup script for Windows to create database and load data

echo ========================================
echo NYC TLC Analytics - Data Loading Script
echo ========================================
echo.

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo.
echo Installing dependencies...
pip install -r requirements.txt

REM Check database connection
echo.
echo Checking database connection...
python check_database.py
if errorlevel 1 (
    echo.
    echo ERROR: Database connection failed!
    echo Please ensure:
    echo 1. PostgreSQL is installed and running
    echo 2. Database 'nyc_taxi_db' exists
    echo 3. .env file has correct DATABASE_URL
    echo.
    pause
    exit /b 1
)

REM Create tables if they don't exist
echo.
echo Creating database tables...
python -c "from app.database.connection import engine, Base; Base.metadata.create_all(bind=engine); print('Tables created successfully')"

REM Load taxi zones
echo.
echo Loading taxi zone lookup table...
python -c "from app.pipelines.etl import load_taxi_zones; load_taxi_zones()"

REM Load trip data
echo.
echo Loading trip data (this may take 10-30 minutes)...
python run_etl.py

echo.
echo ========================================
echo Data loading completed!
echo ========================================
pause

