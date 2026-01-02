# Upload Optimized Database to S3 via AWS Console

## Steps

### 1. Open AWS S3 Console
- Go to: https://console.aws.amazon.com/s3/
- Navigate to bucket: `nyc-taxi-data-800155829166`

### 2. Upload the Optimized Database
- Click **"Upload"** button
- Click **"Add files"** or drag and drop
- Select: `D:\Syntasa\backend\nyc_taxi.db`
- **Important:** The file name is `nyc_taxi.db` (same as existing)
- Click **"Upload"**

### 3. Overwrite Confirmation
- S3 will show a warning: "An object with this name already exists"
- Click **"Replace"** or **"Upload anyway"** to overwrite
- The old file will be automatically replaced

### 4. Wait for Upload
- File size: **5.41 GB** (increased from 1.68 GB due to indexes)
- Upload time: **10-15 minutes** (depending on your internet speed)
- You'll see progress bar during upload

### 5. Verify Upload
- After upload completes, verify the file:
  - File name: `nyc_taxi.db`
  - Size: ~5.41 GB
  - Last modified: Should show current date/time

---

## Important Notes

✅ **No need to delete first** - Uploading with the same name automatically overwrites

✅ **File location on your computer:**
   - Path: `D:\Syntasa\backend\nyc_taxi.db`
   - Size: 5.41 GB

✅ **S3 Bucket:**
   - Bucket name: `nyc-taxi-data-800155829166`
   - File name: `nyc_taxi.db`

---

## After Upload

Once uploaded, restore the database on the server:

```bash
eb ssh
cd /var/app/current
sudo systemctl stop web.service
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
sleep 10
curl http://localhost:8000/health
```

---

**Last Updated:** January 2, 2026

