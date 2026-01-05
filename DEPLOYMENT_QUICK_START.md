# Deployment Quick Start - Method 1

## Quick Reference for Method 1 Deployment

### Prerequisites Checklist
- [ ] AWS account configured
- [ ] AWS CLI installed (`aws --version`)
- [ ] EB CLI installed (`pip install awsebcli`)
- [ ] Data files in `data/` folder (4 parquet files + CSV)
- [ ] Git repository clean (no large files)

### Fastest Deployment Path: Elastic Beanstalk

```powershell
# 1. Prepare deployment package
cd backend
.\deploy_helper.ps1

# 2. Initialize EB (first time only)
eb init -p python-3.11 nyc-taxi-api

# 3. Create environment (first time only)
eb create nyc-taxi-api-env --instance-type t3.medium

# 4. Deploy
eb deploy --source deploy.zip

# 5. Monitor ETL
eb logs --follow

# 6. Get URL
eb status
```

### Key Files Created
- `DEPLOYMENT_GUIDE_METHOD1.md` - Full detailed guide
- `backend/.ebextensions/` - EB configuration files
- `backend/deploy_helper.ps1` - Deployment package creator

### Important Notes
1. **Data Files**: Must be included in deployment (not in git)
2. **ETL Time**: Takes 15-30 minutes on t3.medium
3. **Database**: Generated on server, ~1.7 GB
4. **CORS**: Configure `FRONTEND_URLS` environment variable

### Environment Variables
```bash
DATABASE_URL=sqlite:///./nyc_taxi.db  # Default, can omit
FRONTEND_URLS=https://your-frontend.vercel.app  # For CORS
```

### Troubleshooting
- **ETL fails**: Check logs, increase instance size
- **Database missing**: Verify ETL completed successfully
- **CORS errors**: Set FRONTEND_URLS environment variable
- **Slow queries**: Database indexes should be created automatically

### Next Steps After Deployment
1. Deploy frontend (Vercel/Netlify)
2. Update frontend API URL
3. Test all endpoints
4. Set up monitoring (CloudWatch)

For detailed instructions, see `DEPLOYMENT_GUIDE_METHOD1.md`





