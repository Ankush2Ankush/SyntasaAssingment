# NYC TLC Analytics Dashboard

Interactive dashboard analyzing NYC Yellow Taxi Trip Records (Jan-Apr 2025) to answer 8 analytical questions about system efficiency, driver incentives, and operational insights.

## Project Structure

```
syntasa-analytics/
├── backend/          # Python FastAPI backend
│   ├── app/
│   │   ├── api/      # API endpoints
│   │   ├── database/ # Database models and connection
│   │   ├── pipelines/ # ETL pipeline
│   │   ├── services/ # Business logic
│   │   └── sql/      # SQL query files
│   └── requirements.txt
├── frontend/         # React TypeScript frontend
└── data/             # Raw data files (parquet, CSV)
```

## Quick Start

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Create virtual environment and install dependencies:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

3. Set up PostgreSQL database and configure `.env` file with `DATABASE_URL`

4. Run database migrations:
```bash
psql -U postgres -d nyc_taxi_db -f app/database/schema.sql
```

5. Download data files to `data/` folder and run ETL:
```bash
python -m app.pipelines.etl
```

6. Start backend server:
```bash
uvicorn app.main:app --reload --port 8000
```

### Frontend Setup

1. Navigate to frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Start development server:
```bash
npm run dev
```

## Features

- **SQL-first data processing**: Efficient SQL queries for analytics
- **8 Analytical Questions**: Comprehensive analysis of taxi operations
- **Interactive Dashboard**: React frontend with Chart.js visualizations
- **RESTful API**: FastAPI backend with auto-generated documentation
- **AWS Ready**: Configured for AWS deployment (RDS, Elastic Beanstalk)

## Assignment Questions

1. High revenue zones that become net negative after accounting for costs
2. Times when increased demand reduces system efficiency
3. Zones where surge pricing correlates with lower revenue
4. Levers to reduce wait time by 10% without adding vehicles
5. Zones with high trips but high congestion (low throughput)
6. Driver incentive misalignment with system efficiency
7. Hours with highest trip duration variability
8. Impact simulation of removing trips below minimum distance threshold

## Technology Stack

**Backend:**
- FastAPI
- PostgreSQL / SQLAlchemy
- Pandas
- SQL for analytics

**Frontend:**
- React 18+ with TypeScript
- Chart.js with plugins
- React Context API
- React Query
- Material-UI

## Documentation

- Backend API: http://localhost:8000/docs (Swagger UI)
- See individual README files in `backend/` and `frontend/` directories

