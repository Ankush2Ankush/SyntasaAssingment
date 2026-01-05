# How to Upgrade AWS Account to Use t3.medium

## Overview

To use `t3.medium` instances (or any non-free tier resources), you need to upgrade from the **Free Tier** to a **Pay-As-You-Go** plan. This is a simple process that doesn't require a credit card for the upgrade itself, but you'll be charged for resources you use.

## Important Notes Before Upgrading:

### ✅ What Changes:
- You can use **any instance type** (t3.medium, t3.large, etc.)
- You can use **load balancers** and other paid services
- You'll be charged **only for what you use** (pay-as-you-go)
- Your **free tier credits** ($119.08) will still apply to eligible services

### ⚠️ What to Know:
- **No upfront cost** - You only pay for resources you actually use
- **t3.medium pricing**: ~$0.0416/hour (~$30/month if running 24/7)
- **You can set billing alerts** to avoid surprises
- **You can still use free tier services** - they'll be free until credits run out

## Step-by-Step Upgrade Process:

### Step 1: Access Billing Dashboard

1. **Sign in to AWS Console**: https://console.aws.amazon.com/
2. **Click on your account name** (top right corner)
3. **Click "Billing"** from the dropdown menu
   - Or go directly to: https://console.aws.amazon.com/billing/

### Step 2: Navigate to Account Settings

1. In the **Billing Dashboard**, look for **"Account"** in the left sidebar
2. Click on **"Account"** or **"Account Settings"**
3. You should see your current plan status

### Step 3: Upgrade to Pay-As-You-Go

**Option A: If you see "Upgrade" button:**
1. Click **"Upgrade"** or **"Upgrade Account"** button
2. Review the terms
3. Click **"Confirm"** or **"Upgrade"**

**Option B: If you need to add payment method:**
1. Go to **Billing** → **Payment Methods**
2. Click **"Add Payment Method"**
3. Enter your credit/debit card information
4. Once added, your account automatically becomes Pay-As-You-Go

**Option C: Via Account Settings:**
1. Go to **Billing** → **Account** → **Account Settings**
2. Look for **"Account Type"** or **"Plan"**
3. If it says "Free Tier", look for **"Upgrade"** or **"Change Plan"** option
4. Follow the prompts to upgrade

### Step 4: Verify Upgrade

1. After upgrading, refresh the page
2. Check that your account status shows **"Pay-As-You-Go"** or similar
3. You should now be able to use t3.medium instances

## Alternative: Quick Upgrade via Support

If you can't find the upgrade option:

1. Go to **AWS Support** (top right → Support → Support Center)
2. Create a support case (or use chat)
3. Request: "I want to upgrade my account from Free Tier to Pay-As-You-Go to use t3.medium instances"
4. They'll guide you through the process

## After Upgrading:

### Step 1: Terminate Current Stuck Environment

```powershell
cd D:\Syntasa\backend

# Check current status
eb status

# Terminate the stuck environment
eb terminate nyc-taxi-api-env
```

**Wait 5-10 minutes** for termination to complete.

### Step 2: Recreate Environment with t3.medium

```powershell
# Create environment with t3.medium instance
eb create nyc-taxi-api-env --single --instance-type t3.medium
```

**Interactive Prompts:**
- **Load Balancer Type**: Choose `single` or press Enter for single instance
- **Enable health reporting**: Type `Y` (Yes)
- **Other prompts**: Accept defaults or customize as needed

### Step 3: Monitor Launch

The environment should launch in **5-10 minutes** with t3.medium instance.

## Cost Management:

### Set Up Billing Alerts (Highly Recommended!)

1. Go to **Billing** → **Billing Preferences**
2. Enable **"Receive Billing Alerts"**
3. Go to **CloudWatch** → **Billing** → **Alarms**
4. Create alarm:
   - **Threshold**: $10, $25, $50 (your choice)
   - **Email**: Your email address
   - This will notify you when spending reaches the threshold

### Estimated Monthly Costs:

**For your NYC Taxi API project:**

| Resource | Cost | Notes |
|----------|------|-------|
| **t3.medium instance** | ~$30/month | If running 24/7 |
| **Elastic Beanstalk** | Free | No additional charge |
| **S3 Storage** | ~$0.023/GB/month | Your data files |
| **Data Transfer** | First 1GB free | Then $0.09/GB |
| **Total (estimated)** | **~$30-35/month** | For 24/7 operation |

**If you stop the instance when not in use:**
- You only pay for hours the instance is running
- Can reduce costs significantly

### Free Tier Credits Still Apply:

- Your **$119.08 in credits** will still apply to eligible services
- This means you might not pay anything for the first few months
- Credits apply to: EC2 (t2.micro/t3.micro), S3, etc.

## Quick Command Reference:

```powershell
# After upgrade, recreate environment
cd D:\Syntasa\backend

# Terminate old environment
eb terminate nyc-taxi-api-env

# Wait for termination, then create new one
eb create nyc-taxi-api-env --single --instance-type t3.medium

# Monitor status
eb status
eb events
```

## Troubleshooting:

### If Upgrade Option Not Visible:

1. **Check if already upgraded**: Your account might already be Pay-As-You-Go
2. **Check payment method**: You may need to add a payment method first
3. **Contact AWS Support**: They can help upgrade your account

### If You Get "Insufficient Permissions":

- Make sure you're signed in as the **root account** or an **admin user**
- Free tier accounts sometimes have restrictions

### If Upgrade Fails:

- Try adding a payment method first (Billing → Payment Methods)
- Then the account should automatically become Pay-As-You-Go

## Summary:

1. **Go to**: AWS Console → Billing → Account Settings
2. **Upgrade**: Click "Upgrade" or add payment method
3. **Terminate**: Current stuck environment
4. **Recreate**: With `--instance-type t3.medium`
5. **Set alerts**: Configure billing alerts to monitor costs

**Time to complete**: ~15-20 minutes (including environment recreation)

**Cost**: ~$30/month for t3.medium running 24/7, but you have $119.08 in credits that will cover the first few months!


