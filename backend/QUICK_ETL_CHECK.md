# Quick ETL Check & Run Instructions

## ✅ Status Check
- **S3 Bucket Variable**: ✅ Set correctly (`nyc-taxi-data-800155829166`)
- **SSH Issue**: `eb ssh --command` hangs (known issue)

## 🚀 Solution: Use Interactive SSH

### Step 1: Open Interactive SSH Session

**In a NEW terminal/PowerShell window**, run:
```powershell
cd D:\Syntasa\backend
eb ssh
```

This will open an interactive SSH session (don't use `--command` flag).

### Step 2: Once Connected, Run These Commands

Copy and paste this entire block into the SSH session:

```bash
# Navigate to app directory
cd /var/app/current

# Check if data files exist
echo "=== Checking Data Files ==="
ls -lh data/ 2>/dev/null || echo "Data directory missing"

# Download data files if missing
if [ ! -f "data/yellow_tripdata_2025-01.parquet" ]; then
    echo "Downloading data files from S3..."
    mkdir -p data
    aws s3 cp s3://nyc-taxi-data-800155829166/data/ ./data/ --recursive
    echo "Data files downloaded:"
    ls -lh data/
fi

# Check database
echo ""
echo "=== Checking Database ==="
if [ -f "nyc_taxi.db" ]; then
    DB_SIZE=$(du -h nyc_taxi.db | cut -f1)
    echo "Database exists: $DB_SIZE"
    
    # Check trip count
    source /var/app/venv/*/bin/activate
    export PYTHONPATH="/var/app/current:$PYTHONPATH"
    TRIP_COUNT=$(python -c "from app.database.connection import engine; import pandas as pd; result = pd.read_sql('SELECT COUNT(*) as count FROM trips', engine); print(result['count'].iloc[0])" 2>/dev/null)
    
    if [ -n "$TRIP_COUNT" ] && [ "$TRIP_COUNT" -gt 0 ]; then
        echo "✅ Database has $TRIP_COUNT trips - ETL already completed!"
    else
        echo "⚠️ Database exists but is empty. Running ETL..."
        python run_etl.py
    fi
else
    echo "Database not found. Running ETL to create it..."
    source /var/app/venv/*/bin/activate
    export PYTHONPATH="/var/app/current:$PYTHONPATH"
    python run_etl.py
fi
```

### Step 3: Wait for ETL to Complete

ETL takes **15-30 minutes** on t3.micro. You'll see progress messages like:
```
Starting ETL Pipeline...
1. Loading Taxi Zone Lookup Table...
[OK] Taxi zones loaded successfully
2. Loading Trip Data...
[OK] Trip data loaded successfully
ETL Pipeline Completed Successfully!
```

### Step 4: Test API (From Your Local Machine)

After ETL completes, test the API:

```powershell
# Test overview endpoint
curl http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com/api/v1/overview
```

If it returns data (not 500 error), you're done! ✅

## Alternative: Run ETL in Background

If you want to disconnect from SSH while ETL runs:

```bash
cd /var/app/current
source /var/app/venv/*/bin/activate
export PYTHONPATH="/var/app/current:$PYTHONPATH"
nohup python run_etl.py > etl.log 2>&1 &
tail -f etl.log
```

Press `Ctrl+C` to stop following the log, then `exit` to disconnect. ETL will continue running.

## Quick Status Check (Without Running ETL)

Just want to check status? Run this in SSH:

```bash
cd /var/app/current
echo "Data files:"
ls -lh data/*.parquet 2>/dev/null | wc -l
echo "Database:"
ls -lh nyc_taxi.db 2>/dev/null && du -h nyc_taxi.db | cut -f1
echo "Trip count:"
source /var/app/venv/*/bin/activate
export PYTHONPATH="/var/app/current:$PYTHONPATH"
python -c "from app.database.connection import engine; import pandas as pd; print('Trips:', pd.read_sql('SELECT COUNT(*) as count FROM trips', engine)['count'].iloc[0])" 2>&1
```



