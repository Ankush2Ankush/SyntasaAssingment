# Deployment Next Steps - Status & Actions

## ✅ Current Status

### Deployment Status
- **Environment**: `nyc-taxi-api-env`
- **Status**: Ready
- **Health**: Green ✅
- **API Base URL**: `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`

### What's Working
- ✅ Application deployed successfully
- ✅ FastAPI server running (uvicorn via Procfile)
- ✅ Health endpoints responding:
  - `/health` - ✅ Working
  - `/api/health` - ✅ Working
  - `/` - ✅ Working
- ✅ S3 permissions attached to EC2 role

### Issues Found
- ⚠️ **API Endpoints Returning 500 Error**: `/api/v1/overview` returns Internal Server Error
  - **Likely Cause**: Database is empty (ETL hasn't run yet or data files not downloaded)
  - **Fix Needed**: Verify data files downloaded and ETL pipeline executed

## 🔍 Investigation Steps

### 1. Check if Data Files Were Downloaded

The data download script should run during deployment via:
- Hook: `/opt/elasticbeanstalk/hooks/appdeploy/pre/01_download_data.sh`
- Environment Variable: `S3_DATA_BUCKET=nyc-taxi-data-800155829166`

**To verify:**
```bash
eb ssh
ls -lh /var/app/current/data/
```

Expected files:
- `yellow_tripdata_2025-01.parquet` (~59 MB)
- `yellow_tripdata_2025-02.parquet` (~60 MB)
- `yellow_tripdata_2025-03.parquet` (~70 MB)
- `yellow_tripdata_2025-04.parquet` (~67 MB)
- `taxi_zone_lookup.csv` (~12 KB)

### 2. Check if ETL Pipeline Ran

The ETL script should run via:
- Hook: `/opt/elasticbeanstalk/hooks/appdeploy/post/99_run_etl.sh`

**To verify:**
```bash
eb ssh
ls -lh /var/app/current/nyc_taxi.db
```

**Check ETL logs:**
```bash
eb logs | grep -i "ETL\|run_etl\|data"
```

### 3. Check Database Status

**To verify database has data:**
```bash
eb ssh
cd /var/app/current
source /var/app/venv/*/bin/activate
python -c "from app.database.connection import engine; import pandas as pd; print(pd.read_sql('SELECT COUNT(*) as count FROM trips', engine))"
```

## 🔧 Manual Actions (If Needed)

### Option 1: Manually Download Data Files

If data files weren't downloaded:

```bash
eb ssh
cd /var/app/current
mkdir -p data
aws s3 cp s3://nyc-taxi-data-800155829166/data/ ./data/ --recursive
ls -lh data/
```

### Option 2: Manually Run ETL

If ETL hasn't run:

```bash
eb ssh
cd /var/app/current
source /var/app/venv/*/bin/activate
export PYTHONPATH="/var/app/current:$PYTHONPATH"
python run_etl.py
```

**Note**: ETL takes 15-30 minutes on t3.micro instance. Run in background if needed:
```bash
nohup python run_etl.py > etl.log 2>&1 &
tail -f etl.log
```

### Option 3: Check Application Logs

```bash
eb logs
# Or view specific log files
eb ssh
tail -f /var/log/eb-engine.log
tail -f /var/log/eb-hooks.log
```

## 📋 Verification Checklist

- [ ] Data files exist in `/var/app/current/data/`
- [ ] Database file exists: `/var/app/current/nyc_taxi.db`
- [ ] Database has data (trip count > 0)
- [ ] ETL pipeline completed successfully
- [ ] API endpoints return data (not 500 errors)

## 🐛 Troubleshooting

### If Data Files Not Downloaded

1. **Check S3 Permissions**: Already attached ✅
2. **Check Environment Variable**: 
   ```bash
   eb printenv | grep S3_DATA_BUCKET
   ```
   Should show: `S3_DATA_BUCKET=nyc-taxi-data-800155829166`

3. **Manually download** (see Option 1 above)

### If ETL Fails

1. **Check Python path**: Ensure venv Python is used
2. **Check data files**: Ensure all parquet files exist
3. **Check disk space**: ETL needs ~2-3 GB free space
4. **Check logs**: Look for specific error messages

### If API Still Returns 500 After ETL

1. **Check database connection**: Verify `DATABASE_URL` is set
2. **Check table structure**: Verify tables were created
3. **Check application logs**: Look for Python exceptions
4. **Test database query**: Manually run a query to verify data

## 📊 Expected Results

After ETL completes:
- Database size: ~1.5-2 GB
- Trip count: ~2-3 million records
- API `/api/v1/overview` should return:
  ```json
  {
    "data": {
      "total_trips": 2000000+,
      "start_date": "2025-01-01...",
      "end_date": "2025-04-30...",
      "zone_count": 200+,
      "total_revenue": 50000000+
    }
  }
  ```

## 🚀 Next Actions

1. **SSH into instance** and verify data files
2. **Check if ETL ran** or run it manually
3. **Test API endpoints** after ETL completes
4. **Monitor ETL progress** (takes 15-30 minutes)

## 📝 Notes

- ETL runs in background via post-deploy hook
- If ETL fails, deployment still succeeds (by design)
- Database is created on app startup (in `main.py`)
- Data files are downloaded before app deployment (pre-deploy hook)




