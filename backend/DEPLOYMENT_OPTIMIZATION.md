# Deployment Package Optimization

## Problem
Deployment was taking 15+ minutes because large files were being included:
- **nyc_taxi.db**: 5.4 GB (database file)
- **venv/**: Hundreds of MB (virtual environment)
- **data/*.parquet**: 200+ MB (data files)
- **Documentation**: Many .md files
- **Scripts**: Many .ps1, .sh, .bat files

## Solution
Updated `.ebignore` to exclude all unnecessary files.

## Files Excluded

### Critical (Large Files)
- `*.db`, `*.sqlite`, `*.sqlite3` - Database files (5.4 GB)
- `venv/`, `.venv/` - Virtual environments
- `data/*.parquet` - Large data files
- `.elasticbeanstalk/app_versions/` - Old deployment archives

### Documentation & Scripts
- `*.md` - Documentation files (except README.md)
- `*.ps1`, `*.bat`, `*.sh` - Deployment scripts
- `*.txt` - Text files (except requirements.txt, Procfile)

### Other
- `__pycache__/` - Python cache
- `*.log` - Log files
- `.git/` - Git repository
- `node_modules/` - Node modules (if any)

## What's Included

Only essential files for the application:
- `app/` - Application code
- `requirements.txt` - Dependencies
- `Procfile` - Process definition
- `.ebextensions/` - EB configuration
- `run_etl.py` - ETL script
- `data/taxi_zone_lookup.csv` - Small CSV file (included)

## Deployment Size

**Before:** ~6+ GB (with database and venv)  
**After:** ~10-20 MB (only code and configs)

## Speed Improvement

**Before:** 15+ minutes  
**After:** 2-5 minutes

## Verify Deployment Package

To check what's being included:

```powershell
# EB CLI doesn't have a direct way to list included files
# But you can check the zip file size
# The deployment should be much faster now
```

## Important Notes

1. **Database is NOT deployed** - Must be restored from S3 after deployment
2. **Data files are NOT deployed** - Must be downloaded from S3
3. **Virtual environment is NOT deployed** - EB creates its own venv
4. **Only code and configs are deployed** - This is correct!

## After Deployment

Remember to restore the database:

```bash
eb ssh
cd /var/app/current
sudo systemctl stop web.service
sudo aws s3 cp s3://nyc-taxi-data-800155829166/nyc_taxi.db ./nyc_taxi.db
sudo chown webapp:webapp nyc_taxi.db
sudo chmod 664 nyc_taxi.db
sudo systemctl start web.service
```

---

**Last Updated:** January 2, 2026

