#!/bin/bash
# Step-by-step index creation with success messages
# Run this script to create indexes one by one with progress tracking

DB_PATH="/var/app/current/nyc_taxi.db"

echo "=== Creating Database Indexes ==="
echo "Database: $DB_PATH"
echo ""

# Check if database exists
if [ ! -f "$DB_PATH" ]; then
    echo "ERROR: Database file not found at $DB_PATH"
    exit 1
fi

# Index 1: Revenue covering index
echo "[1/5] Creating idx_revenue_covering..."
sudo sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_revenue_covering ON trips(tpep_pickup_datetime, pulocationid, total_amount, fare_amount, tip_amount);"
if [ $? -eq 0 ]; then
    echo "✅ Index 1/5 created successfully: idx_revenue_covering"
else
    echo "❌ Failed to create idx_revenue_covering"
    exit 1
fi
echo ""

# Index 2: Efficiency timeseries index
echo "[2/5] Creating idx_efficiency_timeseries..."
sudo sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_efficiency_timeseries ON trips(tpep_pickup_datetime, total_amount, tpep_dropoff_datetime);"
if [ $? -eq 0 ]; then
    echo "✅ Index 2/5 created successfully: idx_efficiency_timeseries"
else
    echo "❌ Failed to create idx_efficiency_timeseries"
    exit 1
fi
echo ""

# Index 3: Zone revenue index
echo "[3/5] Creating idx_zone_revenue..."
sudo sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_zone_revenue ON trips(pulocationid, tpep_pickup_datetime, fare_amount, total_amount);"
if [ $? -eq 0 ]; then
    echo "✅ Index 3/5 created successfully: idx_zone_revenue"
else
    echo "❌ Failed to create idx_zone_revenue"
    exit 1
fi
echo ""

# Index 4: Wait time demand index
echo "[4/5] Creating idx_wait_time_demand..."
sudo sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_wait_time_demand ON trips(pulocationid, tpep_pickup_datetime);"
if [ $? -eq 0 ]; then
    echo "✅ Index 4/5 created successfully: idx_wait_time_demand"
else
    echo "❌ Failed to create idx_wait_time_demand"
    exit 1
fi
echo ""

# Index 5: Wait time supply index
echo "[5/5] Creating idx_wait_time_supply..."
sudo sqlite3 "$DB_PATH" "CREATE INDEX IF NOT EXISTS idx_wait_time_supply ON trips(dolocationid, tpep_dropoff_datetime);"
if [ $? -eq 0 ]; then
    echo "✅ Index 5/5 created successfully: idx_wait_time_supply"
else
    echo "❌ Failed to create idx_wait_time_supply"
    exit 1
fi
echo ""

# Verify all indexes
echo "=== Verifying Indexes ==="
INDEX_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND tbl_name='trips';")
echo "Total indexes on trips table: $INDEX_COUNT"
echo ""
echo "List of all indexes:"
sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips' ORDER BY name;"
echo ""

echo "=== All Indexes Created Successfully ==="
echo "✅ 5 new indexes created"
echo "✅ Total indexes: $INDEX_COUNT"

