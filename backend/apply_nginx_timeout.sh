#!/bin/bash
# Apply nginx timeout settings manually
# Run this via: eb ssh, then execute: sudo bash apply_nginx_timeout.sh

echo "=== Applying Nginx Timeout Settings ==="
echo ""

# Backup nginx.conf
echo "1. Backing up nginx.conf..."
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"
echo ""

# Check if timeout settings already exist
if grep -q "proxy_read_timeout 300s" /etc/nginx/nginx.conf; then
    echo "2. Timeout settings already exist, updating..."
    sudo sed -i 's/proxy_read_timeout.*/proxy_read_timeout 300s;/' /etc/nginx/nginx.conf
    sudo sed -i 's/proxy_send_timeout.*/proxy_send_timeout 300s;/' /etc/nginx/nginx.conf
    sudo sed -i 's/proxy_connect_timeout.*/proxy_connect_timeout 300s;/' /etc/nginx/nginx.conf
    sudo sed -i 's/send_timeout.*/send_timeout 300s;/' /etc/nginx/nginx.conf
    echo "✅ Timeout settings updated"
else
    echo "2. Adding timeout settings..."
    # Add after http { line
    if grep -q "^http {" /etc/nginx/nginx.conf; then
        sudo sed -i '/^http {/a\    proxy_read_timeout 300s;\n    proxy_send_timeout 300s;\n    proxy_connect_timeout 300s;\n    send_timeout 300s;' /etc/nginx/nginx.conf
        echo "✅ Timeout settings added"
    elif grep -q "^http{" /etc/nginx/nginx.conf; then
        sudo sed -i '/^http{/a\    proxy_read_timeout 300s;\n    proxy_send_timeout 300s;\n    proxy_connect_timeout 300s;\n    send_timeout 300s;' /etc/nginx/nginx.conf
        echo "✅ Timeout settings added"
    else
        echo "❌ Could not find http block in nginx.conf"
        exit 1
    fi
fi
echo ""

# Test nginx configuration
echo "3. Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration test failed!"
    echo "Restoring backup..."
    sudo cp /etc/nginx/nginx.conf.backup.* /etc/nginx/nginx.conf
    exit 1
fi
echo ""

# Reload nginx
echo "4. Reloading nginx..."
if sudo systemctl reload nginx; then
    echo "✅ Nginx reloaded successfully"
else
    echo "⚠️  Reload failed, trying restart..."
    sudo systemctl restart nginx
fi
echo ""

# Verify timeout settings
echo "5. Verifying timeout settings:"
grep -i "proxy.*timeout\|send_timeout" /etc/nginx/nginx.conf | head -5
echo ""

echo "=== Nginx Timeout Settings Applied ==="
echo ""
echo "Settings:"
echo "  - proxy_read_timeout: 300s"
echo "  - proxy_send_timeout: 300s"
echo "  - proxy_connect_timeout: 300s"
echo "  - send_timeout: 300s"
echo ""
echo "✅ Done! Test the efficiency endpoint now."

