# How to Upload Database to S3 - Step by Step

## Step 1: Open the Bucket
1. In the S3 console, you should see a list of buckets
2. **Click on the bucket name:** `nyc-taxi-data-800155829166`
   - This will open the bucket contents

## Step 2: Upload the File
Once inside the bucket:
1. You'll see the **"Upload"** button at the top of the page
2. Click **"Upload"**
3. Click **"Add files"** or drag and drop
4. Navigate to: `D:\Syntasa\backend\nyc_taxi.db`
5. Select the file and click **"Open"**

## Step 3: Handle Overwrite Warning
- S3 will show a warning: "An object with this name already exists"
- Click **"Replace"** or **"Upload anyway"** to overwrite
- The old file will be automatically replaced

## Step 4: Start Upload
1. Review the file details
2. Click **"Upload"** button at the bottom
3. Wait 10-15 minutes for upload (5.41 GB)

## Alternative: Drag and Drop
- You can also drag the file `D:\Syntasa\backend\nyc_taxi.db` directly into the S3 bucket page
- This will automatically start the upload process

---

**Note:** The Upload button only appears **inside** the bucket, not on the buckets list page.

