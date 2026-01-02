#!/bin/bash
# Script to check server status on EC2 instance
# Run this after SSH'ing into the instance

echo "=== Server Status Check ==="
echo ""

# 1. Check current directory
echo "1. Current Directory:"
pwd
echo ""

# 2. Check application directory
echo "2. Application Directory Contents:"
cd /var/app/current 2>/dev/null || echo "Directory not found"
ls -lh /var/app/current/ | head -20
echo ""

# 3. Check database file
echo "3. Database File Status:"
if [ -f /var/app/current/nyc_taxi.db ]; then
    echo "Database file exists:"
    ls -lh /var/app/current/nyc_taxi.db
    echo ""
    echo "Database tables:"
    sqlite3 /var/app/current/nyc_taxi.db ".tables" 2>/dev/null || echo "Error reading database"
    echo ""
    echo "Row counts:"
    sqlite3 /var/app/current/nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='table';" 2>/dev/null | while read table; do
        if [ -n "$table" ]; then
            count=$(sqlite3 /var/app/current/nyc_taxi.db "SELECT COUNT(*) FROM $table;" 2>/dev/null)
            echo "  $table: $count rows"
        fi
    done
else
    echo "Database file NOT found!"
fi
echo ""

# 4. Check data files
echo "4. Data Files Status:"
if [ -d /var/app/current/data ]; then
    echo "Data directory exists:"
    ls -lh /var/app/current/data/
    echo ""
    echo "File count:"
    find /var/app/current/data -type f | wc -l
else
    echo "Data directory NOT found!"
fi
echo ""

# 5. Check ETL log
echo "5. ETL Log Status:"
if [ -f /var/app/current/etl.log ]; then
    echo "ETL log exists:"
    ls -lh /var/app/current/etl.log
    echo ""
    echo "Last 20 lines of ETL log:"
    tail -20 /var/app/current/etl.log
else
    echo "ETL log NOT found (ETL may not have run)"
fi
echo ""

# 6. Check if ETL process is running
echo "6. ETL Process Status:"
ps aux | grep -E "run_etl|python.*etl" | grep -v grep || echo "No ETL process running"
echo ""

# 7. Check application process
echo "7. Application Process Status:"
ps aux | grep -E "uvicorn|python.*main" | grep -v grep || echo "No application process found"
echo ""

# 8. Check Python version and packages
echo "8. Python Environment:"
VENV_DIR=$(ls -d /var/app/venv/staging-* 2>/dev/null | head -1)
if [ -n "$VENV_DIR" ]; then
    echo "Virtual environment: $VENV_DIR"
    $VENV_DIR/bin/python --version 2>/dev/null || python3 --version
else
    python3 --version
fi
echo ""

# 9. Check disk space
echo "9. Disk Space:"
df -h /var/app/current
echo ""

# 10. Check recent logs
echo "10. Recent Application Logs (last 10 lines):"
tail -10 /var/log/web.stdout.log 2>/dev/null || echo "Log file not found"
echo ""

echo "=== Status Check Complete ==="

