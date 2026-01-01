# NYC TLC Analytics Backend

FastAPI backend for NYC Yellow Taxi Trip Records analysis dashboard.

## Setup

1. **Create virtual environment**:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install dependencies**:
```bash
pip install -r requirements.txt
```

3. **Set up database**:
   - Install PostgreSQL or use AWS RDS
   - Create database: `CREATE DATABASE nyc_taxi_db;`
   - Set `DATABASE_URL` in `.env` file

4. **Create database schema**:
```bash
psql -U postgres -d nyc_taxi_db -f app/database/schema.sql
```

5. **Load data** (after downloading parquet files to `data/` folder):
```bash
python -m app.pipelines.etl
```

6. **Run development server**:
```bash
uvicorn app.main:app --reload --port 8000
```

## API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API Endpoints

All endpoints are prefixed with `/api/v1`:

- `GET /overview` - Overview statistics
- `GET /zones/revenue` - Zone revenue metrics
- `GET /zones/net-profit` - Net profit by zone
- `GET /zones/negative-zones` - Zones that become negative
- `GET /efficiency/timeseries` - Efficiency over time
- `GET /efficiency/heatmap` - Efficiency heatmap
- `GET /surge/events` - Surge pricing events
- `GET /surge/correlation` - Surge vs revenue correlation
- `GET /wait-time/current` - Current wait time metrics
- `GET /congestion/zones` - Congestion by zone
- `GET /incentives/driver` - Driver incentive metrics
- `GET /incentives/system` - System efficiency metrics
- `GET /variability/heatmap` - Duration variability heatmap
- `POST /simulation/min-distance` - Minimum distance simulation

See Swagger UI for full documentation.

