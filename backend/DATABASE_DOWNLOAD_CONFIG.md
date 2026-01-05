# Database Download Configuration

## Overview

The deployment is now configured to **download the optimized database from S3** instead of running ETL. This significantly speeds up deployment and uses your pre-built optimized database with indexes for January data.

## Configuration Details

### S3 Bucket Location
- **Bucket**: `nyc-taxi-data-800155829166`
- **Database File**: `nyc_taxi.db` (at root level, not in `data/` folder)
- **Size**: ~951.5 MB (optimized with indexes for January data)

### Deployment Flow

1. **Pre-Deployment Hook** (`.ebextensions/02_download_data.config`):
   - Downloads `nyc_taxi.db` from S3 bucket root
   - Sets proper permissions (webapp:webapp, 664)
   - Verifies database file exists
   - **Fallback**: If database download fails, downloads data files for ETL

2. **Post-Deployment Hook** (`.ebextensions/03_run_etl.config`):
   - Checks if database exists and is > 1MB
   - **Skips ETL** if optimized database is found
   - Only runs ETL if database doesn't exist or is too small

## Benefits

✅ **Faster Deployment**: No ETL processing needed (saves 15-30 minutes)  
✅ **Optimized Database**: Uses pre-built database with indexes  
✅ **January Data Only**: Database contains optimized January data  
✅ **Reliable**: Fallback to ETL if database download fails  

## Files Modified

1. **`.ebextensions/02_download_data.config`**
   - Primary: Downloads optimized database from S3
   - Fallback: Downloads data files if database download fails

2. **`.ebextensions/03_run_etl.config`**
   - Checks for existing database
   - Skips ETL if optimized database is found
   - Only runs ETL as fallback

## Deployment Process

### Normal Flow (Database Download Success):
```
1. Deploy application
2. Download nyc_taxi.db from S3 (951.5 MB)
3. Set permissions
4. Skip ETL (database already exists)
5. Start application
```

### Fallback Flow (Database Download Fails):
```
1. Deploy application
2. Database download fails
3. Download data files from S3
4. Run ETL to create database
5. Start application
```

## Verification

After deployment, verify the database:

```bash
# SSH into instance
eb ssh

# Check database
cd /var/app/current
ls -lh nyc_taxi.db

# Verify it's the optimized database
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips;"
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM sqlite_master WHERE type='index';"
```

## Notes

- Database is downloaded during **pre-deployment** phase (before app starts)
- ETL is **automatically skipped** if database exists
- Database file is **~951.5 MB** - download takes 1-2 minutes
- Permissions are set automatically (webapp:webapp, 664)
- If you need to update the database, upload new version to S3 and redeploy

## Troubleshooting

### Database Download Fails
- Check S3 bucket permissions for EC2 instance role
- Verify database file exists in S3: `s3://nyc-taxi-data-800155829166/nyc_taxi.db`
- Check deployment logs: `eb logs`

### ETL Runs Instead of Using Database
- Check if database file exists: `ls -lh /var/app/current/nyc_taxi.db`
- Verify database size is > 1MB
- Check deployment logs for download errors


