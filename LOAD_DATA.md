# Data Loading Instructions

Your data files are ready in the `data/` folder:
- ✅ yellow_tripdata_2025-01.parquet
- ✅ yellow_tripdata_2025-02.parquet  
- ✅ yellow_tripdata_2025-03.parquet
- ✅ yellow_tripdata_2025-04.parquet
- ✅ taxi_zone_lookup.csv

## Step-by-Step Data Loading

### Step 1: Set Up Python Environment

Open PowerShell in the `backend` folder and run:

```powershell
# Create virtual environment
python -m venv venv

# Activate it
.\venv\Scripts\Activate.ps1

# If you get execution policy error, run:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Set Up Database

1. **Ensure PostgreSQL is running**

2. **Create the database:**
```sql
CREATE DATABASE nyc_taxi_db;
```

3. **Create `.env` file** in `backend/` folder:
```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/nyc_taxi_db
```
Replace `your_password` with your PostgreSQL password.

### Step 3: Create Database Tables

With virtual environment activated:

```powershell
python -c "from app.database.connection import engine, Base; Base.metadata.create_all(bind=engine); print('Tables created!')"
```

### Step 4: Load the Data

Run the ETL pipeline:

```powershell
python run_etl.py
```

**This will:**
1. Load taxi zone lookup table (~267 zones)
2. Load all 4 parquet files (Jan-Apr 2025)
3. Clean and transform data
4. Insert into database

**Expected time:** 10-30 minutes (depends on your system)

### Step 5: Verify Data Load

Check if data loaded successfully:

```powershell
python check_database.py
```

Or check in PostgreSQL:
```sql
SELECT COUNT(*) FROM trips;
SELECT COUNT(*) FROM taxi_zones;
SELECT MIN(tpep_pickup_datetime), MAX(tpep_pickup_datetime) FROM trips;
```

## Alternative: Use the Batch Script (Windows)

If you prefer an automated approach:

```powershell
cd backend
.\setup_and_load_data.bat
```

## Troubleshooting

### "ModuleNotFoundError: No module named 'sqlalchemy'"
- Make sure virtual environment is activated
- Run: `pip install -r requirements.txt`

### "Database connection failed"
- Check PostgreSQL is running
- Verify DATABASE_URL in `.env` file
- Ensure database `nyc_taxi_db` exists

### "Column not found" errors
- The ETL script handles column name variations automatically
- If issues persist, the script will show which columns are missing

### Out of Memory
- The script processes in batches (10,000 rows at a time)
- If still issues, reduce batch_size in `etl.py`

## After Data is Loaded

1. **Start Backend:**
```powershell
cd backend
.\venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --port 8000
```

2. **Test API:**
- Visit: http://localhost:8000/docs
- Test `/api/v1/overview` endpoint

3. **Start Frontend:**
```powershell
cd frontend
npm install
npm run dev
```

4. **View Dashboard:**
- Visit: http://localhost:5173

## Expected Results

After successful load, you should see:
- **Trips table:** ~2-5 million records (depending on data)
- **Taxi zones table:** 267 zones
- **Date range:** 2025-01-01 to 2025-04-30

The ETL script will print progress for each file loaded.

