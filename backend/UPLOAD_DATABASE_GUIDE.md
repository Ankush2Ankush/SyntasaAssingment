# Upload Database File Directly to EC2

## Option 1: Upload via S3 (Recommended)

### Step 1: Create Database Locally
Run the ETL on your local machine to create the database:

```powershell
cd D:\Syntasa\backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python run_etl.py --data-dir ..\data
```

This will create `nyc_taxi.db` in the backend directory.

### Step 2: Upload to S3 via AWS Console
1. Go to AWS Console → S3
2. Navigate to your bucket: `nyc-taxi-data-800155829166` (or create a new one)
3. Click "Upload"
4. Select `backend/nyc_taxi.db`
5. Click "Upload"

### Step 3: Download on EC2 Instance
SSH into your instance and download:

```bash
cd /var/app/current
aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
chown webapp:webapp nyc_taxi.db
chmod 664 nyc_taxi.db
```

### Step 4: Verify
```bash
sqlite3 nyc_taxi.db '.tables'
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
```

---

## Option 2: Upload via AWS CLI (Faster)

### From Your Local Machine:
```powershell
cd D:\Syntasa\backend

# Upload to S3
aws s3 cp nyc_taxi.db s3://nyc-taxi-data-800155829166/database/nyc_taxi.db

# Then SSH and download
eb ssh
# Then on server:
cd /var/app/current
aws s3 cp s3://nyc-taxi-data-800155829166/database/nyc_taxi.db ./nyc_taxi.db
chown webapp:webapp nyc_taxi.db
chmod 664 nyc_taxi.db
```

---

## Option 3: Use SCP (Direct Transfer)

### From Your Local Machine:
```powershell
cd D:\Syntasa\backend

# Get EC2 instance IP
eb status

# Use SCP to copy directly (requires SSH key)
scp -i C:\Users\ankush\.ssh\aws-eb nyc_taxi.db ec2-user@<EC2-IP>:/var/app/current/
```

**Note:** You'll need the EC2 instance's public IP, which you can get from:
```powershell
eb ssh --command "curl -s http://169.254.169.254/latest/meta-data/public-ipv4"
```

---

## Option 4: Use AWS Systems Manager (Session Manager)

If Session Manager is enabled:
1. Go to AWS Console → EC2 → Instances
2. Select your instance
3. Click "Connect" → "Session Manager"
4. Upload file via Session Manager interface

---

## Important Notes

1. **File Size**: The database file will be large (hundreds of MB to GB). Make sure you have:
   - Enough disk space on EC2 instance
   - Sufficient S3 storage
   - Good network connection for upload

2. **Permissions**: After uploading, ensure correct permissions:
   ```bash
   chown webapp:webapp /var/app/current/nyc_taxi.db
   chmod 664 /var/app/current/nyc_taxi.db
   ```

3. **Restart Application**: After uploading, restart the application:
   ```bash
   sudo systemctl restart web.service
   # Or
   sudo /etc/init.d/web restart
   ```

4. **Backup**: The database will be lost if the instance is replaced. Consider:
   - Using EBS volume for persistence
   - Regular backups to S3
   - Or running ETL on each deployment

---

## Quick Command Summary

**Local (create DB):**
```powershell
cd D:\Syntasa\backend
python run_etl.py --data-dir ..\data
aws s3 cp nyc_taxi.db s3://nyc-taxi-data-800155829166/database/
```

**On EC2 (download):**
```bash
cd /var/app/current
aws s3 cp s3://nyc-taxi-data-800155829166/database/nyc_taxi.db ./
chown webapp:webapp nyc_taxi.db
chmod 664 nyc_taxi.db
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
```

