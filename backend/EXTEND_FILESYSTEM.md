# Extend Filesystem After Volume Increase

## Problem
Volume size was increased to 20 GiB, but the OS still sees the old 8 GB size. You need to extend the filesystem to use the new space.

## Solution: Extend Filesystem

### Step 1: Check Current Space
```bash
df -h /
```
This will show the old size (probably ~8 GB total, ~910 MB free).

### Step 2: Extend Partition
```bash
sudo growpart /dev/nvme0n1 1
```
Expected output: `CHANGED: partition=1 start=2048 old: size=16775168 end=16777216 new: size=41940959 end=41943007`

### Step 3: Extend Filesystem
Try XFS first (Amazon Linux 2023 uses XFS):
```bash
sudo xfs_growfs /
```

If that doesn't work, try ext4:
```bash
sudo resize2fs /dev/nvme0n1p1
```

### Step 4: Verify New Size
```bash
df -h /
```
Should now show:
- **Size:** ~20G (instead of 8.0G)
- **Avail:** ~12-15 GB (instead of 910 MB)

### Step 5: Download Database
Now you have enough space:
```bash
cd /var/app/current
sudo systemctl stop web.service
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
```

## Troubleshooting

### If `growpart` fails:
```bash
# Check partition layout
sudo fdisk -l /dev/nvme0n1

# Check filesystem type
df -T /
```

### If `xfs_growfs` fails:
- Make sure you're using the correct device
- Try: `sudo xfs_growfs /dev/nvme0n1p1`
- Or: `sudo xfs_growfs -d /` (grow to max available)

### If `resize2fs` fails:
- Check if it's actually ext4: `df -T /`
- If it's XFS, use `xfs_growfs` instead

---

**Last Updated:** January 2, 2026

