# Elastic Beanstalk Deployment Guide

## Current Status
✅ EB CLI installed (v3.25.3)
✅ Configuration files created in `.ebextensions/`
✅ Data folder copied to backend/
✅ All data files verified

## Step-by-Step Deployment

### Step 1: Initialize Elastic Beanstalk

Run from the `backend/` directory:

```powershell
cd backend
eb init
```

**Interactive Prompts - Answer as follows:**

1. **Select a region**: 
   - Choose `us-east-1` (or your preferred region)
   - Press Enter

2. **Enter Application Name**:
   - Type: `nyc-taxi-api`
   - Press Enter

3. **Select a platform**:
   - Choose `Python`
   - Press Enter

4. **Select Platform Branch**:
   - Choose `Python 3.11 running on 64bit Amazon Linux 2023`
   - Press Enter

5. **Set up SSH**:
   - Type: `Y` (Yes - recommended for troubleshooting)
   - Press Enter

6. **Select a keypair**:
   - If you have an existing keypair, select it
   - Or create a new one (recommended for first time)
   - Press Enter

### Step 2: Create Environment

After `eb init` completes, create the environment:

```powershell
eb create nyc-taxi-api-env
```

**Interactive Prompts:**

1. **Load Balancer Type**:
   - For SQLite (single instance), choose: `application` or `single` instance
   - Press Enter

2. **Instance Type**:
   - Type: `t3.medium` (recommended for ETL processing)
   - Or `t3.small` (cheaper, but slower ETL)
   - Press Enter

3. **Environment Type**:
   - Choose: `Single instance` (for SQLite)
   - Press Enter

4. **Enable health reporting**:
   - Type: `Y` (Yes)
   - Press Enter

**Note**: Environment creation takes 5-10 minutes.

### Step 3: Deploy Application

Once environment is created:

```powershell
eb deploy
```

This will:
- Package your application
- Upload to S3
- Deploy to Elastic Beanstalk
- Run ETL pipeline (via `.ebextensions/03_run_etl.config`)

**Deployment takes 10-15 minutes** (including ETL processing).

### Step 4: Monitor Deployment

```powershell
# View logs
eb logs

# Check status
eb status

# SSH into instance (if needed)
eb ssh
```

### Step 5: Verify Deployment

```powershell
# Get environment URL
eb status

# Test health endpoint
curl https://your-app.elasticbeanstalk.com/api/health
```

## Important Notes

1. **ETL Processing**: The ETL pipeline runs automatically after deployment (configured in `.ebextensions/03_run_etl.config`). This takes 15-30 minutes depending on instance size.

2. **Database File**: SQLite database (`nyc_taxi.db`) will be created on the server during ETL.

3. **Data Files**: All parquet files are included in the deployment package.

4. **Monitoring**: Use `eb logs` to monitor ETL progress and check for errors.

## Troubleshooting

### ETL Fails
- Check logs: `eb logs`
- SSH into instance: `eb ssh`
- Verify data files: `ls -lh data/`
- Check disk space: `df -h`

### Deployment Fails
- Check `.ebextensions/` configuration files
- Verify `requirements.txt` is correct
- Check `app/main.py` WSGI path

### Application Not Accessible
- Check security groups allow HTTP/HTTPS
- Verify health endpoint: `eb health`
- Check CORS configuration in `app/main.py`

## Next Steps After Deployment

1. **Frontend Deployment**: Deploy frontend to Vercel/Netlify
2. **Update API URL**: Configure frontend to use EB URL
3. **Set Up Monitoring**: Configure CloudWatch alarms
4. **Backup Strategy**: Set up database backup


