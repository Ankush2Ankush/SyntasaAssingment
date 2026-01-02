# Deployment Guide - Method 1: ETL on Server

This guide provides step-by-step instructions for deploying the NYC TLC Analytics Dashboard using **Method 1: Generate Database on Server** with SQLite.

## Overview

**Deployment Strategy:**
- Backend: AWS (Elastic Beanstalk, EC2, or ECS)
- Database: SQLite (generated on server via ETL)
- Frontend: Vercel, Netlify, or AWS S3 + CloudFront
- Data Files: Parquet files included in deployment package (not in git)

---

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Git** repository with code (large files already removed)
4. **Local data files** ready (`data/` folder with parquet files)
5. **Python 3.11+** and **Node.js 18+** installed locally

---

## Phase 1: Pre-Deployment Preparation

### 1.1 Verify Git Repository

Ensure large files are not in git:

```bash
# Check git status
git status

# Verify database file is not tracked
git ls-files | grep -i "\.db$"

# Verify parquet files are not tracked
git ls-files | grep -i "\.parquet$"
```

**Expected**: No database or parquet files should appear in tracked files.

### 1.2 Prepare Deployment Package

Create a deployment package that includes code + data files:

```bash
# From project root (D:\Syntasa)
cd D:\Syntasa

# Create deployment directory
mkdir deployment
cd deployment

# Copy entire project (excluding .git, venv, node_modules)
# On Windows PowerShell:
xcopy /E /I /EXCLUDE:exclude.txt ..\* .
```

Create `exclude.txt`:
```
.git
.gitignore
venv
__pycache__
node_modules
*.db
*.log
.env
.DS_Store
Thumbs.db
```

**OR** manually create deployment package:
1. Copy entire project folder
2. Remove `.git`, `venv`, `node_modules`, `*.db` files
3. **Keep `data/` folder with parquet files** (this is important!)

### 1.3 Verify Data Files

Ensure parquet files are in `data/` folder:

```bash
# Check data files exist
ls data/*.parquet

# Should see:
# - yellow_tripdata_2025-01.parquet
# - yellow_tripdata_2025-02.parquet
# - yellow_tripdata_2025-03.parquet
# - yellow_tripdata_2025-04.parquet
# - taxi_zone_lookup.csv
```

### 1.4 Create Deployment Scripts

Create deployment helper scripts (optional but recommended).

---

## Phase 2: AWS Backend Deployment

Choose one deployment method:

- [Option A: AWS Elastic Beanstalk](#option-a-aws-elastic-beanstalk-recommended)
- [Option B: AWS EC2](#option-b-aws-ec2)
- [Option C: AWS ECS/Fargate](#option-c-aws-ecsfargate)

---

### Option A: AWS Elastic Beanstalk (Recommended)

#### Step 1: Install EB CLI

```bash
pip install awsebcli
```

#### Step 2: Initialize Elastic Beanstalk

```bash
cd backend
eb init
```

**Configuration:**
- Select region (e.g., `us-east-1`)
- Select application name: `nyc-taxi-api`
- Select platform: `Python`
- Select Python version: `3.11`
- Set up SSH: `Yes` (recommended)

#### Step 3: Create Elastic Beanstalk Configuration

Create `.ebextensions/01_python.config`:

```yaml
option_settings:
  aws:elasticbeanstalk:container:python:
    WSGIPath: app.main:app
  aws:elasticbeanstalk:application:environment:
    PYTHONPATH: "/var/app/current:$PYTHONPATH"
```

Create `.ebextensions/02_storage.config`:

```yaml
# Configure persistent storage for database file
option_settings:
  aws:elasticbeanstalk:application:environment:
    DATABASE_URL: "sqlite:///./nyc_taxi.db"
```

Create `.ebextensions/03_run_etl.config`:

```yaml
# Run ETL after deployment
container_commands:
  01_create_tables:
    command: "cd /var/app/current && python -c 'from app.database.connection import Base, engine; Base.metadata.create_all(bind=engine)'"
    leader_only: true
  02_run_etl:
    command: "cd /var/app/current && python run_etl.py"
    leader_only: true
    timeout: 3600  # 1 hour timeout for ETL
```

#### Step 4: Create Deployment Package

```bash
# From backend directory
cd backend

# Create zip file with code + data folder
# On Windows PowerShell:
Compress-Archive -Path app,data,run_etl.py,requirements.txt,.ebextensions -DestinationPath deploy.zip

# OR manually:
# 1. Copy backend folder contents
# 2. Copy data/ folder from parent directory to backend/
# 3. Zip everything
```

**Important**: The `data/` folder must be in the deployment package!

#### Step 5: Create Environment

```bash
eb create nyc-taxi-api-env
```

**Configuration:**
- Instance type: `t3.small` or `t3.medium` (for ETL processing)
- Environment type: `Single instance` (for SQLite) or `Load balanced` (if needed)
- Enable health reporting: `Yes`

#### Step 6: Deploy

```bash
eb deploy
```

**OR** deploy with zip file:

```bash
eb deploy --source deploy.zip
```

#### Step 7: Monitor ETL Process

```bash
# View logs
eb logs

# SSH into instance
eb ssh

# Check ETL progress
tail -f /var/log/eb-engine.log
```

#### Step 8: Verify Deployment

```bash
# Get environment URL
eb status

# Test health endpoint
curl https://your-app.elasticbeanstalk.com/api/health
```

---

### Option B: AWS EC2

#### Step 1: Launch EC2 Instance

1. Go to AWS Console → EC2 → Launch Instance
2. **Configuration:**
   - AMI: Amazon Linux 2023 or Ubuntu 22.04
   - Instance type: `t3.medium` (minimum for ETL) or `t3.large` (recommended)
   - Storage: 30 GB minimum (for database + data files)
   - Security Group: Allow SSH (22) and HTTP (80), HTTPS (443)
   - Key Pair: Create or select existing

#### Step 2: Connect to Instance

```bash
# SSH into instance
ssh -i your-key.pem ec2-user@your-instance-ip
```

#### Step 3: Install Dependencies

```bash
# Update system
sudo yum update -y  # Amazon Linux
# OR
sudo apt update && sudo apt upgrade -y  # Ubuntu

# Install Python 3.11
sudo yum install -y python3.11 python3.11-pip python3.11-venv git
# OR (Ubuntu)
sudo apt install -y python3.11 python3.11-venv python3.11-pip git

# Install Node.js (for frontend build, if needed)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs
```

#### Step 4: Clone Repository

```bash
# Clone your repository
git clone https://github.com/your-username/SyntasaAssingment.git
cd SyntasaAssingment
```

#### Step 5: Upload Data Files

Since data files are not in git, upload them separately:

```bash
# From your local machine
scp -i your-key.pem -r data/ ec2-user@your-instance-ip:/home/ec2-user/SyntasaAssingment/
```

**OR** use S3:

```bash
# Upload to S3 from local machine
aws s3 cp data/ s3://your-bucket/data/ --recursive

# Download on EC2 instance
aws s3 cp s3://your-bucket/data/ ./data/ --recursive
```

#### Step 6: Set Up Backend

```bash
cd backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create database tables
python -c "from app.database.connection import Base, engine; Base.metadata.create_all(bind=engine)"
```

#### Step 7: Run ETL Pipeline

```bash
# Ensure data files are in ../data/ relative to backend/
# Run ETL
python run_etl.py

# This will take 15-30 minutes depending on instance size
# Monitor progress in terminal
```

#### Step 8: Set Up Application Service

Create systemd service file:

```bash
sudo nano /etc/systemd/system/nyc-taxi-api.service
```

Add content:

```ini
[Unit]
Description=NYC Taxi API
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/SyntasaAssingment/backend
Environment="PATH=/home/ec2-user/SyntasaAssingment/backend/venv/bin"
ExecStart=/home/ec2-user/SyntasaAssingment/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable nyc-taxi-api
sudo systemctl start nyc-taxi-api
sudo systemctl status nyc-taxi-api
```

#### Step 9: Configure Nginx (Optional, for HTTPS)

```bash
# Install Nginx
sudo yum install -y nginx  # Amazon Linux
# OR
sudo apt install -y nginx  # Ubuntu

# Configure Nginx
sudo nano /etc/nginx/conf.d/nyc-taxi-api.conf
```

Add:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Start Nginx:

```bash
sudo systemctl enable nginx
sudo systemctl start nginx
```

---

### Option C: AWS ECS/Fargate

#### Step 1: Create Dockerfile

Create `backend/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Copy data files (from parent directory)
COPY ../data /app/data

# Create database directory
RUN mkdir -p /app/data

# Expose port
EXPOSE 8000

# Run ETL and start server
CMD python run_etl.py && uvicorn app.main:app --host 0.0.0.0 --port 8000
```

#### Step 2: Build and Push Docker Image

```bash
cd backend

# Build image
docker build -t nyc-taxi-api:latest .

# Tag for ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin your-account.dkr.ecr.us-east-1.amazonaws.com

# Create ECR repository
aws ecr create-repository --repository-name nyc-taxi-api --region us-east-1

# Tag image
docker tag nyc-taxi-api:latest your-account.dkr.ecr.us-east-1.amazonaws.com/nyc-taxi-api:latest

# Push image
docker push your-account.dkr.ecr.us-east-1.amazonaws.com/nyc-taxi-api:latest
```

#### Step 3: Create ECS Task Definition

Create `task-definition.json`:

```json
{
  "family": "nyc-taxi-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "2048",
  "memory": "4096",
  "containerDefinitions": [
    {
      "name": "nyc-taxi-api",
      "image": "your-account.dkr.ecr.us-east-1.amazonaws.com/nyc-taxi-api:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DATABASE_URL",
          "value": "sqlite:///./nyc_taxi.db"
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "database",
          "containerPath": "/app"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/nyc-taxi-api",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "volumes": [
    {
      "name": "database",
      "efsVolumeConfiguration": {
        "fileSystemId": "fs-xxxxx",
        "rootDirectory": "/"
      }
    }
  ]
}
```

**Note**: For persistent storage, use EFS (Elastic File System) for the database file.

#### Step 4: Create ECS Service

```bash
aws ecs create-service \
  --cluster your-cluster \
  --service-name nyc-taxi-api \
  --task-definition nyc-taxi-api \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

---

## Phase 3: Frontend Deployment

### Step 1: Build Frontend

```bash
cd frontend

# Install dependencies
npm install

# Build for production
npm run build
```

### Step 2: Configure API Endpoint

Create `frontend/.env.production`:

```env
VITE_API_URL=https://your-backend-url.elasticbeanstalk.com/api/v1
```

Update `frontend/src/services/api.ts` to use environment variable:

```typescript
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';
```

### Step 3: Deploy to Vercel (Recommended)

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd frontend
vercel --prod
```

**OR** connect GitHub repository to Vercel for automatic deployments.

### Step 4: Deploy to Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd frontend
netlify deploy --prod --dir=dist
```

### Step 5: Deploy to AWS S3 + CloudFront

```bash
# Create S3 bucket
aws s3 mb s3://nyc-taxi-dashboard

# Upload build files
aws s3 sync frontend/dist/ s3://nyc-taxi-dashboard --delete

# Enable static website hosting
aws s3 website s3://nyc-taxi-dashboard --index-document index.html

# Create CloudFront distribution (via AWS Console or CLI)
```

---

## Phase 4: Post-Deployment Verification

### 4.1 Backend Health Check

```bash
# Test health endpoint
curl https://your-backend-url/api/health

# Test overview endpoint
curl https://your-backend-url/api/v1/overview
```

### 4.2 Database Verification

```bash
# SSH into server (for EC2/EB)
eb ssh  # Elastic Beanstalk
# OR
ssh -i key.pem ec2-user@ip  # EC2

# Check database file exists
ls -lh nyc_taxi.db

# Check database size (should be ~1.5-2 GB)
du -h nyc_taxi.db

# Verify data loaded
python -c "from app.database.connection import engine; import pandas as pd; print(pd.read_sql('SELECT COUNT(*) FROM trips', engine))"
```

### 4.3 Frontend Verification

1. Open frontend URL in browser
2. Check browser console for errors
3. Test API calls from frontend
4. Verify all dashboard pages load correctly

### 4.4 Performance Testing

```bash
# Test API response times
curl -w "@curl-format.txt" -o /dev/null -s https://your-backend-url/api/v1/overview

# Create curl-format.txt:
# time_namelookup:  %{time_namelookup}\n
# time_connect:  %{time_connect}\n
# time_starttransfer:  %{time_starttransfer}\n
# time_total:  %{time_total}\n
```

---

## Phase 5: Monitoring and Maintenance

### 5.1 Set Up CloudWatch Logs

- **Elastic Beanstalk**: Logs automatically sent to CloudWatch
- **EC2**: Install CloudWatch agent
- **ECS**: Configured in task definition

### 5.2 Database Backup

Since using SQLite, backup the database file:

```bash
# Create backup script
cat > backup_db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
cp nyc_taxi.db backups/nyc_taxi_${DATE}.db
# Upload to S3
aws s3 cp backups/nyc_taxi_${DATE}.db s3://your-bucket/backups/
EOF

chmod +x backup_db.sh

# Schedule daily backup (cron)
crontab -e
# Add: 0 2 * * * /path/to/backup_db.sh
```

### 5.3 Update Deployment

When updating code:

```bash
# For Elastic Beanstalk
eb deploy

# For EC2
git pull
# Restart service
sudo systemctl restart nyc-taxi-api

# For ECS
# Update image and redeploy service
```

---

## Troubleshooting

### ETL Fails or Takes Too Long

**Problem**: ETL process fails or times out

**Solutions**:
1. Increase instance size (more CPU/RAM)
2. Increase timeout in `.ebextensions` config
3. Run ETL manually via SSH
4. Check available disk space

### Database File Not Persisting

**Problem**: Database file disappears after restart

**Solutions**:
1. Ensure database file is on persistent storage (EBS volume)
2. For Elastic Beanstalk: Configure persistent storage in `.ebextensions`
3. For ECS: Use EFS for database file

### Parquet Files Not Found

**Problem**: ETL can't find parquet files

**Solutions**:
1. Verify `data/` folder is in deployment package
2. Check path in ETL script (`../data` relative to backend/)
3. Set `DATA_DIR` environment variable if using different path

### API Not Accessible

**Problem**: Can't access API from frontend

**Solutions**:
1. Check security groups allow HTTP/HTTPS
2. Verify CORS configuration in FastAPI
3. Check backend logs for errors
4. Verify frontend API URL is correct

---

## Deployment Checklist

### Pre-Deployment
- [ ] Large files removed from git history
- [ ] `.gitignore` properly configured
- [ ] Data files (`data/` folder) ready
- [ ] Requirements.txt up to date
- [ ] Environment variables documented

### Backend Deployment
- [ ] AWS account configured
- [ ] Deployment method chosen (EB/EC2/ECS)
- [ ] Instance/Environment created
- [ ] Data files uploaded/included
- [ ] ETL pipeline run successfully
- [ ] Database file created and verified
- [ ] API health check passes
- [ ] CORS configured correctly

### Frontend Deployment
- [ ] Frontend built successfully
- [ ] API endpoint configured
- [ ] Frontend deployed (Vercel/Netlify/S3)
- [ ] Frontend accessible and functional

### Post-Deployment
- [ ] All API endpoints tested
- [ ] Dashboard pages load correctly
- [ ] Database backup configured
- [ ] Monitoring set up
- [ ] Documentation updated

---

## Cost Estimation

**Backend (AWS):**
- Elastic Beanstalk: ~$30-50/month (t3.small)
- EC2: ~$15-30/month (t3.small)
- ECS Fargate: ~$40-60/month (2 vCPU, 4GB RAM)

**Frontend:**
- Vercel: Free tier available
- Netlify: Free tier available
- S3 + CloudFront: ~$1-5/month

**Total Estimated Cost**: $15-65/month depending on deployment method

---

## Next Steps

1. **Monitor Performance**: Set up CloudWatch dashboards
2. **Set Up Alerts**: Configure alerts for errors and high latency
3. **Scale if Needed**: Consider load balancer for high traffic
4. **Optimize**: Review slow queries and optimize SQL
5. **Backup Strategy**: Implement automated database backups

---

## Support

For issues or questions:
1. Check logs: `eb logs` or CloudWatch
2. Review troubleshooting section
3. Verify all checklist items completed
4. Check AWS service health status

---

**Last Updated**: 2025-01-XX
**Deployment Method**: Method 1 - ETL on Server
**Database**: SQLite




