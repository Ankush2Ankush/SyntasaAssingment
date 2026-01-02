# Upload Indexed Database to S3

## Step 1: Create Indexes Locally

Run the PowerShell script to create indexes on your local database:

```powershell
cd backend
.\create_indexes_local_january.ps1
```

This will:
- Create 6 indexes on the `trips` table
- Take 5-15 minutes depending on your system
- Increase database size by ~500MB-1GB
- Optimize the database for fast queries

## Step 2: Upload to S3 via AWS Console

### Option A: Replace Existing File (Recommended)

1. **Open AWS Console**
   - Go to: https://console.aws.amazon.com/s3/
   - Navigate to bucket: `nyc-taxi-data-800155829166`

2. **Find the existing database file**
   - Look for `nyc_taxi.db` in the bucket
   - Note its current size (should be ~5.4GB if it has indexes, or ~1.7GB if not)

3. **Upload the new indexed database**
   - Click **"Upload"** button (top right)
   - Click **"Add files"** or drag and drop
   - Select: `D:\Syntasa\backend\nyc_taxi.db`
   - **Important**: Check the box to **"Replace"** or **"Overwrite"** existing files
   - Click **"Upload"**
   - Wait for upload to complete (5-10 minutes for ~2GB file)

### Option B: Upload with Different Name (Then Rename)

1. **Upload with a new name**
   - Upload as `nyc_taxi_indexed.db`
   - Wait for upload to complete

2. **Delete old file**
   - Select `nyc_taxi.db`
   - Click **"Delete"**
   - Confirm deletion

3. **Rename new file**
   - Select `nyc_taxi_indexed.db`
   - Click **"Actions"** → **"Rename"**
   - Rename to `nyc_taxi.db`

## Step 3: Verify Upload

After upload, verify the file:

1. **Check file size**
   - Should be ~1.5-2GB (for January data with indexes)
   - Or ~5.4GB if you have full 4 months with indexes

2. **Check file details**
   - Click on `nyc_taxi.db`
   - Verify the "Last modified" timestamp is recent
   - Check the file size matches your local file

## Step 4: Restore on EC2 Instance

After uploading to S3, restore the database on your EC2 instance:

### Via SSH:

```bash
# SSH into server
eb ssh

# Stop web service
sudo systemctl stop web.service

# Download from S3
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db

# Set permissions
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db

# Verify database
sqlite3 nyc_taxi.db "SELECT COUNT(*) FROM trips;"
sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"

# Start web service
sudo systemctl start web.service
sleep 10

# Test endpoints
curl http://localhost:8000/health
time curl --max-time 60 http://localhost:8000/api/v1/efficiency/timeseries | head -c 500
```

## Expected Results

After restoring the indexed database:

- ✅ **Efficiency endpoint**: Should respond in 10-30 seconds (was timing out)
- ✅ **Overview endpoint**: Should respond in 5-15 seconds (was 5+ minutes)
- ✅ **All other endpoints**: Should respond in 5-20 seconds

## Troubleshooting

### Upload Fails
- **Check file size**: Make sure you have enough space in S3 bucket
- **Check permissions**: Ensure your AWS user has S3 write permissions
- **Try chunked upload**: For large files, AWS Console handles this automatically

### Database Not Working After Restore
- **Check permissions**: Ensure `webapp:webapp` owns the file
- **Check file integrity**: Verify the file downloaded completely
- **Check indexes**: Run `sqlite3 nyc_taxi.db ".indexes trips"` to verify indexes exist
- **Restart service**: `sudo systemctl restart web.service`

### Queries Still Slow
- **Verify indexes exist**: Check with `sqlite3 nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"`
- **Check query plan**: Use `EXPLAIN QUERY PLAN` to see if indexes are being used
- **Run ANALYZE**: `sqlite3 nyc_taxi.db "ANALYZE;"` to update statistics

## File Locations

- **Local database**: `D:\Syntasa\backend\nyc_taxi.db`
- **S3 bucket**: `s3://nyc-taxi-data-800155829166/nyc_taxi.db`
- **EC2 location**: `/var/app/current/nyc_taxi.db`


