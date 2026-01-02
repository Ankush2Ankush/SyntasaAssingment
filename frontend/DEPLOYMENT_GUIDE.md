# Frontend Deployment Guide

## Overview

The frontend is a React + TypeScript application built with Vite. It needs to be configured to connect to the deployed backend API.

**Backend API URL:** `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`

---

## Prerequisites

- Node.js and npm installed
- Backend API deployed and accessible
- Git repository (for Vercel/Netlify)
- AWS account (for S3/CloudFront option)

---

## Option 1: Deploy to Vercel (Recommended - Easiest)

Vercel is the easiest option with automatic deployments, free SSL, and great performance.

### Step 1: Install Vercel CLI

```powershell
npm install -g vercel
```

### Step 2: Configure API URL

Create a `.env.production` file in the `frontend/` directory:

```env
VITE_API_URL=http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com
```

**Note:** For Vercel, you can also set this as an environment variable in the Vercel dashboard.

### Step 3: Build the Application

```powershell
cd frontend
npm install
npm run build
```

Verify the `dist/` folder was created with built files.

### Step 4: Deploy to Vercel

**Option A: Via CLI (First Time)**

```powershell
cd frontend
vercel
```

Follow the prompts:
- Set up and deploy? **Y**
- Which scope? (Select your account)
- Link to existing project? **N**
- Project name: `nyc-taxi-frontend` (or your choice)
- Directory: `./` (current directory)
- Override settings? **N**

**Option B: Via Vercel Dashboard**

1. Go to [vercel.com](https://vercel.com) and sign in
2. Click "Add New Project"
3. Import your Git repository (GitHub/GitLab/Bitbucket)
4. Configure:
   - **Framework Preset:** Vite
   - **Root Directory:** `frontend`
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
5. Add Environment Variable:
   - **Name:** `VITE_API_URL`
   - **Value:** `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`
6. Click "Deploy"

### Step 5: Verify Deployment

After deployment, Vercel will provide a URL like: `https://nyc-taxi-frontend.vercel.app`

Test the application:
- Open the URL in your browser
- Check browser console for any errors
- Verify API calls are working

---

## Option 2: Deploy to Netlify

Netlify is similar to Vercel with automatic deployments and free SSL.

### Step 1: Install Netlify CLI

```powershell
npm install -g netlify-cli
```

### Step 2: Configure API URL

Create a `.env.production` file:

```env
VITE_API_URL=http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com
```

### Step 3: Build the Application

```powershell
cd frontend
npm install
npm run build
```

### Step 4: Deploy to Netlify

**Option A: Via CLI**

```powershell
cd frontend
netlify login
netlify init
netlify deploy --prod
```

**Option B: Via Netlify Dashboard**

1. Go to [netlify.com](https://netlify.com) and sign in
2. Click "Add new site" → "Import an existing project"
3. Connect your Git repository
4. Configure build settings:
   - **Base directory:** `frontend`
   - **Build command:** `npm run build`
   - **Publish directory:** `frontend/dist`
5. Add Environment Variable:
   - **Key:** `VITE_API_URL`
   - **Value:** `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`
6. Click "Deploy site"

---

## Option 3: Deploy to AWS S3 + CloudFront

This option keeps everything in AWS and provides CDN benefits.

### Step 1: Build the Application

```powershell
cd frontend
npm install
npm run build
```

### Step 2: Create S3 Bucket

```powershell
aws s3 mb s3://nyc-taxi-frontend --region us-east-1
```

### Step 3: Configure S3 Bucket for Static Website Hosting

```powershell
# Enable static website hosting
aws s3 website s3://nyc-taxi-frontend --index-document index.html --error-document index.html
```

**Note:** The error document is set to `index.html` to support React Router's client-side routing.

### Step 4: Set Bucket Policy for Public Read Access

Create a file `bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::nyc-taxi-frontend/*"
    }
  ]
}
```

Apply the policy:

```powershell
aws s3api put-bucket-policy --bucket nyc-taxi-frontend --policy file://bucket-policy.json
```

### Step 5: Upload Built Files

```powershell
cd frontend
aws s3 sync dist/ s3://nyc-taxi-frontend --delete
```

### Step 6: Create CloudFront Distribution (Optional but Recommended)

**Via AWS Console:**
1. Go to CloudFront → Create Distribution
2. **Origin Domain:** Select your S3 bucket (`nyc-taxi-frontend.s3.amazonaws.com`)
3. **Origin Access:** Use OAC (Origin Access Control) or keep public
4. **Default Root Object:** `index.html`
5. **Error Pages:** Add custom error response:
   - **HTTP Error Code:** 403
   - **Response Page Path:** `/index.html`
   - **HTTP Response Code:** 200
   - Repeat for 404 errors
6. Click "Create Distribution"

**Via AWS CLI:**

```powershell
aws cloudfront create-distribution --origin-domain-name nyc-taxi-frontend.s3.amazonaws.com --default-root-object index.html
```

### Step 7: Configure Environment Variable

Since S3 is static hosting, you need to set the API URL at build time. Create `.env.production`:

```env
VITE_API_URL=http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com
```

Then rebuild:

```powershell
npm run build
aws s3 sync dist/ s3://nyc-taxi-frontend --delete
```

### Step 8: Access Your Site

- **S3 Website URL:** `http://nyc-taxi-frontend.s3-website-us-east-1.amazonaws.com`
- **CloudFront URL:** `https://d1234567890abc.cloudfront.net` (from CloudFront console)

---

## Option 4: Deploy to GitHub Pages

Free hosting via GitHub Pages.

### Step 1: Install gh-pages Package

```powershell
cd frontend
npm install --save-dev gh-pages
```

### Step 2: Update package.json

Add deploy script to `package.json`:

```json
{
  "scripts": {
    "deploy": "npm run build && gh-pages -d dist"
  }
}
```

### Step 3: Configure vite.config.ts

Update `vite.config.ts` to set the base path:

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/your-repo-name/', // Replace with your GitHub repo name
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
})
```

### Step 4: Build and Deploy

```powershell
# Set API URL
$env:VITE_API_URL="http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com"

# Build and deploy
npm run build
npm run deploy
```

Your site will be available at: `https://your-username.github.io/your-repo-name/`

---

## Environment Variable Configuration

### For All Deployment Options

The frontend uses `VITE_API_URL` environment variable to connect to the backend.

**Backend URL:** `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`

### Setting Environment Variables

**Vercel:**
- Dashboard → Project → Settings → Environment Variables
- Add `VITE_API_URL` with the backend URL

**Netlify:**
- Dashboard → Site → Site settings → Environment variables
- Add `VITE_API_URL` with the backend URL

**AWS S3:**
- Set in `.env.production` file before building
- Rebuild and redeploy after changes

**GitHub Pages:**
- Set as environment variable before build:
  ```powershell
  $env:VITE_API_URL="http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com"
  ```

---

## CORS Configuration

The backend needs to allow requests from your frontend domain. If you encounter CORS errors:

### Update Backend CORS Settings

SSH into the backend instance:

```bash
eb ssh
```

Check the CORS configuration in `backend/app/main.py`. It should allow your frontend domain.

If needed, update the CORS origins in the FastAPI app to include your frontend URL.

---

## Troubleshooting

### Issue: API calls failing with CORS error

**Solution:**
1. Check backend CORS configuration allows your frontend domain
2. Verify `VITE_API_URL` is set correctly
3. Check browser console for exact error message

### Issue: 404 errors on page refresh (React Router)

**Solution:**
- **Vercel/Netlify:** Configure redirects (usually automatic)
- **S3:** Set error document to `index.html` (already done in guide)
- **CloudFront:** Add custom error responses (already done in guide)

### Issue: Environment variable not working

**Solution:**
1. Verify variable name is `VITE_API_URL` (must start with `VITE_` for Vite)
2. Rebuild the application after setting the variable
3. Check the built files to verify the URL is embedded

### Issue: API returns 500 or timeout

**Solution:**
1. Verify backend is running: `curl http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com/health`
2. Check backend logs for errors
3. Verify database is restored (see backend REDEPLOYMENT_GUIDE.md)

---

## Quick Deployment Commands

### Vercel (Recommended)

```powershell
cd frontend
npm install
npm run build
vercel --prod
```

### Netlify

```powershell
cd frontend
npm install
npm run build
netlify deploy --prod
```

### AWS S3

```powershell
cd frontend
npm install
npm run build
aws s3 sync dist/ s3://nyc-taxi-frontend --delete
```

---

## Post-Deployment Checklist

- [ ] Frontend URL is accessible
- [ ] API calls are working (check browser console)
- [ ] All pages load correctly
- [ ] Charts and visualizations render
- [ ] No CORS errors in console
- [ ] Environment variable is set correctly
- [ ] SSL certificate is active (for HTTPS)

---

## Recommended: Vercel

**Why Vercel?**
- ✅ Easiest setup (just `vercel` command)
- ✅ Automatic deployments from Git
- ✅ Free SSL certificates
- ✅ Global CDN
- ✅ Environment variable management
- ✅ Preview deployments for PRs
- ✅ Great performance

**Quick Start:**
```powershell
cd frontend
npm install -g vercel
vercel
```

---

**Last Updated:** January 1, 2026  
**Backend URL:** `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`

