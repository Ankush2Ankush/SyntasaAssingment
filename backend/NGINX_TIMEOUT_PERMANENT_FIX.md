# Permanent Nginx Timeout Fix

## ✅ Solution Applied

I've updated `.ebextensions/06_nginx_timeout.config` to provide a **permanent, robust solution** for nginx timeouts.

## What Changed

### 1. Dual Configuration Approach
- **Primary:** Creates `/etc/nginx/conf.d/elasticbeanstalk-timeout.conf` (more reliable)
- **Fallback:** Updates `/etc/nginx/nginx.conf` directly (ensures it works)

### 2. Improved Logic
- Handles different nginx.conf formats
- Updates existing timeout settings if they exist
- Ensures conf.d directory is included
- Verifies configuration after applying

### 3. Automatic Application
- Applied automatically on every deployment
- No manual intervention needed
- Persists across redeployments

## Deploy the Fix

```powershell
cd D:\Syntasa\backend
eb deploy
```

This will:
1. Create the timeout config file
2. Update nginx.conf
3. Test nginx configuration
4. Reload nginx
5. Verify timeouts are set

## After Deployment

The nginx timeout will be automatically set to **300 seconds (5 minutes)** on every deployment.

### Verify It's Working

After deployment, check on the server:

```bash
eb ssh
grep -i timeout /etc/nginx/nginx.conf
grep -i timeout /etc/nginx/conf.d/elasticbeanstalk-timeout.conf
```

Should show:
```
proxy_read_timeout 300s;
proxy_send_timeout 300s;
proxy_connect_timeout 300s;
send_timeout 300s;
```

## Manual Fix (If Needed Before Deployment)

If you need to fix it immediately before deploying:

```bash
eb ssh
sudo bash fix_nginx_timeout.sh
```

Or manually:

```bash
sudo sed -i '/^http {/a\    proxy_read_timeout 300s;\n    proxy_send_timeout 300s;\n    proxy_connect_timeout 300s;\n    send_timeout 300s;' /etc/nginx/nginx.conf
sudo nginx -t && sudo systemctl reload nginx
```

## Benefits

✅ **Automatic** - Applied on every deployment  
✅ **Persistent** - Survives redeployments  
✅ **Robust** - Multiple fallback methods  
✅ **Verified** - Tests configuration before applying  

---

**Last Updated:** January 2, 2026

