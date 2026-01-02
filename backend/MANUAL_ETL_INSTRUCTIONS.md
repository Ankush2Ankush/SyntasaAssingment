# Manual ETL Instructions

Since `eb ssh --command` can hang, use these alternative methods:

## Method 1: Interactive SSH (Recommended)

1. **Open a new terminal/PowerShell window**

2. **SSH into the instance:**
   ```powershell
   cd D:\Syntasa\backend
   eb ssh
   ```
   This will open an interactive SSH session.

3. **Once connected, run these commands one by one:**

   ```bash
   # Check data files
   ls -lh /var/app/current/data/
   
   # If data files are missing, download them:
   cd /var/app/current
   mkdir -p data
   aws s3 cp s3://nyc-taxi-data-800155829166/data/ ./data/ --recursive
   ls -lh data/
   
   # Check database
   ls -lh /var/app/current/nyc_taxi.db
   
   # Check if database has data
   cd /var/app/current
   source /var/app/venv/*/bin/activate
   export PYTHONPATH="/var/app/current:$PYTHONPATH"
   python -c "from app.database.connection import engine; import pandas as pd; result = pd.read_sql('SELECT COUNT(*) as count FROM trips', engine); print('Trip count:', result['count'].iloc[0])"
   
   # If database is empty or doesn't exist, run ETL:
   python run_etl.py
   ```

4. **Exit SSH when done:**
   ```bash
   exit
   ```

## Method 2: Use the Check Script

1. **Copy the script to the server:**
   ```powershell
   cd D:\Syntasa\backend
   eb ssh
   ```

2. **Create the script on the server:**
   ```bash
   cat > /tmp/check_etl.sh << 'EOF'
   #!/bin/bash
   echo "=== Checking Data Files ==="
   ls -lh /var/app/current/data/ 2>/dev/null || echo "Data directory not found"
   
   echo ""
   echo "=== Checking Database ==="
   ls -lh /var/app/current/nyc_taxi.db 2>/dev/null || echo "Database not found"
   
   echo ""
   echo "=== Checking Trip Count ==="
   cd /var/app/current
   source /var/app/venv/*/bin/activate
   export PYTHONPATH="/var/app/current:$PYTHONPATH"
   python -c "from app.database.connection import engine; import pandas as pd; result = pd.read_sql('SELECT COUNT(*) as count FROM trips', engine); print('Trips:', result['count'].iloc[0])" 2>&1
   EOF
   
   chmod +x /tmp/check_etl.sh
   /tmp/check_etl.sh
   ```

## Method 3: Quick Commands (Copy-Paste)

Once you're in SSH (`eb ssh`), copy and paste this entire block:

```bash
cd /var/app/current && \
mkdir -p data && \
echo "=== Downloading data files ===" && \
aws s3 cp s3://nyc-taxi-data-800155829166/data/ ./data/ --recursive && \
ls -lh data/ && \
echo "" && \
echo "=== Running ETL ===" && \
source /var/app/venv/*/bin/activate && \
export PYTHONPATH="/var/app/current:$PYTHONPATH" && \
python run_etl.py
```

## Method 4: Check via API (After ETL)

Once ETL completes, test the API:

```powershell
# From your local machine
curl http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com/api/v1/overview
```

If it returns data (not 500 error), ETL was successful!

## Expected Output

### Data Files Should Show:
```
-rw-r--r-- 1 root root  59M Jan  1 10:00 yellow_tripdata_2025-01.parquet
-rw-r--r-- 1 root root  60M Jan  1 10:00 yellow_tripdata_2025-02.parquet
-rw-r--r-- 1 root root  70M Jan  1 10:00 yellow_tripdata_2025-03.parquet
-rw-r--r-- 1 root root  67M Jan  1 10:00 yellow_tripdata_2025-04.parquet
-rw-r--r-- 1 root root  12K Jan  1 10:00 taxi_zone_lookup.csv
```

### Database Should Show:
```
-rw-r--r-- 1 webapp webapp 1.5G Jan  1 10:30 nyc_taxi.db
```

### Trip Count Should Show:
```
Trips: 2000000+
```

## Troubleshooting

### If SSH hangs:
- Try closing and reopening the terminal
- Use AWS Console → EC2 → Connect via Session Manager (if enabled)
- Use AWS Console → EC2 → Connect via SSH directly with key pair

### If data download fails:
- Check S3 permissions: `aws iam list-attached-role-policies --role-name aws-elasticbeanstalk-ec2-role`
- Verify bucket exists: `aws s3 ls s3://nyc-taxi-data-800155829166/data/`

### If ETL fails:
- Check disk space: `df -h`
- Check Python path: `which python`
- Check logs: `tail -f /var/log/eb-engine.log`



