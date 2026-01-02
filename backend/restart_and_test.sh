#!/bin/bash
# Restart server and database, then test endpoints
# Run this in your SSH session on EC2

echo "=== Restarting Server and Testing ==="
echo ""

# 1. Stop the web service
echo "1. Stopping web service..."
sudo systemctl stop web.service
sleep 2

# 2. Check if database is locked and close any connections
echo "2. Checking database locks..."
cd /var/app/current
sudo lsof nyc_taxi.db 2>/dev/null | grep -v COMMAND || echo "No locks found"

# 3. Verify database is accessible
echo "3. Testing database access..."
sqlite3 nyc_taxi.db 'SELECT COUNT(*) FROM trips LIMIT 1;' && echo "Database accessible" || echo "Database error!"

# 4. Check database file permissions
echo "4. Checking database permissions..."
ls -lh nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db

# 5. Start the web service
echo "5. Starting web service..."
sudo systemctl start web.service
sleep 5

# 6. Check service status
echo "6. Checking service status..."
sudo systemctl status web.service --no-pager | head -10

# 7. Wait for application to fully start
echo "7. Waiting for application to start..."
sleep 5

# 8. Test endpoints
echo ""
echo "=== Testing Endpoints ==="
echo ""

echo "Testing /health..."
curl -s --max-time 5 http://localhost:8000/health && echo " ✅" || echo " ❌"
echo ""

echo "Testing /api/health..."
curl -s --max-time 5 http://localhost:8000/api/health && echo " ✅" || echo " ❌"
echo ""

echo "Testing /api/v1/overview (30s timeout)..."
curl -s --max-time 30 http://localhost:8000/api/v1/overview | head -c 200 && echo " ✅" || echo " ❌ (timeout or error)"
echo ""

echo "Testing /api/v1/zones/revenue?limit=1 (20s timeout)..."
curl -s --max-time 20 "http://localhost:8000/api/v1/zones/revenue?limit=1" | head -c 200 && echo " ✅" || echo " ❌ (timeout or error)"
echo ""

echo "=== Restart and Test Complete ==="

