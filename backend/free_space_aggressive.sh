#!/bin/bash
# Aggressive disk space cleanup for EC2 instance
# Run this before downloading the 5.4 GB database

echo "=== Aggressive Disk Space Cleanup ==="
echo ""

# Check current space
echo "1. Current disk usage:"
df -h /
echo ""

# Clean log files (keep only today's)
echo "2. Cleaning old log files..."
sudo find /var/log -name "*.log" -type f -mtime +1 -delete 2>/dev/null
sudo find /var/log -name "*.gz" -type f -delete 2>/dev/null
sudo find /var/log -name "*.old" -type f -delete 2>/dev/null
echo "✅ Log files cleaned"
echo ""

# Clean temporary files
echo "3. Cleaning temporary files..."
sudo rm -rf /tmp/* 2>/dev/null
sudo rm -rf /var/tmp/* 2>/dev/null
echo "✅ Temporary files cleaned"
echo ""

# Clean package cache
echo "4. Cleaning package cache..."
sudo dnf clean all 2>/dev/null || sudo yum clean all 2>/dev/null
echo "✅ Package cache cleaned"
echo ""

# Clean user caches
echo "5. Cleaning user caches..."
sudo rm -rf ~/.cache/* 2>/dev/null
sudo rm -rf /root/.cache/* 2>/dev/null
sudo rm -rf /home/*/.cache/* 2>/dev/null
echo "✅ User caches cleaned"
echo ""

# Clean pip cache
echo "6. Cleaning pip cache..."
sudo rm -rf ~/.cache/pip/* 2>/dev/null
sudo rm -rf /root/.cache/pip/* 2>/dev/null
sudo find /var/app -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
echo "✅ Pip cache cleaned"
echo ""

# Remove old database if exists (we'll download new one)
echo "7. Checking for old database..."
if [ -f "/var/app/current/nyc_taxi.db" ]; then
    OLD_SIZE=$(du -h /var/app/current/nyc_taxi.db | cut -f1)
    echo "Found old database: $OLD_SIZE"
    read -p "Remove old database? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -f /var/app/current/nyc_taxi.db
        echo "✅ Old database removed"
    else
        echo "Keeping old database"
    fi
else
    echo "No old database found"
fi
echo ""

# Check space after cleanup
echo "8. Disk usage after cleanup:"
df -h /
echo ""

AVAILABLE=$(df / | tail -1 | awk '{print $4}')
AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))

echo "=== Cleanup Complete ==="
echo "Available space: ~${AVAILABLE_GB} GB"
echo ""

if [ $AVAILABLE_GB -lt 6 ]; then
    echo "⚠️  WARNING: Less than 6 GB available"
    echo "The database is 5.4 GB. You may need to:"
    echo "1. Increase instance storage"
    echo "2. Use a larger instance type"
    echo "3. Consider using EBS volume for database"
else
    echo "✅ Sufficient space available for 5.4 GB database"
fi

