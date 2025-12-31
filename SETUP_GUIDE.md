# NYC TLC Analytics - Setup Guide

Complete setup guide for the NYC TLC Analytics Dashboard project.

## Prerequisites

- Python 3.9+ with pip
- Node.js 18+ with npm
- PostgreSQL 12+ (or AWS RDS)
- Git

## Step 1: Clone and Navigate

```bash
cd D:\Syntasa
```

## Step 2: Backend Setup

### 2.1 Create Virtual Environment

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate
```

### 2.2 Install Dependencies

```bash
pip install -r requirements.txt
```

### 2.3 Set Up Database

1. **Install PostgreSQL** (if not already installed)
2. **Create database**:
```sql
CREATE DATABASE nyc_taxi_db;
```

3. **Create `.env` file** in `backend/` directory:
```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/nyc_taxi_db
CORS_ORIGINS=http://localhost:5173,http://localhost:3000
```

4. **Run schema**:
```bash
psql -U postgres -d nyc_taxi_db -f app/database/schema.sql
```

### 2.4 Download Data

1. Visit: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
2. Download Yellow Taxi Trip Records for:
   - January 2025
   - February 2025
   - March 2025
   - April 2025
3. Download Taxi Zone Lookup Table
4. Place all files in `data/` directory:
   - `yellow_tripdata_2025-01.parquet`
   - `yellow_tripdata_2025-02.parquet`
   - `yellow_tripdata_2025-03.parquet`
   - `yellow_tripdata_2025-04.parquet`
   - `taxi_zone_lookup.csv`

### 2.5 Run ETL Pipeline

```bash
python -m app.pipelines.etl
```

This will:
- Load taxi zone lookup table
- Load and clean all parquet files
- Insert data into PostgreSQL database

**Note**: This may take 10-30 minutes depending on data size.

### 2.6 Start Backend Server

```bash
uvicorn app.main:app --reload --port 8000
```

Backend API will be available at:
- API: http://localhost:8000
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Step 3: Frontend Setup

### 3.1 Install Dependencies

Open a new terminal:

```bash
cd frontend
npm install
```

### 3.2 Configure API Endpoint (Optional)

Create `.env` file in `frontend/` directory:
```env
VITE_API_URL=http://localhost:8000
```

### 3.3 Start Frontend Server

```bash
npm run dev
```

Frontend will be available at: http://localhost:5173

## Step 4: Verify Setup

1. **Backend Health Check**:
   - Visit: http://localhost:8000/health
   - Should return: `{"status": "healthy"}`

2. **Frontend**:
   - Visit: http://localhost:5173
   - Should see the dashboard overview page

3. **API Documentation**:
   - Visit: http://localhost:8000/docs
   - Test endpoints using Swagger UI

## Troubleshooting

### Database Connection Issues

- Verify PostgreSQL is running
- Check `DATABASE_URL` in `.env` file
- Ensure database exists: `psql -U postgres -l`

### ETL Pipeline Issues

- Verify parquet files are in `data/` directory
- Check file names match expected format
- Ensure sufficient disk space

### Frontend Not Connecting to Backend

- Verify backend is running on port 8000
- Check CORS configuration in `backend/app/main.py`
- Verify `VITE_API_URL` in frontend `.env`

### Port Already in Use

- Backend: Change port in `uvicorn` command
- Frontend: Change port in `vite.config.ts`

## Next Steps

1. Explore the dashboard at http://localhost:5173
2. Review API documentation at http://localhost:8000/docs
3. Check assumptions page for methodology details
4. Review each question's analysis

## Deployment

See `IMPLEMENTATION_PLAN.md` for AWS deployment instructions.

