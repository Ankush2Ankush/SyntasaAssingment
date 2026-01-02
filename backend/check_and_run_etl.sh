#!/bin/bash
# Script to check data files and run ETL if needed
# Run this via: eb ssh, then execute this script

echo "=== Checking Data Files ==="
if [ -d "/var/app/current/data" ]; then
    echo "Data directory exists"
    ls -lh /var/app/current/data/
    FILE_COUNT=$(ls -1 /var/app/current/data/*.parquet 2>/dev/null | wc -l)
    echo "Parquet files found: $FILE_COUNT"
    if [ "$FILE_COUNT" -lt 4 ]; then
        echo "WARNING: Expected 4 parquet files, found $FILE_COUNT"
        echo "Downloading from S3..."
        cd /var/app/current
        mkdir -p data
        aws s3 cp s3://nyc-taxi-data-800155829166/data/ ./data/ --recursive
        ls -lh data/
    fi
else
    echo "Data directory does not exist. Creating and downloading..."
    mkdir -p /var/app/current/data
    cd /var/app/current
    aws s3 cp s3://nyc-taxi-data-800155829166/data/ ./data/ --recursive
fi

echo ""
echo "=== Checking Database ==="
if [ -f "/var/app/current/nyc_taxi.db" ]; then
    DB_SIZE=$(du -h /var/app/current/nyc_taxi.db | cut -f1)
    echo "Database exists: $DB_SIZE"
    
    # Check if database has data
    cd /var/app/current
    export PYTHONPATH="/var/app/current:$PYTHONPATH"
    VENV_DIR=$(ls -d /var/app/venv/staging-* 2>/dev/null | head -1)
    if [ -n "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/python" ]; then
        PYTHON="$VENV_DIR/bin/python"
    else
        PYTHON=python3
    fi
    
    TRIP_COUNT=$($PYTHON -c "from app.database.connection import engine; import pandas as pd; result = pd.read_sql('SELECT COUNT(*) as count FROM trips', engine); print(result['count'].iloc[0])" 2>/dev/null)
    
    if [ -n "$TRIP_COUNT" ] && [ "$TRIP_COUNT" -gt 0 ]; then
        echo "Database has $TRIP_COUNT trips. ETL already completed!"
    else
        echo "Database is empty. Running ETL..."
        cd /var/app/current
        export PYTHONPATH="/var/app/current:$PYTHONPATH"
        $PYTHON run_etl.py
    fi
else
    echo "Database does not exist. Running ETL will create it..."
    cd /var/app/current
    export PYTHONPATH="/var/app/current:$PYTHONPATH"
    VENV_DIR=$(ls -d /var/app/venv/staging-* 2>/dev/null | head -1)
    if [ -n "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/python" ]; then
        PYTHON="$VENV_DIR/bin/python"
    else
        PYTHON=python3
    fi
    echo "Running ETL with $PYTHON..."
    $PYTHON run_etl.py
fi

echo ""
echo "=== Final Status ==="
if [ -f "/var/app/current/nyc_taxi.db" ]; then
    DB_SIZE=$(du -h /var/app/current/nyc_taxi.db | cut -f1)
    echo "Database size: $DB_SIZE"
fi


