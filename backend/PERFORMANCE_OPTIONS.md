# Performance Optimization Options

## Current Situation
- **Database size**: 5.4 GB
- **Row count**: ~15,104,289 trips
- **Date range**: January 2025 - April 2025 (4 months)
- **Issue**: Queries timing out (5+ minutes) due to missing indexes

## Option 1: Create Indexes (RECOMMENDED) ✅

### Pros:
- ✅ **Proper solution** - Industry standard for database performance
- ✅ **Fast queries** - Even with 15M rows, indexed queries complete in seconds
- ✅ **Keeps all data** - Full 4 months of data available for analysis
- ✅ **Scalable** - Works even if you add more data later
- ✅ **No data loss** - All historical data preserved

### Cons:
- ⏱️ **One-time setup** - Takes 10-20 minutes to create indexes
- 💾 **Slightly larger DB** - Indexes add ~500MB-1GB to database size

### Performance Impact:
- **Before indexes**: 5+ minutes (timeout)
- **After indexes**: 5-30 seconds (depending on query complexity)

### Implementation:
```bash
# Stop service
sudo systemctl stop web.service

# Create indexes (10-20 minutes)
sudo sqlite3 /var/app/current/nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);"
sudo sqlite3 /var/app/current/nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);"
sudo sqlite3 /var/app/current/nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);"
sudo sqlite3 /var/app/current/nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);"
sudo sqlite3 /var/app/current/nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);"
sudo sqlite3 /var/app/current/nyc_taxi.db "CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);"

# Restart service
sudo systemctl start web.service
```

---

## Option 2: Reduce Data Size (QUICK FIX) ⚠️

### Pros:
- ✅ **Faster setup** - No index creation needed
- ✅ **Smaller database** - Easier to download/upload
- ✅ **Faster queries** - Less data to scan

### Cons:
- ❌ **Data loss** - Less historical data for analysis
- ❌ **Reduced insights** - Can't analyze full 4-month period
- ❌ **Not scalable** - If you add more data later, problem returns
- ❌ **Workaround, not a fix** - Doesn't solve the root cause

### Performance Impact:
- **1 month of data** (~3.7M rows): 30-60 seconds (still slow without indexes)
- **2 months of data** (~7.5M rows): 1-2 minutes (still slow without indexes)
- **With indexes + 4 months**: 5-30 seconds (proper solution)

### Implementation Options:

#### A. Filter to fewer months in queries
Modify the date range in API endpoints:

```python
# Change from:
WHERE tpep_pickup_datetime >= '2025-01-01'
    AND tpep_pickup_datetime < '2025-05-01'

# To (e.g., just January):
WHERE tpep_pickup_datetime >= '2025-01-01'
    AND tpep_pickup_datetime < '2025-02-01'
```

#### B. Delete data from database
```bash
# Stop service
sudo systemctl stop web.service

# Delete data outside desired range (e.g., keep only January)
sudo sqlite3 /var/app/current/nyc_taxi.db "DELETE FROM trips WHERE tpep_pickup_datetime < '2025-01-01' OR tpep_pickup_datetime >= '2025-02-01';"

# Vacuum to reclaim space
sudo sqlite3 /var/app/current/nyc_taxi.db "VACUUM;"

# Restart service
sudo systemctl start web.service
```

#### C. Re-run ETL with filtered data
- Only upload parquet files for desired months
- Re-run ETL to create smaller database

---

## Recommendation: Use Both! 🎯

**Best approach**: Create indexes AND optionally reduce data size if needed

1. **Create indexes first** (proper fix)
   - This solves the timeout issue properly
   - Queries will be fast even with full dataset

2. **Optionally reduce data** if:
   - You don't need all 4 months for your analysis
   - You want a smaller database for easier deployment
   - You're still having issues after indexing (unlikely)

### Expected Performance After Indexes:

| Query Type | Without Indexes | With Indexes |
|------------|----------------|--------------|
| Overview (COUNT, SUM) | 5+ min (timeout) | 5-15 seconds |
| Efficiency Timeseries | 5+ min (timeout) | 10-30 seconds |
| Efficiency Heatmap | 5+ min (timeout) | 15-45 seconds |
| Zone Revenue | 1-2 min | 5-10 seconds |
| Wait Time | 3-5 min | 20-60 seconds |

---

## Quick Decision Guide

**Choose Option 1 (Indexes) if:**
- ✅ You want the proper, scalable solution
- ✅ You need all 4 months of data
- ✅ You want fast queries regardless of data size
- ✅ You might add more data later

**Choose Option 2 (Reduce Data) if:**
- ⚠️ You only need 1-2 months of data
- ⚠️ You want a quick workaround
- ⚠️ You're okay with less historical data
- ⚠️ You won't add more data later

**Choose Both if:**
- 🎯 You want the best of both worlds
- 🎯 You want fast queries AND smaller database
- 🎯 You only need 1-2 months but want proper indexing

---

## My Recommendation

**Start with Option 1 (Indexes)** because:
1. It's the proper solution
2. It fixes the root cause
3. It works with any data size
4. It's a one-time setup

**Then consider Option 2** only if:
- You truly don't need all 4 months
- You want a smaller database for deployment
- You're still having issues (unlikely after indexing)



