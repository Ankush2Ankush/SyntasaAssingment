# Redeployment Guide - NYC Taxi API

## ⚠️ Important Note

**The database file is NOT persisted during redeployment.** Elastic Beanstalk resets the application directory (`/var/app/current`) during each deployment, which means the database file must be restored from S3 after every redeployment.

---

## Prerequisites

- AWS CLI configured with appropriate credentials
- EB CLI installed and configured
- SSH access to EC2 instance (via `eb ssh`)
- Database file uploaded to S3: `s3://nyc-taxi-data-800155829166/nyc_taxi.db`

---

## Step-by-Step Redeployment Process

### Step 1: Prepare for Redeployment

```powershell
cd D:\Syntasa\backend
```

Ensure you're in the backend directory before deploying.

### Step 2: Deploy Application

```powershell
eb deploy
```

**What happens:**
- Application code is packaged and uploaded to S3
- New version is deployed to Elastic Beanstalk
- Application directory (`/var/app/current`) is reset
- **Database file is removed** ⚠️
- Application starts with empty database

**Deployment takes:** 5-10 minutes

### Step 3: Monitor Deployment Status

```powershell
eb status
```

Wait until status shows:
- **Status**: `Ready`
- **Health**: `Green` or `Yellow` (will be Red until database is restored)

### Step 4: Restore Database from S3

After deployment completes, you **MUST** restore the database file.

#### Option A: Restore via SSH (Recommended)

**1. SSH into the instance:**
```bash
eb ssh
```

**2. Stop the web service:**
```bash
sudo systemctl stop web.service
```

**3. Download database from S3:**
```bash
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
```

**Note:** Using `sudo aws s3 cp` downloads directly to `/var/app/current` (which has 5GB+ free space), avoiding `/tmp` space limitations.

**4. Set correct permissions:**
```bash
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
```

**5. Start the web service:**
```bash
sudo systemctl start web.service
sleep 10
```

**6. Verify database restored:**
```bash
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
```

Expected output: `15104289` (or your total trip count)

**7. Test the endpoint:**
```bash
curl http://localhost:8000/api/v1/overview | head -c 200
```

Expected: JSON response with trip data

**8. Exit SSH:**
```bash
exit
```

#### Option B: Restore via PowerShell Script (Alternative)

Create a script `restore_database.ps1`:

```powershell
# Restore database after deployment
Write-Host "Restoring database from S3..." -ForegroundColor Cyan

# SSH and run commands
$commands = @"
sudo systemctl stop web.service
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
sleep 10
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
"@

eb ssh --command "$commands"
```

### Step 5: Verify Public Endpoints

Test the public endpoints from your local machine:

```powershell
$baseUrl = "http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com"

# Test health endpoint
Invoke-WebRequest -Uri "$baseUrl/health" -UseBasicParsing

# Test overview endpoint (may take 1-2 minutes)
Invoke-WebRequest -Uri "$baseUrl/api/v1/overview" -TimeoutSec 300 -UseBasicParsing
```

**Expected Results:**
- Health: `200 OK` with `{"status":"healthy"}`
- Overview: `200 OK` with trip data JSON

---

## Configuration Files

### Load Balancer Timeout

The load balancer timeout is configured in `.ebextensions/05_load_balancer_timeout.config` to **300 seconds (5 minutes)** to allow long-running queries to complete.

**File:** `backend/.ebextensions/05_load_balancer_timeout.config`

This configuration:
- Sets idle timeout to 300 seconds via deployment hook script
- Prevents 504 Gateway Timeout errors for slow queries

### Nginx Timeout

The nginx proxy timeout is configured in `.ebextensions/06_nginx_timeout.config` to **300 seconds (5 minutes)**.

**File:** `backend/.ebextensions/06_nginx_timeout.config`

This configuration:
- Automatically modifies `/etc/nginx/nginx.conf` on every deployment
- Sets `proxy_read_timeout`, `proxy_send_timeout`, `proxy_connect_timeout`, and `send_timeout` to 300s
- Persists across redeployments (permanent solution)
- Prevents nginx 504 Gateway Timeout errors

---

## Troubleshooting

### Issue: "No such table: trips" Error

**Cause:** Database was not restored after deployment.

**Solution:**
1. Follow Step 4 above to restore database from S3
2. Verify database file exists: `ls -lh /var/app/current/nyc_taxi.db`
3. Check table exists: `sqlite3 nyc_taxi.db '.tables'`

### Issue: "No space left on device" Error

**Cause:** `/tmp` directory (tmpfs) has limited space (~426MB), but database is 1.7GB.

**Solution:**
- Use `sudo aws s3 cp` to download directly to `/var/app/current` (not `/tmp`)
- This uses the root filesystem which has 5GB+ free space

### Issue: 504 Gateway Timeout

**Cause:** Query takes longer than load balancer or nginx timeout.

**Solution:**
1. **Check if it's from nginx or load balancer:**
   - If error shows "nginx" in response: nginx timeout issue
   - If error shows "504 Gateway Timeout" without nginx: load balancer timeout

2. **For nginx timeout (most common):**
   - Verify nginx timeout settings:
     ```bash
     grep -A 5 "http {" /etc/nginx/nginx.conf | grep timeout
     ```
   - If missing, the `.ebextensions/06_nginx_timeout.config` should apply on next deployment
   - Or apply manually:
     ```bash
     sudo sed -i '/^http {/a\    proxy_read_timeout 300s;\n    proxy_send_timeout 300s;\n    proxy_connect_timeout 300s;\n    send_timeout 300s;' /etc/nginx/nginx.conf
     sudo nginx -t && sudo systemctl reload nginx
     ```

3. **For load balancer timeout:**
   - Verify load balancer timeout script ran:
     ```bash
     grep -i timeout /var/log/eb-hooks.log
     ```
   - Manually set timeout if needed:
     ```bash
     # Get load balancer ARN
     LB_ARN=$(aws elasticbeanstalk describe-environment-resources --environment-name nyc-taxi-api-env --query 'EnvironmentResources.LoadBalancers[0].Name' --output text)
     LB_ARN=$(aws elbv2 describe-load-balancers --names "$LB_ARN" --query 'LoadBalancers[0].LoadBalancerArn' --output text)
     
     # Set timeout
     aws elbv2 modify-load-balancer-attributes --load-balancer-arn "$LB_ARN" --attributes Key=idle_timeout.timeout_seconds,Value=300
     ```

### Issue: 500 Internal Server Error

**Cause:** Application error, often database-related.

**Solution:**
1. Check application logs:
   ```bash
   sudo tail -100 /var/log/web.stdout.log
   sudo tail -100 /var/log/web.stderr.log
   ```
2. Verify database is accessible:
   ```bash
   sqlite3 /var/app/current/nyc_taxi.db 'SELECT COUNT(*) FROM trips LIMIT 1;'
   ```
3. Check database permissions:
   ```bash
   ls -l /var/app/current/nyc_taxi.db
   ```
   Should show: `-rw-rw-r-- 1 webapp webapp`

### Issue: Database Indexes Missing

**Cause:** Indexes are stored in the database file, so they're restored with the database.

**Solution:**
If queries are slow, verify indexes exist:
```bash
sqlite3 /var/app/current/nyc_taxi.db "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='trips';"
```

Expected indexes:
- `idx_pickup_datetime`
- `idx_dropoff_datetime`
- `idx_pulocationid`
- `idx_dolocationid`
- `idx_pickup_location_time`
- `idx_dropoff_location_time`

If indexes are missing, create them (takes 5-10 minutes):
```bash
sudo systemctl stop web.service
sudo sqlite3 /var/app/current/nyc_taxi.db << 'EOF'
CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);
CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);
CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);
CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);
EOF
sudo chown webapp:webapp /var/app/current/nyc_taxi.db
sudo systemctl start web.service
```

---

## Quick Reference

### Essential Commands

```bash
# Deploy
eb deploy

# Check status
eb status

# SSH into instance
eb ssh

# Restore database (run inside SSH)
sudo systemctl stop web.service
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service

# Verify
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
curl http://localhost:8000/api/v1/overview
```

### Environment Details

- **Environment Name:** `nyc-taxi-api-env`
- **Application Name:** `nyc-taxi-api`
- **Region:** `us-east-1`
- **Public URL:** `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`
- **S3 Bucket:** `nyc-taxi-data-800155829166`
- **Database File:** `nyc_taxi.db` (1.7GB, ~15M trips)
- **Load Balancer Timeout:** 300 seconds (5 minutes)
- **Nginx Timeout:** 300 seconds (5 minutes) - configured via `.ebextensions/06_nginx_timeout.config`

---

## Summary Checklist

After each redeployment, ensure:

- [ ] Deployment completed successfully (`eb status` shows Ready)
- [ ] Database downloaded from S3 to `/var/app/current/nyc_taxi.db`
- [ ] Database permissions set correctly (`webapp:webapp`, `664`)
- [ ] Web service restarted (`sudo systemctl start web.service`)
- [ ] Database verified (`sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'`)
- [ ] Health endpoint working (`curl http://localhost:8000/health`)
- [ ] Overview endpoint working (`curl http://localhost:8000/api/v1/overview`)
- [ ] Public endpoints tested and working

---

## Future Improvements

To automate database restoration, consider:

1. **Create a deployment hook script** in `.ebextensions/` that automatically downloads the database after deployment
2. **Use EBS volume** for persistent storage (requires environment modification)
3. **Use RDS** instead of SQLite for production (better for multi-instance deployments)

---

**Last Updated:** January 1, 2026  
**Version:** 1.0

