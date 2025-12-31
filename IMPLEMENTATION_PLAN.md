# NYC TLC Analytics Assignment - Implementation Plan

## Overview
Build an interactive dashboard analyzing NYC Yellow Taxi Trip Records (Jan-Apr 2025) to answer 8 analytical questions about system efficiency, driver incentives, and operational insights.

**Technical Approach**: SQL-first data processing with Python backend, emphasizing efficient SQL queries, data pipelines, and cloud-based infrastructure (AWS).

---

## Phase 1: Data Acquisition & Preparation (Hours 0-8)

### 1.1 Data Download
- **Source**: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- **Datasets Required**:
  - Yellow Taxi Trip Records: January, February, March, April 2025
  - Taxi Zone Lookup Table
- **File Format**: Parquet files (standard TLC format)
- **Estimated Size**: ~2-4 GB per month (total ~8-16 GB)

### 1.2 Data Loading & Initial Processing
- **Data Pipeline Approach**:
  - Load parquet files using Python/Pandas
  - Ingest data into SQL database (PostgreSQL, AWS RDS, or cloud warehouse like BigQuery/Redshift)
  - Create optimized database schema with proper indexes
  - Load Taxi Zone Lookup Table into database
- **SQL-Based Processing**:
  - Use SQL for data cleaning and filtering
  - Remove rows with missing critical fields using SQL WHERE clauses
  - Filter to 2025 data only (Jan-Apr) using SQL date functions
  - Create database views/materialized views for common queries

### 1.3 Data Schema Understanding
- **Key Fields to Extract**:
  - Timestamps: `tpep_pickup_datetime`, `tpep_dropoff_datetime`
  - Location: `PULocationID`, `DOLocationID` (Taxi Zone IDs)
  - Trip Metrics: `trip_distance`, `trip_duration` (derived)
  - Fare Components: `fare_amount`, `tip_amount`, `total_amount`, `extra`, `mta_tax`, `tolls_amount`
  - Payment: `payment_type`, `RatecodeID`
  - Passenger: `passenger_count`
  - Vendor: `VendorID`

---

## Phase 2: Metric Derivation (Hours 8-16)

### 2.1 SQL-Based Metric Calculation

**Approach**: Use SQL for efficient metric calculations and aggregations

#### A. Trip Duration
- **SQL Calculation**: Use SQL date functions to calculate duration
  ```sql
  SELECT 
    *,
    EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60 AS trip_duration_minutes
  FROM trips
  WHERE tpep_dropoff_datetime > tpep_pickup_datetime
  ```
- Filter out invalid durations (negative or zero) using SQL WHERE clause

#### B. Idle Time (Critical Assumption)
- **Assumption**: Idle time = time between dropoff of previous trip and pickup of next trip for same vehicle
- **Challenge**: No explicit vehicle/driver ID in dataset
- **Approach**: 
  - Option 1: Use spatiotemporal clustering (dropoff location/time → next pickup nearby)
  - Option 2: Use zone-level idle time (average time between dropoff in zone X and next pickup in zone X)
  - Option 3: Use system-wide idle time distribution
- **Recommendation**: Zone-level idle time with temporal windows (e.g., within 30 min, within 5 km)

#### C. Empty Return Probability
- **Definition**: Probability that a trip from Zone A to Zone B is followed by an empty return to Zone A
- **Calculation**: 
  - For each (origin, destination) pair, calculate % of trips where next trip originates from destination back to origin
  - Use time windows (e.g., within 2 hours)
- **Alternative**: Zone-level return probability (any trip from B back to A)

#### D. System Efficiency Metrics
- **SQL-Based Calculations**:
  - **Throughput**: `SELECT zone, COUNT(*) / COUNT(DISTINCT DATE_TRUNC('hour', pickup_time)) AS trips_per_hour FROM trips GROUP BY zone`
  - **Congestion Index**: `SELECT zone, AVG(duration) / NULLIF(AVG(distance), 0) AS congestion_index FROM trips GROUP BY zone`
  - **Productivity**: Calculate revenue per hour using SQL aggregations with window functions
  - **Utilization Rate**: Use SQL to calculate active time vs total time (including idle)

#### E. Demand & Supply Metrics
- **SQL-Based Calculations**:
  - **Demand**: `SELECT pulocationid, DATE_TRUNC('hour', tpep_pickup_datetime) AS hour, COUNT(*) AS demand FROM trips GROUP BY pulocationid, hour`
  - **Supply**: `SELECT dolocationid, DATE_TRUNC('hour', tpep_dropoff_datetime) AS hour, COUNT(*) AS supply FROM trips GROUP BY dolocationid, hour`
  - **Wait Time Proxy**: Join demand and supply tables, calculate ratio using SQL
  - **Surge Indicator**: Use SQL window functions to calculate base fare and detect surge: `CASE WHEN fare_amount > (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fare_amount) * 1.2) THEN 1 ELSE 0 END`

#### F. Variability Metrics
- **SQL-Based Calculations**:
  - **Trip Duration Variability**: Use SQL window functions and aggregations: `STDDEV(duration) / AVG(duration) AS cv`
  - **Distance Bins**: Use SQL CASE statements: `CASE WHEN distance < 2 THEN '0-2' WHEN distance < 5 THEN '2-5' ... END AS distance_bin`
  - Group by distance bins and calculate coefficient of variation using SQL aggregations

### 2.2 SQL Query Optimization
- **Indexing Strategy**: Create indexes on frequently queried columns (pickup/dropoff times, location IDs)
- **Query Optimization**: 
  - Use EXPLAIN ANALYZE to optimize slow queries
  - Leverage materialized views for pre-computed aggregations
  - Use appropriate JOIN strategies (INNER, LEFT, etc.)
  - Optimize window functions and subqueries
- **Data Modeling**:
  - Design normalized schema for efficient queries
  - Create denormalized views for dashboard queries
  - Use partitioning for large tables (by date/month)

---

## Phase 3: Dashboard Development (Hours 16-40)

### Phase 3 Breakdown:
- **Hours 16-24**: Backend API development
  - Set up FastAPI application
  - Implement data processing services
  - Create API endpoints for all 8 questions
- **Hours 24-34**: Frontend React development
  - Set up React app with routing
  - Create reusable components (charts, filters)
  - Build page components for each question
  - Integrate with backend API
- **Hours 34-38**: Frontend optimization
  - Implement lazy loading for routes
  - Add memoization for chart components
  - Implement loading states and skeleton loaders
  - Optimize bundle size with code splitting
- **Hours 38-40**: Integration and testing
  - Connect frontend to backend
  - Test API endpoints
  - Fix integration issues
  - Verify optimization improvements

### 3.1 Technology Stack Selection

#### Backend (Python)
- **API Framework**: FastAPI
- **Database**: 
  - PostgreSQL (AWS RDS) or Cloud Data Warehouse (BigQuery/Redshift/Snowflake)
  - SQLAlchemy for ORM and database connections
  - psycopg2 or asyncpg for PostgreSQL connections
- **Data Processing**: 
  - **SQL-first approach**: Write efficient SQL queries for data extraction, aggregations, and analytics
  - Pandas for data manipulation when needed (post-SQL extraction)
  - PySpark for distributed processing (if using large-scale clusters)
- **Data Pipeline**: 
  - ETL pipeline to load parquet files into SQL database
  - SQL-based transformations and cleaning
  - Materialized views for pre-computed metrics
- **Storage**: 
  - SQL database for raw and processed data
  - In-memory caching for frequently accessed metrics
- **API Documentation**: Not included (removed from scope)

#### Frontend (React)
- **Framework**: React 18+ with TypeScript (recommended) or JavaScript
- **Build Tool**: Vite (recommended) or Create React App
- **UI Library**: 
  - Material-UI (MUI) or Ant Design for components
  - Tailwind CSS for styling (optional)
- **Visualization Libraries**:
  - Chart.js with react-chartjs-2 for interactive charts
  - Chart.js plugins:
    - chartjs-plugin-annotation for annotations
    - chartjs-plugin-datalabels for data labels
  - Leaflet or Mapbox GL JS for map visualizations
  - D3.js for custom visualizations (if needed)
- **State Management**: 
  - React Context API for global state management
  - React Query (TanStack Query) for API data fetching and caching
- **Routing**: React Router
- **HTTP Client**: Axios or Fetch API

#### Architecture
- **Separation**: Frontend and Backend as separate services
- **Communication**: RESTful API (JSON)
- **CORS**: Configure CORS in backend for frontend access
- **Development**: 
  - Backend: `uvicorn` or `gunicorn` for FastAPI
  - Frontend: Vite dev server
  - Proxy: Configure frontend proxy to backend during development

#### Key Libraries & Their Purpose

**Backend (Python)**:
- `fastapi`: Web framework for building APIs
- `sqlalchemy`: SQL toolkit and ORM for database operations
- `psycopg2` or `asyncpg`: PostgreSQL database adapter
- `pandas`: Data manipulation and analysis (post-SQL extraction)
- `pyspark`: Distributed data processing (if using clusters)
- `uvicorn`: ASGI server for running FastAPI
- `alembic`: Database migration tool (optional)

**Frontend (React/TypeScript)**:
- `react` + `react-dom`: Core React library with Context API for state management
- `typescript`: Type safety
- `vite`: Fast build tool and dev server
- `axios`: HTTP client for API calls
- `@tanstack/react-query`: Data fetching, caching, and synchronization
- `react-router-dom`: Client-side routing
- `chart.js` + `react-chartjs-2`: Interactive charts and visualizations
- `chartjs-plugin-annotation`: Chart annotations (lines, boxes, labels)
- `chartjs-plugin-datalabels`: Data labels on chart elements
- `@mui/material`: UI component library
- `leaflet` + `react-leaflet`: Map visualizations

### 3.2 Backend API Design

#### API Endpoints Structure

**Base URL**: `/api/v1`

**Endpoints**:

1. **Data Overview**
   - `GET /overview` - Summary statistics (total trips, date range, zones, etc.)

2. **Question 1: High Revenue Zones**
   - `GET /zones/revenue` - Revenue metrics by zone
   - `GET /zones/net-profit` - Net profit calculation (with costs)
   - `GET /zones/negative-zones` - Zones that flip to negative

3. **Question 2: Demand vs Efficiency**
   - `GET /efficiency/timeseries` - Efficiency over time
   - `GET /efficiency/heatmap` - Efficiency by hour/day
   - `GET /efficiency/demand-correlation` - Demand vs efficiency correlation

4. **Question 3: Surge Pricing**
   - `GET /surge/events` - Surge pricing events
   - `GET /surge/correlation` - Surge vs revenue correlation
   - `GET /surge/zones` - Zone-level surge analysis

5. **Question 4: Wait Time Reduction**
   - `GET /wait-time/current` - Current wait time metrics
   - `POST /wait-time/simulate` - Simulate lever impact
   - `GET /wait-time/tradeoffs` - Trade-off analysis

6. **Question 5: Congestion Analysis**
   - `GET /congestion/zones` - Congestion metrics by zone
   - `GET /congestion/throughput` - Throughput analysis
   - `GET /congestion/short-trips` - Short trip impact

7. **Question 6: Incentive Misalignment**
   - `GET /incentives/driver` - Driver incentive metrics
   - `GET /incentives/system` - System efficiency metrics
   - `GET /incentives/misalignment` - Misalignment zones/times

8. **Question 7: Duration Variability**
   - `GET /variability/heatmap` - CV by hour and distance
   - `GET /variability/distribution` - Duration distributions
   - `GET /variability/trends` - Variability trends

9. **Question 8: Minimum Distance Simulation**
   - `POST /simulation/min-distance` - Run simulation with threshold
   - `GET /simulation/results` - Get simulation results
   - `GET /simulation/sensitivity` - Sensitivity analysis

10. **Utilities**
    - `GET /zones/lookup` - Zone lookup table
    - `GET /assumptions` - Documented assumptions
    - `GET /health` - Health check

#### API Response Format
Simple JSON responses with data:
```python
{
  "data": {...},
  "assumptions": {...}  # Document assumptions for this endpoint
}
```

#### Backend Project Structure
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app entry point
│   ├── database/            # Database configuration
│   │   ├── __init__.py
│   │   ├── connection.py    # Database connection setup
│   │   ├── models.py        # SQLAlchemy models
│   │   └── schema.sql       # Database schema definitions
│   ├── pipelines/           # Data pipeline scripts
│   │   ├── __init__.py
│   │   ├── etl.py           # ETL pipeline to load parquet to SQL
│   │   └── transformations.py # SQL-based data transformations
│   ├── sql/                 # SQL query files
│   │   ├── metrics/         # SQL queries for metrics
│   │   │   ├── idle_time.sql
│   │   │   ├── empty_returns.sql
│   │   │   ├── efficiency.sql
│   │   │   └── ...
│   │   └── views/           # SQL views and materialized views
│   │       ├── zone_metrics.sql
│   │       └── time_series.sql
│   ├── api/                 # API routes
│   │   ├── __init__.py
│   │   ├── overview.py
│   │   ├── zones.py
│   │   ├── efficiency.py
│   │   ├── surge.py
│   │   ├── wait_time.py
│   │   ├── congestion.py
│   │   ├── incentives.py
│   │   ├── variability.py
│   │   └── simulation.py
│   ├── services/            # Business logic
│   │   ├── db_service.py    # Database service layer
│   │   ├── sql_executor.py  # SQL query execution
│   │   ├── metrics.py       # Metric calculations (SQL + Python)
│   │   └── simulation.py
│   └── utils/               # Utilities
│       └── helpers.py
├── data/                    # Raw data storage
├── requirements.txt
├── .ebextensions/           # Elastic Beanstalk config (if using EB)
│   └── python.config
├── Dockerfile               # Docker config (if using ECS)
├── .dockerignore
└── README.md
```

### 3.3 Frontend React Application Structure

#### Frontend Project Structure
```
frontend/
├── public/
│   └── index.html
├── src/
│   ├── App.tsx              # Main app component
│   ├── main.tsx             # Entry point
│   ├── index.css
│   ├── components/          # Reusable components
│   │   ├── Layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── Footer.tsx
│   │   ├── Charts/
│   │   │   ├── MapChart.tsx          # Leaflet map component
│   │   │   ├── TimeSeriesChart.tsx   # Chart.js Line chart
│   │   │   ├── HeatmapChart.tsx      # Chart.js with custom heatmap
│   │   │   ├── ScatterChart.tsx      # Chart.js Scatter chart
│   │   │   └── BarChart.tsx          # Chart.js Bar chart
│   │   ├── Filters/
│   │   │   ├── DateRangePicker.tsx
│   │   │   ├── ZoneSelector.tsx
│   │   │   └── MetricSelector.tsx
│   │   └── Common/
│   │       ├── LoadingSpinner.tsx      # Loading spinner for API calls
│   │       ├── SkeletonLoader.tsx     # Skeleton loader for charts
│   │       ├── ErrorMessage.tsx
│   │       └── InfoCard.tsx
│   ├── pages/               # Page components
│   │   ├── Overview.tsx
│   │   ├── Question1.tsx
│   │   ├── Question2.tsx
│   │   ├── Question3.tsx
│   │   ├── Question4.tsx
│   │   ├── Question5.tsx
│   │   ├── Question6.tsx
│   │   ├── Question7.tsx
│   │   ├── Question8.tsx
│   │   └── Assumptions.tsx
│   ├── services/            # API services
│   │   ├── api.ts           # Axios instance & base config
│   │   ├── overview.ts
│   │   ├── zones.ts
│   │   ├── efficiency.ts
│   │   ├── surge.ts
│   │   ├── waitTime.ts
│   │   ├── congestion.ts
│   │   ├── incentives.ts
│   │   ├── variability.ts
│   │   └── simulation.ts
│   ├── context/             # React Context API
│   │   ├── AppContext.tsx   # Main app state (filters, selected zones, etc.)
│   │   └── FilterContext.tsx # Filter state (date range, zones, metrics)
│   ├── types/               # TypeScript types
│   │   ├── api.ts
│   │   ├── metrics.ts
│   │   └── zones.ts
│   └── utils/               # Utilities
│       ├── formatters.ts
│       └── constants.ts
├── package.json
├── tsconfig.json
├── vite.config.ts
└── README.md
```

### 3.4 Development Workflow

#### Backend Development
1. **Database Setup & Data Pipeline**:
   - Set up PostgreSQL (AWS RDS) or cloud data warehouse
   - Create database schema with optimized indexes
   - Build ETL pipeline to load parquet files into database
   - Write SQL scripts for data cleaning and transformation
   - Create materialized views for common aggregations

2. **SQL-Based Analytics**:
   - Write efficient SQL queries for metric calculations
   - Use SQL window functions for complex analytics (idle time, empty returns)
   - Create stored procedures or views for reusable calculations
   - Optimize queries with proper indexes and query plans
   - Use SQL aggregations instead of pandas groupby where possible

3. **API Development**:
   - Create route handlers for each endpoint
   - Execute SQL queries using SQLAlchemy or raw SQL
   - Implement business logic in service layer (SQL + Python)
   - Return JSON responses with data and assumptions
   - Test endpoints with curl or Postman

#### Frontend Development
1. **Setup & Configuration**:
   - Initialize React app with TypeScript
   - Set up routing (React Router)
   - Configure API client (Axios)
   - Set up React Query for data fetching
   - Create Context API providers for state management
     - AppContext: Global application state
     - FilterContext: Filter and selection state

2. **Component Development**:
   - Create reusable chart components using Chart.js
     - Configure Chart.js plugins (annotation, datalabels)
     - Create wrapper components for different chart types (Line, Bar, Scatter, etc.)
   - Build page components for each question
     - Use Context API hooks (useApp, useFilter, etc.) to access shared state
     - Use React Query hooks for API data fetching
   - Implement filters and controls
     - Connect filters to FilterContext for state management
   - Add loading and error states
     - Loading spinners for API calls
     - Skeleton loaders for charts
     - Error boundaries for error handling

3. **Frontend Optimization**:
   - **Lazy Loading**: Use React.lazy() for route-based code splitting
     - Lazy load page components (Question1, Question2, etc.)
     - Reduce initial bundle size
   - **Memoization**: Use React.memo() for expensive chart components
     - Memoize chart components to prevent unnecessary re-renders
     - Use useMemo() for computed values
   - **Code Splitting**: 
     - Split routes into separate chunks
     - Lazy load heavy libraries (Chart.js, Leaflet) if needed
   - **Performance**:
     - Optimize Chart.js rendering with proper data structures
     - Debounce filter inputs to reduce API calls
     - Use React Query caching to minimize redundant requests

4. **Integration**:
   - Connect components to API endpoints
   - Handle data transformations
   - Implement interactive features

### 3.5 Dashboard Structure

#### Section 1: Executive Summary
- Key metrics overview
- Data coverage summary (date range, record count, zones covered)
- Assumptions documentation panel

#### Section 2: Question 1 - High Revenue Zones with Hidden Costs
- **Visualizations**:
  - Map: Revenue by pickup zone (heatmap)
  - Bar Chart: Top 20 zones by revenue
  - Scatter Plot: Revenue vs. Net Profit (after idle time, duration, empty returns)
  - Table: Zones that flip from positive to negative
- **Metrics**:
  - Gross Revenue per zone
  - Net Revenue = Gross Revenue - (Idle Time Cost + Duration Cost + Empty Return Cost)
  - Cost assumptions clearly stated

#### Section 3: Question 2 - Demand vs. Efficiency Trade-offs
- **Visualizations**:
  - Time Series: Total trips vs. System efficiency over hours/days
  - Heatmap: Efficiency by hour of day and day of week
  - Scatter: Demand (trips) vs. Efficiency metric
- **Metrics**:
  - System Efficiency = Total Revenue / Total Vehicle Hours (including idle)
  - Identify inflection points where efficiency decreases despite trip increase

#### Section 4: Question 3 - Surge Pricing Paradox
- **Visualizations**:
  - Time Series: Surge pricing events by zone
  - Scatter: Surge frequency vs. Daily revenue
  - Case Study: Deep dive into specific zones
- **Metrics**:
  - Surge Detection: (fare_amount - base_fare) / base_fare > threshold
  - Correlation analysis: Surge events vs. total daily revenue

#### Section 5: Question 4 - Wait Time Reduction Levers
- **Visualizations**:
  - Analysis of two proposed levers
  - Before/After simulation
  - Trade-off matrix
- **Proposed Levers** (to be validated with data):
  1. **Lever 1**: Optimize vehicle distribution (move vehicles from low-demand to high-demand zones)
  2. **Lever 2**: Reduce minimum trip distance (encourage shorter trips, faster turnover)
- **Trade-offs**: Document what worsens (e.g., driver earnings, congestion, etc.)

#### Section 6: Question 5 - High Trip, High Congestion Zones
- **Visualizations**:
  - Map: Trip count by zone
  - Map: Congestion index by zone
  - Scatter: Trips vs. Congestion Index
  - Bar Chart: Zones with high trips but low throughput
- **Metrics**:
  - Congestion Index = Avg Duration / Avg Distance
  - Throughput = Trips / (Avg Duration + Idle Time)
  - Productivity Distortion = Short trips (< 1 mile) impact on metrics

#### Section 7: Question 6 - Driver Incentive Misalignment
- **Visualizations**:
  - Driver perspective: Revenue per hour by zone/time
  - System perspective: System efficiency by zone/time
  - Misalignment heatmap
  - Case studies
- **Metrics**:
  - Driver Incentive Score = (Fare + Tip) / Trip Duration
  - System Efficiency Score = Total Revenue / Total System Time
  - Misalignment = Zones/times where driver incentives high but system efficiency low

#### Section 8: Question 7 - Trip Duration Variability
- **Visualizations**:
  - Heatmap: Coefficient of variation by hour of day and distance bin
  - Box plots: Duration distribution by hour
  - Time series: Variability trends
- **Metrics**:
  - CV (Coefficient of Variation) = Std(Duration) / Mean(Duration) for similar distances
  - Distance bins: 0-2, 2-5, 5-10, 10+ miles

#### Section 9: Question 8 - Minimum Distance Threshold Simulation
- **Visualizations**:
  - Before/After comparison charts
  - Impact on multiple metrics
  - Sensitivity analysis
- **Simulation**:
  - Remove trips below threshold (e.g., 0.5, 1.0, 1.5 miles)
  - Measure impact on:
    - Total trips
    - Average wait time
    - System revenue
    - Driver utilization
    - Congestion
  - Document assumptions and fragility

#### Section 10: Assumptions & Methodology
- Detailed documentation of all assumptions
- Data limitations
- Methodology for derived metrics
- Sensitivity analysis notes

---

## Phase 4: Analysis & Insights (Hours 40-60)

### 4.1 Question-by-Question Analysis

#### Q1: High Revenue → Net Negative Zones
- Calculate zone-level metrics
- Apply cost factors (idle time, duration, empty returns)
- Identify zones that flip
- Validate with case studies

#### Q2: Demand vs. Efficiency
- Calculate efficiency metrics by time period
- Identify periods where trips ↑ but efficiency ↓
- Analyze root causes (congestion, idle time spikes, etc.)

#### Q3: Surge Pricing Paradox
- Detect surge events (statistical method)
- Calculate correlation with daily revenue
- Identify zones with negative correlation
- Explain mechanism (demand destruction, driver behavior, etc.)

#### Q4: Wait Time Reduction
- Analyze current wait time proxies
- Test two levers with data
- Quantify trade-offs
- Provide recommendations

#### Q5: Congestion vs. Throughput
- Calculate congestion and throughput metrics
- Identify high-trip, high-congestion zones
- Show how short trips distort metrics
- Provide corrected productivity view

#### Q6: Incentive Misalignment
- Calculate driver and system metrics
- Identify misalignment zones/times
- Explain mechanism (e.g., drivers chase surges, leaving other areas underserved)

#### Q7: Duration Variability
- Calculate CV by hour and distance
- Identify high-variability periods
- Link to predictability and rider experience
- Suggest implications

#### Q8: Minimum Distance Simulation
- Run simulation with multiple thresholds
- Measure multi-dimensional impact
- Identify non-intuitive effects
- Document assumptions and fragility

---

## Phase 5: Dashboard Refinement & Documentation (Hours 60-72)

### Phase 5 Breakdown:
- **Hours 60-64**: Dashboard polish and testing
- **Hours 64-68**: AWS backend deployment setup and deployment
- **Hours 68-70**: Frontend deployment and integration testing
- **Hours 70-72**: Final testing, documentation, and link generation

### 5.1 Dashboard Polish
- Ensure all visualizations are interactive
- Add filters (date range, zone selection, etc.)
- Improve UI/UX
- Add tooltips and explanations
- Verify loading states work correctly (spinners, skeleton loaders)
- Test lazy loading performance (check bundle sizes, load times)
- Verify memoization prevents unnecessary re-renders

### 5.2 Documentation
- Assumptions panel (prominent) - clearly document all assumptions
- Brief methodology notes for key metrics

### 5.3 Testing
- Verify all calculations work correctly
- Test dashboard interactivity
- Ensure API endpoints return expected data

### 5.4 Deployment

**Database Deployment Strategy**: The project uses **SQLite** by default (`sqlite:///./nyc_taxi.db`), which is the **recommended deployment path** for this project. SQLite provides a simple, self-contained database that works well for this analytics dashboard.

**Important**: The database file (`nyc_taxi.db`) is too large to commit to git (excluded in `.gitignore`). The database will be **generated on the server** during deployment using the ETL pipeline. This is the recommended approach.

#### Deployment Architecture

**Backend (AWS)**
- **Option 1: AWS Elastic Beanstalk (Recommended for simplicity)**
  - Deploy FastAPI application to Elastic Beanstalk
  - Automatic scaling and load balancing
  - Easy environment configuration
  - Supports Python applications out of the box
- **Option 2: AWS EC2**
  - Launch EC2 instance (t2.micro or t3.small for cost-effective)
  - Install Python, FastAPI, and dependencies
  - Use systemd or PM2 to run uvicorn as a service
  - Configure security groups for API access
- **Option 3: AWS ECS/Fargate (Containerized)**
  - Containerize FastAPI app with Docker
  - Deploy to ECS Fargate for serverless containers
  - Use Application Load Balancer for routing
- **Database: SQLite (Recommended)**
  - Project uses SQLite by default (`sqlite:///./nyc_taxi.db`)
  - **Database Generation**: Database file is generated on server during deployment (too large for git)
  - **Advantages**: 
    - Simple deployment - no separate database service needed
    - Works out of the box with current codebase
    - No additional AWS service costs
    - Self-contained and portable
  - **Deployment Methods** (choose one):
    - **Method 1: ETL on Server (Recommended)**: Run ETL pipeline after deployment to generate database
    - **Method 2: S3 Storage**: Upload database file to S3, download during deployment (faster, requires pre-built database)
  - **Deployment Notes**:
    - Database file must be on persistent storage (EBS volume) for EC2/Elastic Beanstalk
    - Parquet data files must be accessible (included in deployment or stored in S3)
    - SQLite handles read-heavy analytics workloads well for this use case
  - **Optional: PostgreSQL/RDS** (if needed for multi-instance scaling or high concurrency)
- **Additional AWS Services**:
  - **S3**: Store raw parquet files and processed data
  - **CloudWatch**: Monitor API logs, database performance, and query execution times
  - **Route 53**: Domain name configuration (optional)

**Frontend**
- Build React app (`npm run build`)
- Deploy to Vercel, Netlify, or AWS S3 + CloudFront
- Configure API endpoint (AWS backend URL) in frontend environment variables

#### AWS Backend Setup Steps
1. **Prepare for Deployment**:
   - **IMPORTANT: Remove large files from git history** (if already committed):
     ```bash
     # Remove database file from git history
     git rm --cached backend/nyc_taxi.db
     git commit -m "Remove database file from git (too large)"
     
     # If file is in git history, remove it completely:
     git filter-branch --force --index-filter "git rm --cached --ignore-unmatch backend/nyc_taxi.db" --prune-empty --tag-name-filter cat -- --all
     # Or use git-filter-repo (recommended):
     # pip install git-filter-repo
     # git filter-repo --path backend/nyc_taxi.db --invert-paths
     ```
   - Create `requirements.txt` with all dependencies
   - Create `.ebextensions` config (for Elastic Beanstalk) or Dockerfile (for ECS)
   - Configure CORS in FastAPI to allow frontend domain
   - **Handle large files** (database and parquet files excluded from git):
     - **Option A**: Include `data/` folder with parquet files in deployment package (zip/tar separately, don't commit to git)
     - **Option B**: Upload parquet files to S3 and configure ETL to download from S3
     - **Option C**: Upload pre-built database to S3 and download during deployment

2. **Deploy to AWS Elastic Beanstalk**:
   ```bash
   # Install EB CLI
   pip install awsebcli
   
   # Initialize EB
   eb init -p python-3.11 nyc-taxi-api
   
   # Create environment
   eb create nyc-taxi-api-env
   
   # Deploy
   eb deploy
   ```

3. **Deploy to AWS EC2**:
   ```bash
   # SSH into EC2 instance
   # Clone repository
   # Set up virtual environment
   # Install dependencies
   # Run with: uvicorn app.main:app --host 0.0.0.0 --port 8000
   # Use systemd service or PM2 for process management
   ```

4. **Database Configuration (SQLite)**:

   **Method 1: Generate Database on Server (Recommended)**
   
   Since the database file is too large for git, generate it on the server:
   
   a. **Include parquet data files in deployment** (parquet files are also excluded from git):
      - **Option A: Include in deployment package** (recommended for simplicity):
        - Parquet files are in `data/` folder (excluded from git via `.gitignore`)
        - When deploying, manually include `data/` folder in deployment package
        - For EC2: Copy `data/` folder to server via SCP or include in deployment script
        - For Elastic Beanstalk: Add `data/` folder to deployment zip (exclude from git but include in zip)
        - For ECS: Copy `data/` folder into Docker image or mount as volume
      - **Option B: Store in S3**:
        - Upload parquet files to S3 bucket
        - Modify ETL to download from S3 before processing
        - Configure IAM permissions for S3 access
   
   b. **Run ETL after deployment**:
      ```bash
      # SSH into EC2 instance
      cd /path/to/app
      source venv/bin/activate  # or activate virtual environment
      python run_etl.py
      ```
   
   c. **For Elastic Beanstalk**: Add post-deployment hook in `.ebextensions`:
      ```yaml
      # .ebextensions/01_run_etl.config
      container_commands:
        01_run_etl:
          command: "cd /var/app/current && python run_etl.py"
          leader_only: true
      ```
   
   d. **For ECS/Fargate**: Add ETL step in Dockerfile or use init container
   
   **Method 2: Pre-built Database from S3 (Faster Deployment)**
   
   If you have a pre-built database file:
   
   a. **Upload database to S3** (one-time):
      ```bash
      aws s3 cp nyc_taxi.db s3://your-bucket/database/nyc_taxi.db
      ```
   
   b. **Download during deployment**:
      - For EC2: Add download script in user-data or deployment script
      - For Elastic Beanstalk: Add to `.ebextensions`:
        ```yaml
        # .ebextensions/02_download_db.config
        files:
          "/opt/elasticbeanstalk/hooks/appdeploy/post/99_download_db.sh":
            mode: "000755"
            content: |
              #!/bin/bash
              aws s3 cp s3://your-bucket/database/nyc_taxi.db /var/app/current/nyc_taxi.db
        ```
   
   **Environment Configuration**:
   - **Environment variables**: 
     - Leave `DATABASE_URL` unset to use default SQLite path, OR
     - Set `DATABASE_URL=sqlite:///./nyc_taxi.db` explicitly
   - **Data files path**: 
     - Set `DATA_DIR` environment variable if parquet files are in non-standard location
     - Default: `../data` (relative to backend directory)
   - **Persistent storage**: 
     - For EC2: Mount EBS volume and store database file there
     - For Elastic Beanstalk: Use `.ebextensions` to configure persistent storage
     - For ECS/Fargate: Use EFS (Elastic File System) for persistent storage
   - **S3 Access** (if using Method 2 or S3 for parquet files):
     - Configure IAM role with S3 read permissions
     - Set AWS credentials or use instance role

5. **Environment Configuration**:
   - Set environment variables in AWS (Elastic Beanstalk environment or EC2)
   - Configure security groups to allow HTTP/HTTPS traffic
   - Set up SSL certificate (optional, using AWS Certificate Manager)

#### Troubleshooting: Large Files in Git

**Problem**: Database file or parquet files committed to git, causing push failures.

**Solution**:
1. **Remove from git tracking** (if file is staged but not committed):
   ```bash
   git rm --cached backend/nyc_taxi.db
   git commit -m "Remove database file from git"
   ```

2. **Remove from git history** (if file is already in commits):
   ```bash
   # Option 1: Using git filter-branch (built-in)
   git filter-branch --force --index-filter "git rm --cached --ignore-unmatch backend/nyc_taxi.db" --prune-empty --tag-name-filter cat -- --all
   
   # Option 2: Using git-filter-repo (recommended, faster)
   pip install git-filter-repo
   git filter-repo --path backend/nyc_taxi.db --invert-paths
   
   # After removing from history, force push (WARNING: rewrites history)
   git push origin --force --all
   ```

3. **Verify `.gitignore` includes**:
   - `*.db`, `*.sqlite`, `*.sqlite3` (database files)
   - `data/*.parquet` (parquet files)

4. **For deployment**: Include parquet files in deployment package manually (not via git)

#### Deployment Checklist

**Database Setup (SQLite)**:
- [ ] **Choose deployment method**: ETL on server (Method 1) OR Pre-built from S3 (Method 2)
- [ ] **For Method 1 (ETL on Server)**:
  - [ ] Parquet data files included in deployment package OR stored in S3
  - [ ] ETL script configured to access data files (check `DATA_DIR` path)
  - [ ] Post-deployment hook configured to run ETL (for Elastic Beanstalk/ECS)
  - [ ] ETL pipeline tested and run after deployment
- [ ] **For Method 2 (S3 Pre-built)**:
  - [ ] Database file uploaded to S3 bucket
  - [ ] Download script configured in deployment process
  - [ ] IAM permissions configured for S3 access
  - [ ] Database file downloaded to persistent storage location
- [ ] Persistent storage (EBS volume/EFS) configured for database file
- [ ] DATABASE_URL environment variable configured (or left unset for default SQLite path)
- [ ] DATA_DIR environment variable set (if parquet files in non-standard location)
- [ ] Database file verified to exist and be accessible after deployment

**Backend Deployment**:
- [ ] AWS account set up and configured
- [ ] SQL queries tested and optimized (with current database)
- [ ] Backend deployed to AWS (Elastic Beanstalk/EC2/ECS)
- [ ] Database connection configured in backend
- [ ] Backend API accessible and health check working
- [ ] CORS configured correctly in FastAPI for frontend domain
- [ ] Security groups configured to allow API access (and database access if using RDS)
- [ ] Environment variables set in AWS (including DATABASE_URL if needed)

**Frontend Deployment**:
- [ ] Frontend built and deployed
- [ ] API endpoint (AWS backend URL) configured in frontend
- [ ] Dashboard fully functional
- [ ] Shareable link generated

---

## Key Assumptions to Document

### Critical Assumptions:
1. **Idle Time Calculation**: 
   - Method: Zone-level temporal clustering
   - Time window: 30 minutes
   - Spatial window: Same zone or adjacent zones
   - Cost: $X per hour of idle time

2. **Empty Return Probability**:
   - Time window: 2 hours
   - Definition: Return trip from destination to origin
   - Cost: Full trip cost (fuel + time)

3. **Wait Time Proxy**:
   - Formula: Demand/Supply ratio
   - Calibration: May not reflect actual wait times

4. **Surge Detection**:
   - Threshold: 20% above base fare
   - Base fare: Median fare for similar distance/time

5. **Vehicle Assignment**:
   - No explicit vehicle ID → use spatiotemporal inference
   - May introduce errors in idle time calculation

6. **Minimum Distance Simulation**:
   - Assumes removed trips don't affect remaining trips
   - No behavioral changes modeled
   - Static system assumption

---

## Risk Mitigation

### Data Risks:
- **Large file sizes**: Use efficient processing (Polars if needed, chunking)
- **Missing data**: Filter out rows with missing critical fields

### Technical Risks:
- **Dashboard performance**: 
  - Backend: Cache processed metrics in memory
  - Frontend: Implement lazy loading, code splitting, and memoization
- **API integration**: Test frontend-backend communication early
- **Deployment issues**: 
  - Test AWS deployment process early
  - Ensure CORS configured correctly in FastAPI
  - Configure AWS security groups properly
  - Test API accessibility from frontend domain
  - Monitor AWS costs (use t2.micro/t3.small for cost-effective testing)
- **Large dataset handling**: 
  - Use efficient data processing (Polars if needed)
  - Pre-compute and cache metrics
- **Frontend loading performance**:
  - Implement loading states and skeleton loaders
  - Use React Query for efficient data fetching and caching
  - Optimize bundle size with code splitting

### Analytical Risks:
- **Assumption sensitivity**: Document clearly, provide sensitivity analysis
- **Methodology questions**: Be transparent, explain rationale
- **Non-intuitive findings**: Validate, provide explanations

---

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Phase 1: Data Acquisition | 8 hours | Loaded and filtered dataset |
| Phase 2: Metric Derivation | 8 hours | All derived metrics calculated |
| Phase 3: Dashboard Development | 24 hours | Backend API + React frontend with all sections |
| Phase 4: Analysis & Insights | 20 hours | Answers to all 8 questions |
| Phase 5: Refinement & Deployment | 12 hours | Polished dashboard, deployed and shared |
| **Total** | **72 hours** | **Complete assignment** |

---

## Success Criteria

✅ All 8 questions answered with data-driven insights  
✅ Interactive dashboard deployed and accessible  
✅ Clear documentation of assumptions and methodology  
✅ Visualizations are clear, informative, and interactive  
✅ Findings are non-obvious and demonstrate analytical depth  
✅ Ready for discussion in next interview round  

---

## Development Environment Setup

### Backend Setup (Python)
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install fastapi uvicorn sqlalchemy psycopg2-binary pandas numpy pyarrow
# For cloud warehouses (optional):
# pip install google-cloud-bigquery  # For BigQuery
# pip install snowflake-connector-python  # For Snowflake
# pip install pyspark  # For distributed processing

# Run development server
cd backend
uvicorn app.main:app --reload --port 8000
```

### Database Setup
**Option 1: PostgreSQL (AWS RDS)**
```bash
# Set up AWS RDS PostgreSQL instance
# Configure connection string in environment variables:
# DATABASE_URL=postgresql://user:password@host:5432/dbname
```

**Option 2: Cloud Data Warehouse**
- **BigQuery**: Set up GCP project and BigQuery dataset
- **Redshift**: Set up AWS Redshift cluster
- **Snowflake**: Set up Snowflake account and warehouse

**Database Schema Creation**:
```sql
-- Example: Create trips table
CREATE TABLE trips (
    id SERIAL PRIMARY KEY,
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    pulocationid INTEGER,
    dolocationid INTEGER,
    trip_distance FLOAT,
    fare_amount FLOAT,
    tip_amount FLOAT,
    total_amount FLOAT,
    -- ... other fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_pickup_datetime ON trips(tpep_pickup_datetime);
CREATE INDEX idx_pulocationid ON trips(pulocationid);
CREATE INDEX idx_dolocationid ON trips(dolocationid);
```

### ETL Pipeline Setup
```python
# app/pipelines/etl.py
import pandas as pd
from sqlalchemy import create_engine
from pathlib import Path

def load_parquet_to_sql(data_dir: str, db_url: str):
    """ETL pipeline to load parquet files into SQL database"""
    engine = create_engine(db_url)
    
    # Load parquet files
    files = [
        "yellow_tripdata_2025-01.parquet",
        "yellow_tripdata_2025-02.parquet",
        "yellow_tripdata_2025-03.parquet",
        "yellow_tripdata_2025-04.parquet",
    ]
    
    for file in files:
        df = pd.read_parquet(Path(data_dir) / file)
        # Clean and transform
        df = df.dropna(subset=['tpep_pickup_datetime', 'tpep_dropoff_datetime', 
                               'PULocationID', 'DOLocationID'])
        # Load to database
        df.to_sql('trips', engine, if_exists='append', index=False, method='multi')
```

### AWS Preparation (for Backend Deployment)
```bash
# Install AWS CLI (if not already installed)
# Windows: Download from AWS website
# Mac/Linux: brew install awscli or pip install awscli

# Install Elastic Beanstalk CLI (for EB deployment option)
pip install awsebcli

# Configure AWS credentials
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region (e.g., us-east-1), Output format (json)

# Create requirements.txt for deployment
pip freeze > requirements.txt
```

**AWS Account Setup**:
- Create AWS account (if not already have one)
- Set up IAM user with appropriate permissions (Elastic Beanstalk, EC2, or ECS)
- Note: AWS Free Tier available for first 12 months (t2.micro EC2, etc.)

### Frontend Setup (React)
```bash
# Create React app with Vite
npm create vite@latest frontend -- --template react-ts
cd frontend

# Install dependencies
npm install
npm install axios @tanstack/react-query
npm install chart.js react-chartjs-2
npm install chartjs-plugin-annotation chartjs-plugin-datalabels
npm install @mui/material @emotion/react @emotion/styled
npm install react-router-dom
npm install leaflet react-leaflet  # For maps

# Run development server
npm run dev
```

#### Chart.js Configuration
Create a Chart.js configuration file to register plugins:
```typescript
// src/utils/chartConfig.ts
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from 'chart.js';
import annotationPlugin from 'chartjs-plugin-annotation';
import datalabelsPlugin from 'chartjs-plugin-datalabels';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  annotationPlugin,
  datalabelsPlugin
);
```
Import this configuration in your main app file or chart components.

**Chart.js Plugin Benefits**:
- **chartjs-plugin-annotation**: Add threshold lines, boxes, and labels to highlight key insights (e.g., efficiency thresholds, surge pricing levels)
- **chartjs-plugin-datalabels**: Display data values directly on chart elements for better readability

#### Context API Setup
Create Context providers for state management:
```typescript
// src/context/AppContext.tsx
import { createContext, useContext, useState, ReactNode } from 'react';

interface AppState {
  selectedZones: number[];
  dateRange: { start: Date; end: Date };
  // ... other global state
}

const AppContext = createContext<AppState | undefined>(undefined);

export const AppProvider = ({ children }: { children: ReactNode }) => {
  const [state, setState] = useState<AppState>({
    selectedZones: [],
    dateRange: { start: new Date('2025-01-01'), end: new Date('2025-04-30') },
  });

  return (
    <AppContext.Provider value={{ ...state, setState }}>
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within AppProvider');
  return context;
};
```

Wrap your app with context providers in `App.tsx`:
```typescript
<AppProvider>
  <FilterProvider>
    {/* Your app components */}
  </FilterProvider>
</AppProvider>
```

**Context API Usage Strategy**:
- **AppContext**: Global application state (selected zones, date range, preferences)
- **FilterContext**: Filter and selection state shared across components
- **React Query**: Server state (API responses, data fetching, caching)

#### Lazy Loading & Code Splitting Setup
Implement lazy loading for routes to optimize initial bundle size:
```typescript
// src/App.tsx
import { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LoadingSpinner from './components/Common/LoadingSpinner';

// Lazy load page components
const Overview = lazy(() => import('./pages/Overview'));
const Question1 = lazy(() => import('./pages/Question1'));
const Question2 = lazy(() => import('./pages/Question2'));
// ... other questions

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<LoadingSpinner />}>
        <Routes>
          <Route path="/" element={<Overview />} />
          <Route path="/question1" element={<Question1 />} />
          <Route path="/question2" element={<Question2 />} />
          {/* ... other routes */}
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}
```

**Optimization Benefits**:
- **Lazy Loading**: Each route loads only when needed, reducing initial bundle size
- **Code Splitting**: Automatic code splitting with React.lazy() and Suspense
- **Loading States**: Suspense fallback provides loading UI during code splitting
- **Memoization**: Use React.memo() for chart components to prevent unnecessary re-renders

### Project Structure
```
syntasa-analytics/
├── backend/          # Python FastAPI backend
├── frontend/         # React TypeScript frontend
├── data/             # Raw data files
└── README.md         # Project documentation
```

---

## Next Steps

1. **Approve this plan** (or suggest modifications)
2. **Set up development environment**:
   - Python 3.9+ with virtual environment
   - Node.js 18+ and npm
   - Code editor (VS Code recommended)
3. **Begin Phase 1**: Download and prepare data
4. **Set up project structure**: Create backend and frontend folders
5. **Iterate**: Build API endpoints and React components incrementally
6. **Test integration**: Ensure frontend-backend communication works
7. **Final review**: Ensure all questions addressed, assumptions documented


