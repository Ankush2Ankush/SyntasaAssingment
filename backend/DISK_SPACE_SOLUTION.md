# Disk Space Full - Solution Guide

## Problem
Error: `database or disk is full (13)` when creating indexes.

This means the EC2 instance has run out of disk space.

## Quick Diagnosis

Run these commands in SSH:

```bash
# Check overall disk usage
df -h

# Check what's using space in /var/app/current
du -sh /var/app/current/* | sort -h | tail -10

# Check database size
ls -lh /var/app/current/nyc_taxi.db

# Check for large files
find /var/app/current -type f -size +100M -exec ls -lh {} \;
```

## Solutions

### Solution 1: Free Up Space (Quick Fix)

Run the cleanup script:

```bash
cd /var/app/current
sudo bash free_disk_space.sh
```

Or manually:

```bash
# Clean old log files
sudo find /var/log -name "*.log" -type f -mtime +7 -delete
sudo find /var/log -name "*.gz" -type f -mtime +7 -delete

# Clean temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clean pip cache
sudo rm -rf ~/.cache/pip/*
sudo rm -rf /root/.cache/pip/*

# Clean package cache
sudo dnf clean all || sudo yum clean all
```

### Solution 2: Create Indexes on Local Machine (Recommended)

Since the database is 1.7GB and creating indexes requires additional space, create indexes locally and upload:

**On your local machine:**

```powershell
cd D:\Syntasa\backend

# Create indexes locally
sqlite3 nyc_taxi.db "PRAGMA journal_mode=WAL;"
sqlite3 nyc_taxi.db "PRAGMA cache_size=-256000;"
sqlite3 nyc_taxi.db "PRAGMA synchronous=NORMAL;"
sqlite3 nyc_taxi.db "ANALYZE;"

# Create indexes one by one
sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_revenue_covering ON trips(tpep_pickup_datetime, pulocationid, total_amount, fare_amount, tip_amount);"
sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_efficiency_timeseries ON trips(tpep_pickup_datetime, total_amount, tpep_dropoff_datetime);"
sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_zone_revenue ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);"
sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_wait_time_demand ON trips(pulocationid, tpep_pickup_datetime);"
sqlite3 nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_wait_time_supply ON trips(dolocationid, tpep_dropoff_datetime);"

# Verify indexes
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';"

# Upload to S3
aws s3 cp nyc_taxi.db s3://nyc-taxi-data-800155829166/nyc_taxi.db
```

**Then on server:**

```bash
# Stop service
sudo systemctl stop web.service

# Download optimized database
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db

# Set permissions
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db

# Start service
sudo systemctl start web.service
```

### Solution 3: Increase Instance Storage

If you need more space permanently:

1. **Stop the environment:**
   ```powershell
   eb stop
   ```

2. **Modify instance storage in AWS Console:**
   - Go to EC2 → Elastic Beanstalk → Environment
   - Modify instance type or add EBS volume

3. **Restart environment:**
   ```powershell
   eb start
   ```

### Solution 4: Create Indexes in Smaller Batches

If you must create on server, do it in smaller batches and clean up between:

```bash
# Create one index at a time, clean up after each
sudo sqlite3 nyc_taxi.db 'CREATE INDEX IF NOT EXISTS idx_wait_time_demand ON trips(pulocationid, tpep_pickup_datetime);'
sudo rm -rf /tmp/*
sudo sqlite3 nyc_taxi.db 'CREATE INDEX IF NOT EXISTS idx_wait_time_supply ON trips(dolocationid, tpep_dropoff_datetime);'
sudo rm -rf /tmp/*
```

## Recommended Approach

**Best solution:** Create indexes locally (Solution 2) because:
- ✅ More disk space available locally
- ✅ Faster (no network transfer during index creation)
- ✅ Can verify before uploading
- ✅ Avoids server disk space issues

## After Freeing Space

Once you have space, continue with index creation:

```bash
# Verify space
df -h

# Continue with remaining indexes
sudo sqlite3 nyc_taxi.db 'CREATE INDEX IF NOT EXISTS idx_zone_revenue ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);' && echo 'SUCCESS: Index 3/5 created' || echo 'FAILED'
```

