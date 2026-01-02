#!/bin/bash
# Check disk space and identify what's using space

echo "=== Disk Space Check ==="
echo ""

# Check overall disk usage
echo "1. Overall disk usage:"
df -h
echo ""

# Check specific directories
echo "2. Space usage by directory:"
du -sh /var/app/current/* 2>/dev/null | sort -h | tail -10
echo ""

# Check database size
echo "3. Database file size:"
ls -lh /var/app/current/nyc_taxi.db
echo ""

# Check for large files
echo "4. Large files (>100MB):"
find /var/app/current -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10
echo ""

# Check for log files
echo "5. Log files size:"
du -sh /var/log/*.log 2>/dev/null | sort -h | tail -10
echo ""

# Check temporary files
echo "6. Temporary files:"
du -sh /tmp/* 2>/dev/null 2>/dev/null | sort -h | tail -10
echo ""

# Check available space in /var/app/current
echo "7. Available space in /var/app/current:"
df -h /var/app/current
echo ""

echo "=== Recommendations ==="
echo "If disk is full, consider:"
echo "1. Clean up old log files"
echo "2. Remove temporary files"
echo "3. Check for old application versions"
echo "4. Consider increasing instance storage"

