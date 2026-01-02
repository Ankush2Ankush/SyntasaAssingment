# Quick Database Update Guide

## Current Situation
- Environment rolled back to previous version: `app-260102_181948875867`
- New database already uploaded to S3: `s3://nyc-taxi-data-800155829166/nyc_taxi.db`
- Need to download and update database on EC2 instance

## Step 1: Wait for Environment to be Ready

Check status:
```bash
eb status
```

Wait until you see:
```
Status: Ready
Health: Green (or Yellow is OK)
```

## Step 2: SSH into the Instance

```bash
eb ssh
```

## Step 3: Update the Database

### Option A: Run the Automated Script

1. Create the script file:
```bash
nano update_database.sh
```

2. Paste the entire contents of `update_database.sh` (from your local backend folder)

3. Save and exit:
   - Press `Ctrl+X`
   - Press `Y` to confirm
   - Press `Enter`

4. Make it executable:
```bash
chmod +x update_database.sh
```

5. Run it:
```bash
./update_database.sh
```

### Option B: Run Commands Manually

Copy and paste these commands one by one:

```bash
# Stop the web service
sudo systemctl stop web.service
sleep 2

# Navigate to application directory
cd /var/app/current

# Backup existing database (optional)
if [ -f "nyc_taxi.db" ]; then
    sudo cp nyc_taxi.db nyc_taxi.db.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backup created"
fi

# Download new database from S3
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db

# Set proper permissions
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db

# Verify database
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';"

# Start the web service
sudo systemctl start web.service
sleep 5

# Check service status
sudo systemctl status web.service --no-pager | head -10

# Test health endpoint
curl http://localhost:8000/health
```

## Step 4: Verify Everything Works

### Test Local Endpoint
```bash
curl http://localhost:8000/health
curl http://localhost:8000/api/v1/overview | head -c 200
```

### Test Public Endpoint
From your local machine:
```bash
curl "https://hellosyntasa.vercel.app/api/v1/efficiency/timeseries"
```

## Troubleshooting

### If Service Won't Start
```bash
# Check service logs
sudo journalctl -u web.service -n 50

# Check for errors
sudo journalctl -u web.service -n 50 | grep -i error
```

### If Database Download Fails
```bash
# Check S3 access
aws s3 ls s3://nyc-taxi-data-800155829166/

# Check disk space
df -h

# Check if file exists in S3
aws s3 ls s3://nyc-taxi-data-800155829166/nyc_taxi.db
```

### If Health Check Fails
```bash
# Check if service is running
sudo systemctl status web.service

# Check if port is listening
sudo netstat -tlnp | grep 8000

# Check application logs
tail -f /var/log/eb-engine.log
```

## Quick Commands Reference

```bash
# Check environment status
eb status

# SSH into instance
eb ssh

# Stop service
sudo systemctl stop web.service

# Download database
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db

# Set permissions
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db

# Start service
sudo systemctl start web.service

# Test
curl http://localhost:8000/health
```

## Expected Results

After successful update:
- ✅ Service status: `active (running)`
- ✅ Health endpoint: `{"status":"healthy"}` or similar
- ✅ Database has January data (check trip count)
- ✅ Indexes are present (should show 6+ indexes)
- ✅ Public API endpoint responds without timeout

