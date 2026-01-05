# S3 Setup Complete ✅

## What Was Done

1. **S3 Bucket Created**: `nyc-taxi-data-800155829166`
2. **Data Files Uploaded**:
   - ✅ yellow_tripdata_2025-01.parquet (56.42 MB)
   - ✅ yellow_tripdata_2025-02.parquet (57.55 MB)
   - ✅ yellow_tripdata_2025-03.parquet (66.72 MB)
   - ✅ yellow_tripdata_2025-04.parquet (64.23 MB)
   - ✅ taxi_zone_lookup.csv (0.01 MB)

3. **Configuration Updated**:
   - ✅ `.ebextensions/02_download_data.config` - Configured with bucket name
   - ✅ `.ebignore` - Excludes large files from deployment

## Next Steps

### 1. Ensure EC2 Instance Role Has S3 Permissions

The EC2 instance needs permission to read from S3. After creating the environment, you'll need to:

**Option A: Via AWS Console**
1. Go to AWS Console → IAM → Roles
2. Find the role: `aws-elasticbeanstalk-ec2-role` (or the role used by your EB environment)
3. Click "Add permissions" → "Attach policies"
4. Search for and attach: `AmazonS3ReadOnlyAccess`

**Option B: Via AWS CLI** (after environment is created)
```powershell
aws iam attach-role-policy --role-name aws-elasticbeanstalk-ec2-role --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

### 2. Deploy to Elastic Beanstalk

Now you can create the environment:

```powershell
cd D:\Syntasa\backend
eb create nyc-taxi-api-env
```

The deployment should now be under 512MB since:
- ✅ `venv/` is excluded
- ✅ `data/*.parquet` files are excluded
- ✅ Data files will be downloaded from S3 during deployment

### 3. Monitor Deployment

After deployment starts:

```powershell
# View logs
eb logs

# Check status
eb status

# SSH into instance (if needed)
eb ssh
```

### 4. Verify Data Download

After deployment, verify data files were downloaded:

```powershell
eb ssh
# Then on the server:
ls -lh /var/app/current/data/
```

You should see all 5 files (4 parquet + 1 CSV).

## Troubleshooting

### If data files don't download:
1. Check CloudWatch logs: `eb logs`
2. Verify S3 bucket name in `.ebextensions/02_download_data.config`
3. Ensure EC2 instance role has S3 read permissions
4. Check environment variable: `eb printenv | grep S3_DATA_BUCKET`

### If ETL fails:
1. Check if data files exist: `ls -lh /var/app/current/data/`
2. Verify file permissions
3. Check ETL logs in `/var/log/eb-engine.log`

## S3 Bucket Details

- **Bucket Name**: `nyc-taxi-data-800155829166`
- **Region**: `us-east-1`
- **Path**: `s3://nyc-taxi-data-800155829166/data/`

## Files in S3

```
s3://nyc-taxi-data-800155829166/data/
├── yellow_tripdata_2025-01.parquet (59.2 MB)
├── yellow_tripdata_2025-02.parquet (60.3 MB)
├── yellow_tripdata_2025-03.parquet (69.9 MB)
├── yellow_tripdata_2025-04.parquet (67.4 MB)
└── taxi_zone_lookup.csv (12 KB)
```




