# Modify Volume While Instance is Running

## Problem
Elastic Beanstalk automatically restarts stopped instances, so we can't keep it stopped long enough to modify the volume.

## Solution: Modify Volume While Running

**Good news:** AWS supports modifying gp3 volumes while they're in-use! You can modify the volume while the instance is running.

## Steps

### Step 1: Modify Volume (While Instance is Running)

1. **Go to Volumes** (left menu → Elastic Block Store → Volumes)
2. **Select volume:** `vol-07c079eab7ff0b42f`
3. **Click "Actions"** → **"Modify volume"**
4. **Change size:**
   - Current: **8 GiB**
   - New: **20 GiB**
5. **Click "Modify"**
6. **Wait for completion:**
   - Status: "Modifying" → "Optimizing" → "Completed"
   - Takes **1-2 minutes**

### Step 2: Extend Filesystem (After Volume Modification)

After the volume modification is complete, you need to extend the filesystem:

```bash
eb ssh
sudo growpart /dev/nvme0n1 1
sudo xfs_growfs / || sudo resize2fs /dev/nvme0n1p1
df -h  # Verify new size (should show ~20 GB available)
```

### Step 3: Download Database

Now you have enough space:

```bash
cd /var/app/current
sudo systemctl stop web.service
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
```

## Important Notes

✅ **Volume modification while running is supported** for gp3 volumes (which you have)

✅ **No downtime required** - the instance can keep running

⚠️ **You must extend the filesystem** after volume modification, otherwise the OS won't see the new space

## Verify Volume Modification

After modifying, check in Volumes console:
- Volume size should show **20 GiB**
- Status should be **"In-use"** and **"Completed"**

Then extend filesystem to make the space available.

---

**Last Updated:** January 2, 2026

