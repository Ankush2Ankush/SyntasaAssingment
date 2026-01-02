# Modify Volume Size - Step by Step

## Current Status
- **Volume ID:** `vol-07c079eab7ff0b42f` (selected)
- **Current Size:** 8 GiB
- **Target Size:** 20 GiB
- **Status:** In-use

## Steps to Modify Volume

### Step 1: Stop the Instance First
⚠️ **IMPORTANT:** The volume is "In-use". You must stop the instance first!

1. Go to **Instances** in the left menu
2. Find your instance (with tag `elasticbeanstalk:environment-name = nyc-taxi-api-env`)
3. Select the instance
4. Click **"Instance state"** → **"Stop instance"**
5. Wait for status to change to **"Stopped"** (2-3 minutes)

### Step 2: Modify Volume Size

1. **Go back to Volumes** (you're already there)
2. **Select the volume** `vol-07c079eab7ff0b42f` (already selected)
3. Click **"Actions"** button (top right of the table)
4. Select **"Modify volume"** from the dropdown
5. In the popup:
   - Change **Size** from `8` to `20` GiB
   - Review the cost estimate (if shown)
   - Click **"Modify"** button
6. Confirm the modification

### Step 3: Wait for Modification
- The volume modification will start immediately
- Status will show "Modifying" → "Optimizing" → "Completed"
- This takes 1-2 minutes

### Step 4: Start the Instance

1. Go to **Instances**
2. Select your instance
3. Click **"Instance state"** → **"Start instance"**
4. Wait for status to change to **"Running"** (2-3 minutes)

### Step 5: Extend Filesystem

After instance is running, SSH and extend the filesystem:

```bash
eb ssh
sudo growpart /dev/nvme0n1 1
sudo xfs_growfs / || sudo resize2fs /dev/nvme0n1p1
df -h  # Verify new size (should show ~20 GB available)
```

### Step 6: Download Database

Now you have enough space:

```bash
cd /var/app/current
sudo systemctl stop web.service
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
```

---

## Quick Reference

**Volume to modify:** `vol-07c079eab7ff0b42f`  
**Current size:** 8 GiB  
**New size:** 20 GiB  
**Status:** Must be stopped first (currently In-use)

---

**Last Updated:** January 2, 2026

