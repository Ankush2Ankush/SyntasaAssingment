# Alternative SSH Access Methods

Since `eb ssh` is hanging, use these methods:

## Method 1: AWS Systems Manager Session Manager ⭐ (Easiest)

**No SSH key needed!**

1. Open **AWS Console** → **EC2** → **Instances**
2. Find instance: `i-00edfe73c878d3e9d`
3. Select it → Click **"Connect"** button
4. Choose **"Session Manager"** tab
5. Click **"Connect"**

Opens a browser-based terminal!

## Method 2: EC2 Instance Connect

1. AWS Console → EC2 → Instances
2. Select instance → **"Connect"**
3. Choose **"EC2 Instance Connect"** tab
4. Click **"Connect"**

## Method 3: Direct SSH (If Key Available)

```powershell
ssh -i C:\Users\ankush\.ssh\aws-eb ec2-user@44.220.90.84
```

## Once Connected - Run These Commands

```bash
cd /var/app/current

# Check ETL status
ps aux | grep -E "run_etl|python.*etl" | grep -v grep

# Check database
ls -lh nyc_taxi.db

# Check application
ps aux | grep uvicorn | grep -v grep

# Check system resources
df -h
free -h
```

## If ETL Needs to Continue

```bash
cd /var/app/current
source /var/app/venv/*/bin/activate
export PYTHONPATH="/var/app/current:$PYTHONPATH"
nohup python -c "from app.pipelines.etl import load_parquet_to_sql; load_parquet_to_sql('./data')" > etl.log 2>&1 &
tail -f etl.log
```

## If Application Needs Restart

```bash
# Check if running
ps aux | grep uvicorn

# If not, restart manually
cd /var/app/current
source /var/app/venv/*/bin/activate
export PYTHONPATH="/var/app/current:$PYTHONPATH"
nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > app.log 2>&1 &
```


