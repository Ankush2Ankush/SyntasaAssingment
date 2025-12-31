# Quick Start Guide - Loading Data

## Prerequisites Check

Before loading data, ensure:

1. **PostgreSQL is installed and running**
2. **Database exists**: Create it with:
   ```sql
   CREATE DATABASE nyc_taxi_db;
   ```
3. **Environment file**: Create `backend/.env` with:
   ```env
   DATABASE_URL=postgresql://postgres:your_password@localhost:5432/nyc_taxi_db
   ```

## Option 1: Automated Setup (Windows)

Run the batch script:
```bash
cd backend
setup_and_load_data.bat
```

## Option 2: Manual Setup

### Step 1: Activate Virtual Environment

**Windows:**
```bash
cd backend
venv\Scripts\activate
```

**Mac/Linux:**
```bash
cd backend
source venv/bin/activate
```

### Step 2: Install Dependencies (if not already done)
```bash
pip install -r requirements.txt
```

### Step 3: Check Database Connection
```bash
python check_database.py
```

### Step 4: Create Database Tables
```bash
python -c "from app.database.connection import engine, Base; Base.metadata.create_all(bind=engine)"
```

### Step 5: Load Data
```bash
python run_etl.py
```

This will:
1. Load taxi zone lookup table
2. Load all 4 parquet files (Jan-Apr 2025)
3. Clean and transform data
4. Insert into PostgreSQL database

**Expected time:** 10-30 minutes depending on your system

## Verify Data Load

After loading, verify with:
```bash
python check_database.py
```

Or check directly in PostgreSQL:
```sql
SELECT COUNT(*) FROM trips;
SELECT COUNT(*) FROM taxi_zones;
```

## Troubleshooting

### Database Connection Error
- Verify PostgreSQL is running: `pg_isready` or check services
- Check DATABASE_URL in `.env` file
- Ensure database exists

### Missing Columns Error
- The ETL script handles column name variations automatically
- If issues persist, check the actual column names in parquet files

### Out of Memory
- Reduce batch_size in `etl.py` (default: 10000)
- Process files one at a time

## Next Steps

After data is loaded:
1. Start backend server: `uvicorn app.main:app --reload`
2. Test API: Use curl or Postman to test endpoints (e.g., `curl http://localhost:8000/api/v1/overview`)
3. Start frontend: `cd frontend && npm run dev`

