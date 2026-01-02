#!/bin/bash
# Fix nginx timeout for long-running queries
# Run this via: eb ssh, then execute: sudo bash fix_nginx_timeout.sh

echo "=== Fixing Nginx Timeout ==="
echo ""

# Check current nginx timeout settings
echo "1. Current nginx timeout settings:"
grep -i timeout /etc/nginx/nginx.conf | head -5
echo ""

# Backup nginx.conf
echo "2. Backing up nginx.conf..."
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"
echo ""

# Check if timeout settings already exist
if grep -q "proxy_read_timeout" /etc/nginx/nginx.conf; then
    echo "3. Timeout settings found, updating..."
    sudo sed -i 's/proxy_read_timeout.*/proxy_read_timeout 300s;/' /etc/nginx/nginx.conf
    sudo sed -i 's/proxy_send_timeout.*/proxy_send_timeout 300s;/' /etc/nginx/nginx.conf
    sudo sed -i 's/proxy_connect_timeout.*/proxy_connect_timeout 300s;/' /etc/nginx/nginx.conf
    sudo sed -i 's/send_timeout.*/send_timeout 300s;/' /etc/nginx/nginx.conf
    echo "✅ Timeout settings updated"
else
    echo "3. Adding timeout settings..."
    # Find the http block and add timeout settings after it
    sudo sed -i '/^http {/a\    proxy_read_timeout 300s;\n    proxy_send_timeout 300s;\n    proxy_connect_timeout 300s;\n    send_timeout 300s;' /etc/nginx/nginx.conf
    echo "✅ Timeout settings added"
fi
echo ""

# Test nginx configuration
echo "4. Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
    echo ""
    echo "5. Reloading nginx..."
    sudo systemctl reload nginx
    if [ $? -eq 0 ]; then
        echo "✅ Nginx reloaded successfully"
    else
        echo "⚠️  Reload failed, trying restart..."
        sudo systemctl restart nginx
    fi
else
    echo "❌ Nginx configuration test failed!"
    echo "Restoring backup..."
    sudo cp /etc/nginx/nginx.conf.backup.* /etc/nginx/nginx.conf
    exit 1
fi
echo ""

# Verify timeout settings
echo "6. Verifying timeout settings:"
grep -i timeout /etc/nginx/nginx.conf | head -5
echo ""

echo "=== Nginx Timeout Fix Complete ==="
echo ""
echo "Timeout settings:"
echo "  - proxy_read_timeout: 300s"
echo "  - proxy_send_timeout: 300s"
echo "  - proxy_connect_timeout: 300s"
echo "  - send_timeout: 300s"
echo ""
echo "Test the endpoint again from Vercel frontend."

