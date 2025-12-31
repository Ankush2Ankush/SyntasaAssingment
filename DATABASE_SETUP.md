# Database Setup Instructions

## PostgreSQL Setup Required

The ETL pipeline requires PostgreSQL to be running. Here's how to set it up:

### Option 1: Install PostgreSQL Locally

1. **Download PostgreSQL:**
   - Visit: https://www.postgresql.org/download/windows/
   - Download and install PostgreSQL (latest version recommended)

2. **During Installation:**
   - Remember the password you set for the `postgres` user
   - Note the port (default is 5432)

3. **Create Database:**
   - Open pgAdmin or psql command line
   - Run: `CREATE DATABASE nyc_taxi_db;`

4. **Update `.env` file** in `backend/` folder:
   ```env
   DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/nyc_taxi_db
   ```
   Replace `YOUR_PASSWORD` with your PostgreSQL password.

### Option 2: Use Docker (Recommended for Quick Setup)

If you have Docker installed:

```powershell
# Run PostgreSQL in Docker
docker run --name nyc-taxi-db `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=nyc_taxi_db `
  -p 5432:5432 `
  -d postgres:15

# Update .env file
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/nyc_taxi_db
```

### Option 3: Use AWS RDS (For Production)

1. Create RDS PostgreSQL instance in AWS
2. Update `.env` with RDS connection string:
   ```env
   DATABASE_URL=postgresql://username:password@your-rds-endpoint:5432/nyc_taxi_db
   ```

## Verify PostgreSQL is Running

**Windows:**
```powershell
# Check if PostgreSQL service is running
Get-Service -Name postgresql*

# Or check port
Test-NetConnection -ComputerName localhost -Port 5432
```

**Alternative Check:**
```powershell
# Try connecting with psql (if installed)
psql -U postgres -d postgres -c "SELECT version();"
```

## After PostgreSQL is Set Up

1. **Create `.env` file** in `backend/` folder with correct DATABASE_URL

2. **Test connection:**
   ```powershell
   cd backend
   .\venv\Scripts\python.exe check_database.py
   ```

3. **Create tables:**
   ```powershell
   .\venv\Scripts\python.exe -c "import sys; sys.path.insert(0, '.'); from app.database.connection import engine, Base; Base.metadata.create_all(bind=engine); print('Tables created!')"
   ```

4. **Load data:**
   ```powershell
   .\venv\Scripts\python.exe run_etl.py
   ```

## Troubleshooting

### "Connection refused" Error
- PostgreSQL is not running
- Start PostgreSQL service: `net start postgresql-x64-15` (adjust version)
- Or restart via Services (services.msc)

### "Database does not exist"
- Create it: `CREATE DATABASE nyc_taxi_db;`

### "Authentication failed"
- Check password in `.env` file
- Verify username (usually `postgres`)

### Port 5432 Already in Use
- Another PostgreSQL instance is running
- Change port in PostgreSQL config or use different port in DATABASE_URL

