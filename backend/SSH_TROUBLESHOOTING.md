# SSH Connection Troubleshooting

## Issue: SSH Connection Stuck

If `eb ssh` gets stuck or hangs, try these solutions:

## Solution 1: Cancel and Retry

1. **Cancel the stuck connection:**
   - Press `Ctrl+C` in the terminal
   - Or close the terminal window

2. **Retry:**
   ```powershell
   eb ssh
   ```

## Solution 2: Use Direct SSH Command

1. **Get instance IP:**
   ```powershell
   aws ec2 describe-instances --filters "Name=tag:elasticbeanstalk:environment-name,Values=nyc-taxi-api-env" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
   ```

2. **SSH directly:**
   ```powershell
   ssh -i C:\Users\ankush\.ssh\aws-eb ec2-user@<INSTANCE_IP>
   ```
   Replace `<INSTANCE_IP>` with the IP from step 1.

## Solution 3: Check SSH Key Permissions

If SSH still fails, check key permissions:

```powershell
# Windows: Check if key file exists
Test-Path C:\Users\ankush\.ssh\aws-eb

# If key doesn't exist, EB will prompt to create one
eb ssh
```

## Solution 4: Use AWS Systems Manager (Alternative)

If SSH continues to fail, use AWS Systems Manager Session Manager:

1. Go to AWS Console → EC2 → Instances
2. Select your instance
3. Click "Connect" → "Session Manager"
4. Click "Connect"

This opens a browser-based terminal (no SSH key needed).

## Solution 5: Restore Database via AWS CLI

If you can't SSH, you can still restore the database using AWS Systems Manager:

1. Go to AWS Console → Systems Manager → Run Command
2. Create a new command:
   - **Command document:** `AWS-RunShellScript`
   - **Targets:** Select your instance
   - **Commands:**
     ```bash
     sudo systemctl stop web.service
     cd /var/app/current
     sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
     sudo chown webapp:webapp nyc_taxi.db
     sudo chmod 664 nyc_taxi.db
     sudo systemctl start web.service
     ```
3. Run the command

## Quick Commands (Once SSH Works)

```bash
# Restore database
sudo systemctl stop web.service
cd /var/app/current
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service

# Verify
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips;'
curl http://localhost:8000/health
```

---

**Last Updated:** January 2, 2026


