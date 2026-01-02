#!/bin/bash
# Script to diagnose and fix database issue
# Run this on the EC2 instance

cd /var/app/current

echo "=== Diagnosing Database Issue ==="
echo ""

# 1. Check data files
echo "1. Checking data files..."
if [ -d data ]; then
    echo "Data directory exists:"
    ls -lh data/
    echo ""
    echo "File count: $(find data -type f | wc -l)"
    echo ""
    
    # Check if parquet files exist
    PARQUET_COUNT=$(find data -name "*.parquet" | wc -l)
    CSV_COUNT=$(find data -name "*.csv" | wc -l)
    echo "Parquet files: $PARQUET_COUNT"
    echo "CSV files: $CSV_COUNT"
else
    echo "ERROR: Data directory not found!"
    exit 1
fi
echo ""

# 2. Check ETL log
echo "2. Checking ETL log..."
if [ -f etl.log ]; then
    echo "ETL log exists:"
    ls -lh etl.log
    echo ""
    echo "Last 50 lines:"
    tail -50 etl.log
else
    echo "ETL log not found - ETL may not have run"
fi
echo ""

# 3. Check if ETL is running
echo "3. Checking for running ETL process..."
ps aux | grep -E "run_etl|python.*etl" | grep -v grep || echo "No ETL process running"
echo ""

# 4. Check Python environment
echo "4. Checking Python environment..."
VENV_DIR=$(ls -d /var/app/venv/staging-* 2>/dev/null | head -1)
if [ -n "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/python" ]; then
    PYTHON="$VENV_DIR/bin/python"
    echo "Using Python from venv: $PYTHON"
else
    PYTHON=python3
    echo "Using system Python: $PYTHON"
fi
$PYTHON --version
echo ""

# 5. Check if run_etl.py exists
echo "5. Checking ETL script..."
if [ -f run_etl.py ]; then
    echo "run_etl.py exists"
    ls -lh run_etl.py
else
    echo "ERROR: run_etl.py not found!"
    exit 1
fi
echo ""

# 6. Check database current state
echo "6. Current database state:"
sqlite3 nyc_taxi.db '.tables'
echo ""
sqlite3 nyc_taxi.db "SELECT COUNT(*) as taxi_zones_count FROM taxi_zones;"
echo ""

# 7. Check if we can import required modules
echo "7. Testing Python imports..."
export PYTHONPATH="/var/app/current:$PYTHONPATH"
$PYTHON -c "import pandas; import sqlalchemy; print('Required modules available')" 2>&1
echo ""

echo "=== Diagnosis Complete ==="
echo ""
echo "To fix the issue, run the ETL manually:"
echo "  export PYTHONPATH=\"/var/app/current:\$PYTHONPATH\""
echo "  $PYTHON run_etl.py --data-dir ./data"
echo ""

