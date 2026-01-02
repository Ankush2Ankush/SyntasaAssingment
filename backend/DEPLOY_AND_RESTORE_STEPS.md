# Complete Deployment and Database Restoration Steps

## Overview

After updating the backend code to use January data only, you need to:
1. **Deploy the updated code** to EC2
2. **Restore the optimized database** from S3 (deployment resets the app directory)

## Step 1: Deploy Updated Code

```powershell
cd backend
eb deploy
```

**What this does:**
- Uploads all updated API files (with January date filters)
- Restarts the application
- Applies nginx timeout settings
- **WARNING**: Resets `/var/app/current` directory (database will be lost)

**Expected time:** 5-10 minutes

**Wait for:** Status to be "Ready" and Health "Green"

## Step 2: Verify Deployment

```powershell
eb status
```

Should show:
- Status: Ready
- Health: Green (or Yellow initially, will turn Green)

## Step 3: Restore Database from S3

After deployment completes, SSH into the server and restore the database:

```bash
# SSH into server
eb ssh

# Stop service
sudo systemctl stop web.service

# Download from S3
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db

# Set permissions
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db

# Verify database
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';"

# Start service
sudo systemctl start web.service
sleep 10

# Test endpoints
curl http://localhost:8000/health
time curl --max-time 60 http://localhost:8000/api/v1/overview | head -c 300
time curl --max-time 60 http://localhost:8000/api/v1/efficiency/timeseries | head -c 500
```

## Step 4: Test Public Endpoints

After restoration, test the public endpoint:

```
https://hellosyntasa.vercel.app/api/v1/efficiency/timeseries
```

**Expected:**
- Response time: 10-30 seconds (instead of timeout)
- Status: 200 OK
- Data: 744 data points (one per hour in January)

## Why Both Steps Are Needed

### Code Deployment (Step 1):
- Updates API endpoints to filter January only
- Applies nginx timeout settings
- Updates application logic

### Database Restoration (Step 2):
- Deployment resets the app directory
- Database file is lost during deployment
- Must restore from S3 after each deployment

## Quick Command Reference

**Deploy:**
```powershell
cd backend
eb deploy
```

**Restore Database (after deployment):**
```bash
eb ssh
sudo systemctl stop web.service
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
```

## Troubleshooting

### Deployment Stuck
- Check: `eb status`
- If stuck in "Updating", wait or use `eb abort` then retry

### Database Not Found After Deployment
- Normal! Deployment resets the directory
- Just restore from S3 (Step 3)

### Endpoints Still Timing Out
- Check if database was restored: `ls -lh /var/app/current/nyc_taxi.db`
- Check if indexes exist: `sqlite3 nyc_taxi.db ".indexes trips"`
- Check nginx timeout: `grep -i timeout /etc/nginx/nginx.conf`

## Summary

**Always do BOTH:**
1. ✅ Deploy code (`eb deploy`)
2. ✅ Restore database (download from S3)

The deployment updates the code, but resets the database. That's why we always restore from S3 after deployment.


