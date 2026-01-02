# Frontend Deployment - Quick Start

## 🚀 Fastest Way: Deploy to Vercel (5 minutes)

### Step 1: Install Vercel CLI

```powershell
npm install -g vercel
```

### Step 2: Deploy

```powershell
cd frontend
.\deploy.ps1
```

Or manually:

```powershell
cd frontend
npm install
npm run build
vercel --prod
```

Follow the prompts:
- Set up and deploy? **Y**
- Link to existing project? **N** (first time)
- Project name: `nyc-taxi-frontend`
- Directory: `./`

### Step 3: Set Environment Variable

After deployment, go to Vercel Dashboard:
1. Select your project
2. Settings → Environment Variables
3. Add:
   - **Name:** `VITE_API_URL`
   - **Value:** `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`
   - **Environment:** Production, Preview, Development
4. Click "Save"
5. Redeploy: Deployments → ... → Redeploy

### Step 4: Update Backend CORS

After you get your frontend URL (e.g., `https://nyc-taxi-frontend.vercel.app`), update the backend CORS:

**Via SSH:**
```bash
eb ssh
sudo nano /var/app/current/.ebextensions/01_python.config
```

Add to `option_settings`:
```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    PYTHONPATH: "/var/app/current:$PYTHONPATH"
    DATABASE_URL: "sqlite:///./nyc_taxi.db"
    FRONTEND_URLS: "http://localhost:5173,http://localhost:3000,https://your-frontend-url.vercel.app"
```

Then redeploy backend:
```powershell
cd backend
eb deploy
```

**OR via EB CLI:**
```powershell
cd backend
eb setenv FRONTEND_URLS="http://localhost:5173,http://localhost:3000,https://your-frontend-url.vercel.app"
```

### Step 5: Test

Open your frontend URL and verify:
- ✅ Page loads
- ✅ No CORS errors in console
- ✅ API calls work
- ✅ Charts render

---

## Alternative: Manual Deployment

### Build Locally

```powershell
cd frontend

# Create .env.production
echo "VITE_API_URL=http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com" > .env.production

# Install and build
npm install
npm run build
```

### Deploy Options

**Vercel:**
```powershell
vercel --prod
```

**Netlify:**
```powershell
netlify deploy --prod
```

**AWS S3:**
```powershell
aws s3 sync dist/ s3://nyc-taxi-frontend --delete
```

---

## Troubleshooting

### CORS Error

If you see CORS errors:
1. Get your frontend URL (e.g., `https://nyc-taxi-frontend.vercel.app`)
2. Update backend `FRONTEND_URLS` environment variable (see Step 4 above)
3. Restart backend or redeploy

### API Not Working

1. Verify backend is running:
   ```powershell
   curl http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com/health
   ```
2. Check `VITE_API_URL` is set correctly
3. Check browser console for errors

---

**Backend URL:** `http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com`

