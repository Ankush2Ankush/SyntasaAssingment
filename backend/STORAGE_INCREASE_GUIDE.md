# Increase EC2 Instance Storage

## Current Situation
- **Total storage:** 8 GB
- **Available:** 910 MB
- **Database size:** 5.4 GB (with indexes)
- **Problem:** Not enough space to download the optimized database

## Solution: Increase Root Volume Size

### Option 1: Increase via AWS Console (Recommended)

**Step 1: Stop the Environment**
```powershell
cd D:\Syntasa\backend
eb stop
```

Wait for environment to stop (5-10 minutes).

**Step 2: Modify Volume in AWS Console**

1. Go to: https://console.aws.amazon.com/ec2/
2. Click **"Instances"** in left menu
3. Find your Elastic Beanstalk instance (search for "nyc-taxi-api-env")
4. Click on the instance
5. Click **"Storage"** tab at the bottom
6. Click on the root volume (usually `/dev/xvda` or `/dev/nvme0n1`)
7. Click **"Actions"** → **"Modify Volume"**
8. Change size from **8 GB** to **20 GB** (or more)
9. Click **"Modify"**

**Step 3: Extend Filesystem**

After volume is modified, you need to extend the filesystem:

```bash
eb ssh
sudo growpart /dev/nvme0n1 1
sudo xfs_growfs / || sudo resize2fs /dev/nvme0n1p1
df -h  # Verify new size
```

**Step 4: Start Environment**
```powershell
eb start
```

### Option 2: Use EB CLI to Modify (Alternative)

If you prefer command line, you can modify the environment configuration:

```powershell
# Create a configuration file
eb config save

# Edit the saved config file to increase volume size
# Then apply it
eb config put
```

---

## Quick Alternative: Use Smaller Database

If you can't increase storage right now, you could:

1. **Create indexes on a subset of data** (not recommended - defeats optimization purpose)
2. **Use a database without some indexes** (partial optimization)

But this is **not recommended** as it won't give you the full performance benefits.

---

## Recommended: Increase to 20 GB

**Why 20 GB?**
- Database: 5.4 GB
- OS + Application: ~2 GB
- Logs + Temp: ~2 GB
- Buffer: ~10 GB
- **Total needed:** ~20 GB

---

## After Storage Increase

Once you have enough space:

```bash
cd /var/app/current
sudo systemctl stop web.service
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
```

---

**Last Updated:** January 2, 2026

