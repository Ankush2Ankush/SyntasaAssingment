# Disk Space Solution for 5.4 GB Database

## Problem
The optimized database is now **5.4 GB** (increased from 1.7 GB due to indexes), and the EC2 instance doesn't have enough free space.

## Solution Options

### Option 1: Free Up Space (Try First)

Run aggressive cleanup:

```bash
# Check current space
df -h

# Aggressive cleanup
sudo find /var/log -name "*.log" -type f -mtime +1 -delete
sudo find /var/log -name "*.gz" -type f -delete
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo dnf clean all || sudo yum clean all
sudo rm -rf ~/.cache/*
sudo rm -rf /root/.cache/*

# Remove old database (if exists) - we'll download new one
sudo rm -f /var/app/current/nyc_taxi.db

# Check space again
df -h
```

**Need at least 6 GB free** for the 5.4 GB database.

### Option 2: Download to EBS Volume (If Available)

If you have an EBS volume attached:

```bash
# Find EBS volume mount point
df -h | grep -E "/mnt|/data"

# Download to EBS volume (if available)
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db /mnt/nyc_taxi.db
# Then create symlink or move after download
```

### Option 3: Increase Instance Storage

If cleanup doesn't free enough space:

1. **Stop the environment:**
   ```powershell
   eb stop
   ```

2. **Modify instance in AWS Console:**
   - Go to EC2 → Instances
   - Select your instance
   - Modify instance → Change instance type or add EBS volume

3. **Restart environment:**
   ```powershell
   eb start
   ```

### Option 4: Use Smaller Database (Not Recommended)

If you can't increase storage, you could:
- Create indexes on a subset of data
- Use a smaller date range
- But this defeats the purpose of optimization

## Recommended Approach

1. **First:** Run aggressive cleanup (Option 1)
2. **Check space:** Need at least 6 GB free
3. **If still not enough:** Increase instance storage (Option 3)

## After Freeing Space

Once you have 6+ GB free:

```bash
cd /var/app/current
sudo systemctl stop web.service
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
```

## Check Current Space

```bash
df -h /
```

Look for "Avail" column - need at least 6 GB.

---

**Last Updated:** January 2, 2026

