# Frontend Deployment Script
# This script helps deploy the frontend to Vercel (recommended)

param(
    [string]$DeployTarget = "vercel",
    [string]$ApiUrl = "http://nyc-taxi-api-env.eba-givk3xmp.us-east-1.elasticbeanstalk.com"
)

Write-Host "`n=== Frontend Deployment Script ===" -ForegroundColor Cyan
Write-Host "Deploy Target: $DeployTarget" -ForegroundColor Yellow
Write-Host "API URL: $ApiUrl`n" -ForegroundColor Yellow

# Change to frontend directory
$originalDir = Get-Location
Set-Location "$PSScriptRoot"

try {
    # Step 1: Install dependencies
    Write-Host "Step 1: Installing dependencies..." -ForegroundColor Green
    npm install
    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed"
    }

    # Step 2: Create .env.production file
    Write-Host "`nStep 2: Creating .env.production file..." -ForegroundColor Green
    $envContent = "VITE_API_URL=$ApiUrl"
    Set-Content -Path ".env.production" -Value $envContent
    Write-Host "Created .env.production with API URL: $ApiUrl" -ForegroundColor Gray

    # Step 3: Build the application
    Write-Host "`nStep 3: Building application..." -ForegroundColor Green
    npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }

    # Step 4: Deploy based on target
    Write-Host "`nStep 4: Deploying to $DeployTarget..." -ForegroundColor Green
    
    switch ($DeployTarget.ToLower()) {
        "vercel" {
            # Check if Vercel CLI is installed
            $vercelInstalled = Get-Command vercel -ErrorAction SilentlyContinue
            if (-not $vercelInstalled) {
                Write-Host "Vercel CLI not found. Installing..." -ForegroundColor Yellow
                npm install -g vercel
            }
            
            Write-Host "`nDeploying to Vercel..." -ForegroundColor Cyan
            Write-Host "Follow the prompts to complete deployment.`n" -ForegroundColor Yellow
            vercel --prod
        }
        
        "netlify" {
            # Check if Netlify CLI is installed
            $netlifyInstalled = Get-Command netlify -ErrorAction SilentlyContinue
            if (-not $netlifyInstalled) {
                Write-Host "Netlify CLI not found. Installing..." -ForegroundColor Yellow
                npm install -g netlify-cli
            }
            
            Write-Host "`nDeploying to Netlify..." -ForegroundColor Cyan
            netlify deploy --prod
        }
        
        "s3" {
            $bucketName = "nyc-taxi-frontend"
            Write-Host "`nDeploying to S3 bucket: $bucketName" -ForegroundColor Cyan
            
            # Check if bucket exists
            $bucketExists = aws s3 ls "s3://$bucketName" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Creating S3 bucket..." -ForegroundColor Yellow
                aws s3 mb "s3://$bucketName" --region us-east-1
            }
            
            # Upload files
            Write-Host "Uploading files to S3..." -ForegroundColor Yellow
            aws s3 sync dist/ "s3://$bucketName" --delete
            
            Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
            Write-Host "Website URL: http://$bucketName.s3-website-us-east-1.amazonaws.com" -ForegroundColor Cyan
        }
        
        default {
            Write-Host "Unknown deployment target: $DeployTarget" -ForegroundColor Red
            Write-Host "Available options: vercel, netlify, s3" -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host "`n✅ Deployment process completed!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Verify the frontend is accessible" -ForegroundColor White
    Write-Host "2. Test API calls in the browser console" -ForegroundColor White
    Write-Host "3. Check for CORS errors (may need backend CORS update)" -ForegroundColor White
    
} catch {
    Write-Host "`n❌ Deployment failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Set-Location $originalDir
}

