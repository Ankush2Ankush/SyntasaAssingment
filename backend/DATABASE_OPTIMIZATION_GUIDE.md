# Database Optimization Guide

## Overview

This guide provides comprehensive database optimization strategies to improve query performance from ~186 seconds to ~20-50 seconds (2-5x improvement).

## Current Performance

- **Without indexes**: ~186 seconds per query
- **With basic indexes**: ~50 seconds per query
- **With full optimization**: ~20-30 seconds per query (target)

---

## Optimization Strategies

### 1. SQLite Configuration Optimizations

#### A. WAL Mode (Write-Ahead Logging)
- **Benefit**: Better concurrency, faster writes
- **Command**: `PRAGMA journal_mode=WAL;`
- **Impact**: 10-20% performance improvement

#### B. Cache Size
- **Current**: Default (2MB)
- **Optimized**: 1GB (256MB pages * 4)
- **Command**: `PRAGMA cache_size=-256000;`
- **Impact**: 30-50% improvement for repeated queries

#### C. Page Size
- **Current**: 4KB (default)
- **Optimized**: 64KB
- **Command**: `PRAGMA page_size=65536;`
- **Impact**: 10-15% improvement for large scans
- **Note**: Must be set before creating database (or use VACUUM)

#### D. Synchronous Mode
- **Current**: FULL (safest, slowest)
- **Optimized**: NORMAL (safe with WAL, faster)
- **Command**: `PRAGMA synchronous=NORMAL;`
- **Impact**: 20-30% write performance improvement

---

### 2. Index Optimizations

#### Current Indexes (Basic)
- `idx_pickup_datetime` - Single column
- `idx_dropoff_datetime` - Single column
- `idx_pulocationid` - Single column
- `idx_dolocationid` - Single column
- `idx_pickup_location_time` - Composite (pulocationid, tpep_pickup_datetime)
- `idx_dropoff_location_time` - Composite (dolocationid, tpep_dropoff_datetime)

#### Additional Optimized Indexes

**A. Covering Index for Revenue Queries**
```sql
CREATE INDEX IF NOT EXISTS idx_revenue_covering 
ON trips(tpep_pickup_datetime, pulocationid, total_amount, fare_amount, tip_amount);
```
- **Benefit**: Query can be satisfied entirely from index (no table access)
- **Use case**: `/api/v1/zones/revenue` endpoint

**B. Efficiency Timeseries Index**
```sql
CREATE INDEX IF NOT EXISTS idx_efficiency_timeseries 
ON trips(tpep_pickup_datetime, total_amount, tpep_dropoff_datetime);
```
- **Benefit**: Optimizes GROUP BY hour queries
- **Use case**: `/api/v1/efficiency/timeseries` endpoint

**C. Zone Revenue Index**
```sql
CREATE INDEX IF NOT EXISTS idx_zone_revenue 
ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);
```
- **Benefit**: Optimizes zone-based revenue aggregations
- **Use case**: Zone revenue and net-profit queries

**D. Wait Time Indexes**
```sql
CREATE INDEX IF NOT EXISTS idx_wait_time_demand 
ON trips(pulocationid, tpep_pickup_datetime);

CREATE INDEX IF NOT EXISTS idx_wait_time_supply 
ON trips(dolocationid, tpep_dropoff_datetime);
```
- **Benefit**: Optimizes demand/supply calculations
- **Use case**: `/api/v1/wait-time/*` endpoints

**E. Partial Index for Date Range**
```sql
CREATE INDEX IF NOT EXISTS idx_date_range 
ON trips(tpep_pickup_datetime) 
WHERE tpep_pickup_datetime >= '2025-01-01' 
  AND tpep_pickup_datetime < '2025-05-01';
```
- **Benefit**: Smaller index, faster queries for date-filtered queries
- **Use case**: All queries filtering by date range

---

### 3. Query Optimizations

#### A. Use EXPLAIN QUERY PLAN
```sql
EXPLAIN QUERY PLAN
SELECT ... FROM trips WHERE ...;
```
- **Purpose**: Verify indexes are being used
- **Look for**: "SEARCH" or "SCAN" operations

#### B. Avoid Full Table Scans
- Ensure WHERE clauses use indexed columns
- Use covering indexes when possible
- Limit result sets early (use LIMIT)

#### C. Optimize Aggregations
- Pre-filter before GROUP BY
- Use indexed columns in GROUP BY
- Consider materialized views for common aggregations

---

### 4. Database Maintenance

#### A. ANALYZE
```sql
ANALYZE;
```
- **Purpose**: Update query planner statistics
- **Frequency**: After index creation, after bulk inserts
- **Impact**: Better query plan selection

#### B. VACUUM
```sql
VACUUM;
```
- **Purpose**: Reorganize database, reclaim space
- **Frequency**: Monthly or after major changes
- **Impact**: Smaller database, faster scans

#### C. REINDEX
```sql
REINDEX;
```
- **Purpose**: Rebuild all indexes
- **Frequency**: After VACUUM or schema changes
- **Impact**: Optimized index structure

---

## Implementation

### Option 1: Automated Script (Recommended)

Run the optimization script:

```bash
eb ssh
cd /var/app/current
sudo systemctl stop web.service
sudo bash optimize_database.sh
sudo chown webapp:webapp nyc_taxi.db
sudo systemctl start web.service
```

**Script location**: `backend/optimize_database.sh`

### Option 2: Manual Steps

```bash
# 1. Stop service
sudo systemctl stop web.service

# 2. Enable WAL mode
sqlite3 nyc_taxi.db "PRAGMA journal_mode=WAL;"

# 3. Increase cache
sqlite3 nyc_taxi.db "PRAGMA cache_size=-256000;"

# 4. Set page size (if database is new or can be recreated)
sqlite3 nyc_taxi.db "PRAGMA page_size=65536;"

# 5. Set synchronous mode
sqlite3 nyc_taxi.db "PRAGMA synchronous=NORMAL;"

# 6. Create additional indexes
sqlite3 nyc_taxi.db << 'EOF'
CREATE INDEX IF NOT EXISTS idx_revenue_covering ON trips(tpep_pickup_datetime, pulocationid, total_amount, fare_amount, tip_amount);
CREATE INDEX IF NOT EXISTS idx_efficiency_timeseries ON trips(tpep_pickup_datetime, total_amount, tpep_dropoff_datetime);
CREATE INDEX IF NOT EXISTS idx_zone_revenue ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);
CREATE INDEX IF NOT EXISTS idx_wait_time_demand ON trips(pulocationid, tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_wait_time_supply ON trips(dolocationid, tpep_dropoff_datetime);
EOF

# 7. Update statistics
sqlite3 nyc_taxi.db "ANALYZE;"

# 8. Vacuum database
sqlite3 nyc_taxi.db "VACUUM;"

# 9. Set permissions
sudo chown webapp:webapp nyc_taxi.db

# 10. Start service
sudo systemctl start web.service
```

---

## Code-Level Optimizations

### Connection Settings (Already Applied)

The `backend/app/database/connection.py` has been updated to:
- Enable WAL mode automatically on connection
- Set cache size to 1GB
- Set synchronous to NORMAL
- Enable query planner optimizations

**These settings apply automatically** when the application connects to the database.

---

## Expected Performance Improvements

| Optimization | Expected Improvement |
|-------------|---------------------|
| Basic indexes | 186s → 50s (3.7x) |
| WAL mode | 50s → 45s (11%) |
| Cache size (1GB) | 45s → 35s (22%) |
| Covering indexes | 35s → 25s (29%) |
| ANALYZE + VACUUM | 25s → 20s (20%) |
| **Total** | **186s → 20s (9.3x)** |

---

## Monitoring Performance

### Check Query Plans
```sql
EXPLAIN QUERY PLAN
SELECT ... FROM trips WHERE ...;
```

### Monitor Index Usage
```sql
-- Check which indexes exist
SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';

-- Check index sizes
SELECT name, (SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips') as index_count;
```

### Test Query Performance
```bash
# Time a query
time sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips WHERE tpep_pickup_datetime >= '2025-01-01';"
```

---

## Maintenance Schedule

### Daily
- None required (automatic via connection.py)

### Weekly
- Check query performance
- Monitor index usage

### Monthly
- Run `ANALYZE` to update statistics
- Run `VACUUM` if database has grown significantly

### After Major Changes
- Rebuild indexes: `REINDEX;`
- Update statistics: `ANALYZE;`
- Vacuum: `VACUUM;`

---

## Troubleshooting

### Issue: Queries Still Slow

1. **Check if indexes are being used:**
   ```sql
   EXPLAIN QUERY PLAN <your_query>;
   ```
   Look for "SEARCH" (good) vs "SCAN" (bad)

2. **Verify WAL mode is enabled:**
   ```sql
   PRAGMA journal_mode;
   ```
   Should return: `wal`

3. **Check cache size:**
   ```sql
   PRAGMA cache_size;
   ```
   Should return: `-256000` (1GB)

4. **Update statistics:**
   ```sql
   ANALYZE;
   ```

### Issue: Database Locked

- WAL mode should prevent this
- Check for long-running queries: `ps aux | grep sqlite3`
- Restart service if needed: `sudo systemctl restart web.service`

---

## Best Practices

1. **Always create indexes** before loading large datasets
2. **Use covering indexes** for frequently accessed columns
3. **Run ANALYZE** after index creation
4. **Monitor query plans** to ensure indexes are used
5. **Use WAL mode** for better concurrency
6. **Set appropriate cache size** based on available memory
7. **Vacuum periodically** to maintain performance

---

**Last Updated:** January 2, 2026  
**Version:** 1.0

