# SSH Issue & Environment Recovery Guide

## Current Situation

- **SSH Issue**: `eb ssh` command hangs (known issue with EB CLI)
- **Environment Health**: Severe
- **API Status**: 504 Gateway Timeout
- **Likely Cause**: ETL process may have overloaded t3.micro instance or crashed the application

## Solution: Use Alternative Access Methods

### Option 1: AWS Systems Manager Session Manager (Recommended)

1. **Go to AWS Console** → **EC2** → **Instances**
2. **Find your instance**: `i-00edfe73c878d3e9d`
3. **Select the instance** → Click **"Connect"**
4. **Choose "Session Manager"** tab
5. Click **"Connect"**

This will open a browser-based terminal - no SSH key needed!

### Option 2: EC2 Instance Connect

1. **Go to AWS Console** → **EC2** → **Instances**
2. **Select instance** → Click **"Connect"**
3. **Choose "EC2 Instance Connect"** tab
4. Click **"Connect"**

### Option 3: Direct SSH with Key

If you have the SSH key file:

```powershell
ssh -i C:\Users\ankush\.ssh\aws-eb ec2-user@44.220.90.84
```

## Once Connected - Check Status

```bash
# Check if ETL is still running
ps aux | grep -E "run_etl|python.*etl" | grep -v grep

# Check database status
cd /var/app/current
ls -lh nyc_taxi.db

# Check application status
ps aux | grep uvicorn

# Check system resources
df -h  # Disk space
free -h  # Memory
top -bn1 | head -20  # CPU/Memory usage
```

## Recovery Steps

### If ETL is Still Running

Let it complete. It takes 15-30 minutes. Monitor with:
```bash
watch -n 5 'ls -lh /var/app/current/nyc_taxi.db'
```

### If Application Crashed

Restart the application:
```bash
# Check if uvicorn is running
ps aux | grep uvicorn

# If not running, the Procfile should auto-restart it
# Or manually restart:
cd /var/app/current
source /var/app/venv/*/bin/activate
export PYTHONPATH="/var/app/current:$PYTHONPATH"
nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > app.log 2>&1 &
```

### If Instance is Overloaded

The t3.micro might be too small for ETL. Options:

1. **Wait for ETL to complete** (if still running)
2. **Restart environment** to free resources:
   ```powershell
   cd D:\Syntasa\backend
   eb restart
   ```
3. **Upgrade instance type** (if needed):
   - Go to AWS Console → Elastic Beanstalk → Configuration
   - Modify instance type to t3.small or t3.medium

## Check ETL Progress Without SSH

### Via CloudWatch Logs

1. Go to **AWS Console** → **CloudWatch** → **Log groups**
2. Find: `/aws/elasticbeanstalk/nyc-taxi-api-env/var/log/eb-engine.log`
3. Check recent logs for ETL progress

### Via EB Logs (Local)

```powershell
cd D:\Syntasa\backend
eb logs --all
```

Then check the downloaded logs for ETL messages.

## Quick Status Check Commands

Once you're connected via Session Manager or EC2 Instance Connect:

```bash
# Quick status check
cd /var/app/current && \
echo "=== Database ===" && \
ls -lh nyc_taxi.db && \
echo "" && \
echo "=== ETL Process ===" && \
ps aux | grep -E "run_etl|python.*etl" | grep -v grep && \
echo "" && \
echo "=== Application ===" && \
ps aux | grep uvicorn | grep -v grep && \
echo "" && \
echo "=== System Resources ===" && \
df -h / && \
free -h
```

## Next Steps

1. **Access instance** via AWS Console (Session Manager)
2. **Check ETL status** - is it still running or completed?
3. **Check database size** - has it grown from 0?
4. **Restart application** if needed
5. **Test API** once everything is stable

## If ETL Completed Successfully

After ETL completes, the database should be ~1.5-2 GB. Then:

1. Restart the environment to ensure app is running:
   ```powershell
   cd D:\Syntasa\backend
   eb restart
   ```

2. Wait 2-3 minutes for restart

3. Test API:
   ```powershell
   curl http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com/api/v1/overview
   ```

## Summary

- **Problem**: SSH hanging, environment health severe
- **Solution**: Use AWS Console → EC2 → Connect → Session Manager
- **Action**: Check ETL status, restart app if needed, verify database



