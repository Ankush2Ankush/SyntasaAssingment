# Restore Optimized Database on Server

## ✅ Upload Complete
- Database uploaded to S3: `s3://nyc-taxi-data-800155829166/nyc_taxi.db`
- Size: 5.4 GB (includes all 5 indexes)
- Status: Ready to restore

---

## Step-by-Step: Restore on Server

### Step 1: SSH into Server
```bash
eb ssh
```

### Step 2: Navigate and Stop Service
```bash
cd /var/app/current
sudo systemctl stop web.service
```

### Step 3: Download Optimized Database
```bash
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
```
**Note:** This will take 10-15 minutes (5.4 GB download)

### Step 4: Set Permissions
```bash
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
```

### Step 5: Verify Database
```bash
# Check trip count
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
# Expected: 15104289

# Check indexes
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
# Expected: 11+ indexes (6 standard + 5 new)

# List all indexes
sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips' ORDER BY name;"
```

### Step 6: Start Service
```bash
sudo systemctl start web.service
sleep 10
```

### Step 7: Test Endpoints
```bash
# Test health
curl http://localhost:8000/health
# Expected: {"status":"healthy"}

# Test overview (should be much faster now!)
time curl --max-time 300 http://localhost:8000/api/v1/overview | head -c 200
# Expected: 20-30 seconds (vs 186 seconds before)
```

---

## Expected Results

### Performance Improvement
- **Before optimization:** ~186 seconds
- **After optimization:** 20-30 seconds
- **Improvement:** 6-9x faster! 🚀

### Indexes Created
1. ✅ idx_revenue_covering
2. ✅ idx_efficiency_timeseries
3. ✅ idx_zone_revenue
4. ✅ idx_wait_time_demand
5. ✅ idx_wait_time_supply

Plus 6 standard indexes = 11+ total indexes

---

## Quick Command Summary

Copy and paste all at once:

```bash
eb ssh
cd /var/app/current
sudo systemctl stop web.service
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
sudo systemctl start web.service
sleep 10
curl http://localhost:8000/health
time curl --max-time 300 http://localhost:8000/api/v1/overview | head -c 200
```

---

**Last Updated:** January 2, 2026

