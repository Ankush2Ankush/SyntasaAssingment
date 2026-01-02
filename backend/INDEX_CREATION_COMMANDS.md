# Individual Index Creation Commands

## Commands with Success Messages

Run these commands one by one in SSH. Each command will show a success message when complete.

### Prerequisites
```bash
cd /var/app/current
sudo systemctl stop web.service
```

### Index 1: Revenue Covering Index
```bash
echo "[1/5] Creating idx_revenue_covering..."
sudo sqlite3 nyc_taxi.db 'CREATE INDEX IF NOT EXISTS idx_revenue_covering ON trips(tpep_pickup_datetime, pulocationid, total_amount, fare_amount, tip_amount);' && echo '✅ Index 1/5 created successfully: idx_revenue_covering' || echo '❌ Failed to create idx_revenue_covering'
```

### Index 2: Efficiency Timeseries Index
```bash
echo "[2/5] Creating idx_efficiency_timeseries..."
sudo sqlite3 nyc_taxi.db 'CREATE INDEX IF NOT EXISTS idx_efficiency_timeseries ON trips(tpep_pickup_datetime, total_amount, tpep_dropoff_datetime);' && echo '✅ Index 2/5 created successfully: idx_efficiency_timeseries' || echo '❌ Failed to create idx_efficiency_timeseries'
```

### Index 3: Zone Revenue Index
```bash
echo "[3/5] Creating idx_zone_revenue..."
sudo sqlite3 nyc_taxi.db 'CREATE INDEX IF NOT EXISTS idx_zone_revenue ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);' && echo '✅ Index 3/5 created successfully: idx_zone_revenue' || echo '❌ Failed to create idx_zone_revenue'
```

### Index 4: Wait Time Demand Index
```bash
echo "[4/5] Creating idx_wait_time_demand..."
sudo sqlite3 nyc_taxi.db 'CREATE INDEX IF NOT EXISTS idx_wait_time_demand ON trips(pulocationid, tpep_pickup_datetime);' && echo '✅ Index 4/5 created successfully: idx_wait_time_demand' || echo '❌ Failed to create idx_wait_time_demand'
```

### Index 5: Wait Time Supply Index
```bash
echo "[5/5] Creating idx_wait_time_supply..."
sudo sqlite3 nyc_taxi.db 'CREATE INDEX IF NOT EXISTS idx_wait_time_supply ON trips(dolocationid, tpep_dropoff_datetime);' && echo '✅ Index 5/5 created successfully: idx_wait_time_supply' || echo '❌ Failed to create idx_wait_time_supply'
```

### Verify All Indexes
```bash
echo "=== Verifying Indexes ==="
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips' ORDER BY name;"
```

### Final Steps
```bash
sudo chown webapp:webapp nyc_taxi.db
sudo systemctl start web.service
sleep 10
curl http://localhost:8000/health
```

---

## Alternative: Use the Script

You can also use the complete script:

```bash
cd /var/app/current
sudo bash create_indexes_step_by_step.sh
```

This script will:
- Create all 5 indexes one by one
- Show progress (1/5, 2/5, etc.)
- Display success message for each index
- Verify all indexes at the end

---

## Notes

- **Each index takes 1-2 minutes** to create on a 1.7GB database
- **Total time:** 5-10 minutes for all indexes
- **If connection drops:** You can resume from the last completed index
- **Indexes are persistent:** Once created, they remain in the database

