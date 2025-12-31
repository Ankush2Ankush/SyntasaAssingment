# Next Steps - Data Loading

## Current Status

✅ **Data files ready** in `data/` folder:
- 4 parquet files (Jan-Apr 2025)
- Taxi zone lookup CSV
- Data dictionary

✅ **Backend code ready:**
- ETL pipeline created
- Database models defined
- API endpoints implemented

⚠️ **PostgreSQL not running** - Need to set up database

## Option 1: Quick Start with SQLite (For Testing)

If you want to test quickly without PostgreSQL, I can modify the code to use SQLite. This is easier for development but slower for large datasets.

**Pros:**
- No installation needed
- Works immediately
- Good for testing

**Cons:**
- Slower for large datasets
- Not production-ready

## Option 2: Set Up PostgreSQL (Recommended)

### Quick Setup Steps:

1. **Install PostgreSQL:**
   - Download: https://www.postgresql.org/download/windows/
   - Install with default settings
   - Remember the password you set

2. **Create Database:**
   ```sql
   CREATE DATABASE nyc_taxi_db;
   ```

3. **Create `.env` file** in `backend/` folder:
   ```env
   DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/nyc_taxi_db
   ```
   (Replace YOUR_PASSWORD with your PostgreSQL password)

4. **Start PostgreSQL Service:**
   ```powershell
   # Check if service exists
   Get-Service -Name postgresql*
   
   # Start service (adjust name based on your installation)
   Start-Service postgresql-x64-15
   ```

5. **Verify Connection:**
   ```powershell
   cd backend
   .\venv\Scripts\python.exe check_database.py
   ```

6. **Create Tables:**
   ```powershell
   .\venv\Scripts\python.exe -c "import sys; sys.path.insert(0, '.'); from app.database.connection import engine, Base; Base.metadata.create_all(bind=engine); print('Tables created!')"
   ```

7. **Load Data:**
   ```powershell
   .\venv\Scripts\python.exe run_etl.py
   ```

## Option 3: Use Docker (If You Have Docker)

```powershell
# Run PostgreSQL container
docker run --name nyc-taxi-db `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=nyc_taxi_db `
  -p 5432:5432 `
  -d postgres:15

# Update .env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/nyc_taxi_db
```

## What I've Fixed

1. ✅ Fixed data path in ETL script (now looks in `../data` from backend folder)
2. ✅ Fixed Unicode encoding issues in scripts
3. ✅ Created database setup documentation
4. ✅ All dependencies installed

## After Database is Set Up

Once PostgreSQL is running and connected:

1. **Create tables** (one-time setup)
2. **Run ETL pipeline** to load data (10-30 minutes)
3. **Start backend server:**
   ```powershell
   cd backend
   .\venv\Scripts\Activate.ps1
   uvicorn app.main:app --reload --port 8000
   ```
4. **Start frontend:**
   ```powershell
   cd frontend
   npm install
   npm run dev
   ```

## Need Help?

- See `DATABASE_SETUP.md` for detailed PostgreSQL setup
- See `LOAD_DATA.md` for data loading instructions
- See `SETUP_GUIDE.md` for complete setup guide

## Quick Decision

**Want to test quickly?** → I can modify code to use SQLite (just say "use SQLite")

**Want production-ready?** → Set up PostgreSQL following Option 2 above

Let me know which option you prefer!

