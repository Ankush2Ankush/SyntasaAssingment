#!/bin/bash
# Script to free up disk space on EC2 instance

echo "=== Freeing Up Disk Space ==="
echo ""

# Check current space
echo "Current disk usage:"
df -h /
echo ""

# 1. Clean up old log files
echo "1. Cleaning old log files..."
sudo find /var/log -name "*.log" -type f -mtime +7 -exec rm -f {} \; 2>/dev/null
sudo find /var/log -name "*.gz" -type f -mtime +7 -exec rm -f {} \; 2>/dev/null
echo "✅ Log files cleaned"
echo ""

# 2. Clean up temporary files
echo "2. Cleaning temporary files..."
sudo rm -rf /tmp/* 2>/dev/null
sudo rm -rf /var/tmp/* 2>/dev/null
echo "✅ Temporary files cleaned"
echo ""

# 3. Clean up old Elastic Beanstalk versions (if any)
echo "3. Checking for old EB versions..."
if [ -d "/var/app/versions" ]; then
    OLD_VERSIONS=$(ls -t /var/app/versions | tail -n +4)
    if [ -n "$OLD_VERSIONS" ]; then
        echo "Removing old versions..."
        for version in $OLD_VERSIONS; do
            sudo rm -rf "/var/app/versions/$version"
        done
        echo "✅ Old versions cleaned"
    else
        echo "No old versions to clean"
    fi
else
    echo "No versions directory found"
fi
echo ""

# 4. Clean up pip cache
echo "4. Cleaning pip cache..."
sudo rm -rf ~/.cache/pip/* 2>/dev/null
sudo rm -rf /root/.cache/pip/* 2>/dev/null
echo "✅ Pip cache cleaned"
echo ""

# 5. Clean up package manager cache
echo "5. Cleaning package manager cache..."
sudo dnf clean all 2>/dev/null || sudo yum clean all 2>/dev/null
echo "✅ Package cache cleaned"
echo ""

# Check space after cleanup
echo "Disk usage after cleanup:"
df -h /
echo ""

echo "=== Cleanup Complete ==="

