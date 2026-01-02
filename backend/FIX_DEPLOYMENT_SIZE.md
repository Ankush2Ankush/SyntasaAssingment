# Fix Elastic Beanstalk Deployment Size Error

## Problem
The deployment archive exceeds Elastic Beanstalk's 512MB limit because:
- Parquet data files: ~244 MB
- Virtual environment (venv): ~200-300 MB
- Other files: ~50-100 MB
- **Total: >512 MB**

## Solution: Use S3 for Data Files

We'll exclude data files from the deployment package and download them from S3 during deployment.

### Step 1: Upload Data Files to S3

1. **Create an S3 bucket** (if you don't have one):
   ```powershell
   aws s3 mb s3://nyc-taxi-data --region us-east-1
   ```

2. **Upload data files**:
   ```powershell
   cd backend
   .\upload_data_to_s3.ps1 -BucketName nyc-taxi-data -Region us-east-1
   ```

   Or manually:
   ```powershell
   aws s3 cp ..\data\yellow_tripdata_2025-01.parquet s3://nyc-taxi-data/data/
   aws s3 cp ..\data\yellow_tripdata_2025-02.parquet s3://nyc-taxi-data/data/
   aws s3 cp ..\data\yellow_tripdata_2025-03.parquet s3://nyc-taxi-data/data/
   aws s3 cp ..\data\yellow_tripdata_2025-04.parquet s3://nyc-taxi-data/data/
   aws s3 cp ..\data\taxi_zone_lookup.csv s3://nyc-taxi-data/data/
   ```

### Step 2: Configure Elastic Beanstalk Environment

1. **Set S3 bucket name** as environment variable:
   ```powershell
   eb setenv S3_DATA_BUCKET=nyc-taxi-data
   ```

2. **Ensure EC2 instance role has S3 permissions**:
   - Go to AWS Console → IAM → Roles
   - Find your Elastic Beanstalk EC2 instance role (usually `aws-elasticbeanstalk-ec2-role`)
   - Attach policy: `AmazonS3ReadOnlyAccess`

### Step 3: Deploy

Now the deployment should work:

```powershell
cd backend
eb create nyc-taxi-api-env
```

Or if environment already exists:

```powershell
eb deploy
```

## What Changed

1. **`.ebignore`**: Excludes `venv/`, `__pycache__/`, and `data/*.parquet` files
2. **`.ebextensions/02_download_data.config`**: Downloads data files from S3 before ETL runs
3. **`upload_data_to_s3.ps1`**: Script to upload data files to S3

## Alternative: Quick Test (Without S3)

If you want to test deployment quickly without S3 setup:

1. **Temporarily exclude data files** (already done in `.ebignore`)
2. **Deploy without data files**:
   ```powershell
   eb create nyc-taxi-api-env
   ```
3. **Upload data files manually after deployment**:
   ```powershell
   eb ssh
   # Then on the server:
   aws s3 cp s3://nyc-taxi-data/data/ /var/app/current/data/ --recursive
   python run_etl.py
   ```

## Verify Deployment Size

Check the size of files that will be deployed (excluding ignored files):

```powershell
# This should show < 512 MB
cd backend
Get-ChildItem -Recurse -File | Where-Object { 
    $_.FullName -notmatch 'venv|__pycache__|\.db$|data\\.*\.parquet' 
} | Measure-Object -Property Length -Sum | 
  Select-Object @{Name="Size(MB)";Expression={[math]::Round($_.Sum/1MB, 2)}}
```

## Troubleshooting

### Data files not downloading
- Check `S3_DATA_BUCKET` environment variable is set
- Verify EC2 instance role has S3 read permissions
- Check CloudWatch logs: `eb logs`

### ETL fails to find data files
- Verify files were downloaded: `eb ssh` then `ls -lh /var/app/current/data/`
- Check download script logs in `/var/log/eb-engine.log`



