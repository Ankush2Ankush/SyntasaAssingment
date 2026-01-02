# Stop Instance to Modify Volume

## Current Status
- **Instance 1:** `i-00edfe73c878d3e9d` - **Terminated** ✅ (already stopped)
- **Instance 2:** `i-0f8d68ef2a079d659` - **Running** ⚠️ (needs to be stopped)

## Steps to Stop Instance

### Method 1: Using Instance State Dropdown

1. **Select the running instance:**
   - Click the **checkbox** next to `i-0f8d68ef2a079d659` (the Running one)

2. **Stop the instance:**
   - Click **"Instance state ▼"** dropdown (top right, near Actions)
   - Select **"Stop instance"**
   - Confirm the stop action in the popup

3. **Wait for stop:**
   - Status will change: Running → Stopping → Stopped
   - This takes **2-3 minutes**

### Method 2: Using Actions Menu

1. **Select the running instance:**
   - Click the **checkbox** next to `i-0f8d68ef2a079d659`

2. **Stop the instance:**
   - Click **"Actions ▼"** dropdown
   - Select **"Instance state"** → **"Stop instance"**
   - Confirm the stop action

3. **Wait for stop:**
   - Status will change to **"Stopped"** (2-3 minutes)

## After Instance is Stopped

Once the instance status shows **"Stopped"**:

1. **Go to Volumes** (left menu → Elastic Block Store → Volumes)
2. **Select volume:** `vol-07c079eab7ff0b42f`
3. **Modify volume:**
   - Click **"Actions"** → **"Modify volume"**
   - Change size: **8 GiB** → **20 GiB**
   - Click **"Modify"**
4. **Wait for modification** (1-2 minutes)
5. **Start instance again:**
   - Go back to Instances
   - Select instance → **"Instance state"** → **"Start instance"**
6. **Extend filesystem** (after instance starts):
   ```bash
   eb ssh
   sudo growpart /dev/nvme0n1 1
   sudo xfs_growfs / || sudo resize2fs /dev/nvme0n1p1
   df -h  # Verify new size
   ```

---

**Note:** The instance will be unavailable during the stop/modify/start process (about 5-10 minutes total).

---

**Last Updated:** January 2, 2026

