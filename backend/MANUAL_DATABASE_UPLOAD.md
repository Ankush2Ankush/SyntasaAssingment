# Manual Database Upload Alternative

Since SSH is unreliable, here's an alternative approach:

## Option 1: Run ETL Locally and Upload Database (Not Recommended)

**Why not recommended:**
- Database file is ~1.5-2 GB (too large for easy upload)
- Requires local machine with all data files
- Slow upload process

**If you still want to try:**

1. **Run ETL locally:**
   ```powershell
   cd D:\Syntasa\backend
   python -m venv venv
   .\venv\Scripts\activate
   pip install -r requirements.txt
   python run_etl.py
   ```

2. **Upload database to S3:**
   ```powershell
   aws s3 cp nyc_taxi.db s3://nyc-taxi-data-800155829166/database/nyc_taxi.db
   ```

3. **Download on server** (via deployment hook or manual)

## Option 2: Use AWS Systems Manager Run Command (Better)

Run ETL remotely without SSH:

```powershell
# Install SSM plugin if needed
aws ssm send-command `
  --instance-ids "i-00edfe73c878d3e9d" `
  --document-name "AWS-RunShellScript" `
  --parameters "commands=[
    'cd /var/app/current',
    'source /var/app/venv/*/bin/activate',
    'export PYTHONPATH=\"/var/app/current:$PYTHONPATH\"',
    'python -c \"from app.pipelines.etl import load_taxi_zones, load_parquet_to_sql; load_taxi_zones(\"./data\"); load_parquet_to_sql(\"./data\")\"'
  ]"
```

## Option 3: Fix Deployment Hook (Best Solution) ✅

The deployment hook is already configured. Just redeploy and it will run automatically:

```powershell
cd D:\Syntasa\backend
eb deploy
```

The ETL will run automatically in the background after deployment.

## Option 4: Use AWS Console - EC2 Run Command

1. Go to **AWS Console** → **EC2** → **Instances**
2. Select instance `i-00edfe73c878d3e9d`
3. Click **"Actions"** → **"Monitor and troubleshoot"** → **"EC2 Instance Connect"** or **"Session Manager"**
4. Or use **"Actions"** → **"Monitor and troubleshoot"** → **"Run command"**

## Recommended: Fix and Redeploy

The best solution is to fix the ETL hook (which I just did) and redeploy. The ETL will run automatically without needing SSH.


