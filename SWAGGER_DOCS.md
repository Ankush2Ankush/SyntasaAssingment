# Swagger UI Documentation

## Accessing Swagger UI

FastAPI automatically generates interactive API documentation using Swagger UI. This provides a web-based interface to explore and test all API endpoints.

## Prerequisites

1. **Backend server must be running**
   - The backend API server should be started on port 8000
   - See `README.md` for instructions on starting the backend

## How to Access Swagger UI

### Step 1: Start the Backend Server

Navigate to the backend directory and start the server:

```bash
cd backend
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install dependencies (if not already done)
pip install -r requirements.txt

# Start the server
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Step 2: Open Swagger UI in Browser

Once the server is running, open your web browser and navigate to:

**Swagger UI (Interactive):**
```
http://localhost:8000/docs
```

**Alternative ReDoc (Alternative Documentation):**
```
http://localhost:8000/redoc
```

**OpenAPI JSON Schema:**
```
http://localhost:8000/openapi.json
```

## Using Swagger UI

### Features

1. **Browse All Endpoints**
   - All API endpoints are organized by tags (Overview, Zones, Efficiency, etc.)
   - Expand each endpoint to see details

2. **View Request/Response Schemas**
   - Click on any endpoint to see:
     - Request parameters
     - Request body structure
     - Response structure
     - Example values

3. **Test API Endpoints**
   - Click "Try it out" button on any endpoint
   - Enter parameter values
   - Click "Execute" to send a request
   - View the response directly in the browser

4. **Authentication** (if needed)
   - Use the "Authorize" button at the top to add authentication tokens

### Example: Testing an Endpoint

1. Navigate to `http://localhost:8000/docs`
2. Find the endpoint you want to test (e.g., `GET /api/v1/overview`)
3. Click on the endpoint to expand it
4. Click the "Try it out" button
5. Click "Execute"
6. View the response in the "Responses" section

### Available API Endpoints

The Swagger UI will show all available endpoints organized by category:

- **Overview**: `/api/v1/overview`
- **Zones**: 
  - `/api/v1/zones/revenue`
  - `/api/v1/zones/net-profit`
  - `/api/v1/zones/negative-zones`
- **Efficiency**:
  - `/api/v1/efficiency/timeseries`
  - `/api/v1/efficiency/heatmap`
  - `/api/v1/efficiency/demand-correlation`
- **Surge Pricing**:
  - `/api/v1/surge/events`
  - `/api/v1/surge/correlation`
  - `/api/v1/surge/zones`
- **Wait Time**: `/api/v1/wait-time/current`
- **Congestion**:
  - `/api/v1/congestion/zones`
  - `/api/v1/congestion/throughput`
  - `/api/v1/congestion/short-trip-impact`
- **Incentives**:
  - `/api/v1/incentives/driver`
  - `/api/v1/incentives/system`
  - `/api/v1/incentives/misalignment`
- **Variability**:
  - `/api/v1/variability/heatmap`
  - `/api/v1/variability/distribution`
  - `/api/v1/variability/trends`
- **Simulation**:
  - `/api/v1/simulation/min-distance`
  - `/api/v1/simulation/sensitivity`

## Troubleshooting

### Swagger UI Not Loading

1. **Check if server is running:**
   ```bash
   curl http://localhost:8000/health
   ```
   Should return: `{"status":"healthy"}`

2. **Check if port 8000 is accessible:**
   ```bash
   # Windows PowerShell
   netstat -ano | findstr ":8000"
   
   # Linux/Mac
   lsof -i :8000
   ```

3. **Verify backend is started correctly:**
   - Check terminal for any error messages
   - Ensure all dependencies are installed
   - Verify database connection is working

### Common Issues

- **"Connection refused"**: Backend server is not running
- **"404 Not Found"**: Wrong URL - use `/docs` not `/swagger`
- **CORS errors**: Check CORS configuration in `backend/app/main.py`

## Additional Resources

- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Swagger UI Documentation**: https://swagger.io/tools/swagger-ui/
- **OpenAPI Specification**: https://swagger.io/specification/

## Quick Reference

| Resource | URL |
|----------|-----|
| Swagger UI | http://localhost:8000/docs |
| ReDoc | http://localhost:8000/redoc |
| OpenAPI JSON | http://localhost:8000/openapi.json |
| API Root | http://localhost:8000/ |
| Health Check | http://localhost:8000/health |

