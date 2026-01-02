# Test Checklist for NYC TLC Analytics Dashboard

## Status Overview

### ✅ Completed Tests
- Backend server health check
- Swagger documentation removed
- Questions 1, 2, 3, 8: Full implementation (backend + frontend)

### ⚠️ Needs Testing/Fixing

## 1. Backend API Endpoint Tests

### Question 1: High Revenue Zones ✅
- [x] `GET /api/v1/zones/revenue` - Tested
- [x] `GET /api/v1/zones/net-profit` - Tested
- [x] `GET /api/v1/zones/negative-zones` - Tested

### Question 2: Demand vs Efficiency ✅
- [x] `GET /api/v1/efficiency/timeseries` - Tested (was empty, fixed)
- [x] `GET /api/v1/efficiency/heatmap` - Tested
- [x] `GET /api/v1/efficiency/demand-correlation` - Needs testing

### Question 3: Surge Pricing ✅
- [ ] `GET /api/v1/surge/events` - **Needs SQLite compatibility check**
- [ ] `GET /api/v1/surge/correlation` - **Needs SQLite compatibility check**
- [ ] `GET /api/v1/surge/zones` - **Needs SQLite compatibility check**

### Question 4: Wait Time Reduction ⚠️
- [ ] `GET /api/v1/wait-time/current` - **CRITICAL: Uses PostgreSQL syntax (DATE_TRUNC, FULL OUTER JOIN)**
- [ ] `POST /api/v1/wait-time/simulate` - Placeholder, needs implementation
- [x] `GET /api/v1/wait-time/tradeoffs` - Static data, should work

### Question 5: Congestion Analysis ⚠️
- [ ] `GET /api/v1/congestion/zones` - **CRITICAL: Uses EXTRACT(EPOCH FROM ...) - needs SQLite compatibility**
- [ ] `GET /api/v1/congestion/throughput` - **CRITICAL: Uses EXTRACT(EPOCH FROM ...) - needs SQLite compatibility**
- [ ] `GET /api/v1/congestion/short-trips` - **CRITICAL: Uses COUNT(*) FILTER - needs SQLite compatibility**

### Question 6: Incentive Misalignment ⚠️
- [x] `GET /api/v1/incentives/driver` - Tested (was empty, fixed)
- [x] `GET /api/v1/incentives/system` - Tested (was empty, fixed)
- [x] `GET /api/v1/incentives/misalignment` - Tested (was empty, fixed)

### Question 7: Duration Variability ✅
- [x] `GET /api/v1/variability/heatmap` - Tested (was empty, fixed)
- [x] `GET /api/v1/variability/distribution` - Tested (was empty, fixed)
- [x] `GET /api/v1/variability/trends` - Tested (was empty, fixed)

### Question 8: Minimum Distance Simulation ✅
- [x] `GET /api/v1/simulation/min-distance` - Tested (changed from POST to GET)
- [ ] `GET /api/v1/simulation/results` - Needs testing
- [ ] `GET /api/v1/simulation/sensitivity` - Needs testing

### Overview & Utilities ✅
- [x] `GET /api/v1/overview` - Tested
- [ ] `GET /api/v1/zones/lookup` - Needs testing
- [x] `GET /health` - Tested

## 2. SQL Compatibility Issues (CRITICAL)

### Files Requiring SQLite Compatibility Fixes:

#### `backend/app/api/wait_time.py`
**Issues:**
- Line 22: `DATE_TRUNC('hour', ...)` → Use `date_trunc_hour()` from `sql_compat.py`
- Line 32: `DATE_TRUNC('hour', ...)` → Use `date_trunc_hour()` from `sql_compat.py`
- Line 46: `::FLOAT` → SQLite doesn't use `::` casting, use `CAST(... AS REAL)`
- Line 50: `FULL OUTER JOIN` → SQLite doesn't support FULL OUTER JOIN, use LEFT JOIN + UNION

#### `backend/app/api/congestion.py`
**Issues:**
- Line 22: `EXTRACT(EPOCH FROM ...)` → Use `duration_minutes()` from `sql_compat.py`
- Line 25: `EXTRACT(EPOCH FROM ...)` → Use `duration_minutes()` from `sql_compat.py`
- Line 56: `EXTRACT(EPOCH FROM ...)` → Use `duration_minutes()` from `sql_compat.py`
- Line 58: `EXTRACT(EPOCH FROM ...)` → Use `duration_minutes()` from `sql_compat.py`
- Line 91: `COUNT(*) FILTER (WHERE ...)` → Use `count_filter()` from `sql_compat.py`
- Line 92: `COUNT(*) FILTER (WHERE ...)` → Use `count_filter()` from `sql_compat.py`
- Line 94: `EXTRACT(EPOCH FROM ...)` → Use `duration_minutes()` from `sql_compat.py`

#### `backend/app/api/surge.py`
**Issues:**
- Line 67: `PERCENTILE_CONT(0.5)` → Already has SQLite compatibility check, but verify
- Line 155: `PERCENTILE_CONT(0.5)` → Already has SQLite compatibility check, but verify
- Line 166: `COUNT(*) FILTER` → Use `count_filter()` from `sql_compat.py`
- Line 247: `PERCENTILE_CONT(0.5)` → Already has SQLite compatibility check, but verify
- Line 257-258: `COUNT(*) FILTER` → Use `count_filter()` from `sql_compat.py`

#### `backend/app/api/simulation.py`
**Issues:**
- Line 40-41: Mixed SQLite and PostgreSQL syntax - needs cleanup
- Line 142-144: `COUNT(*) FILTER` → Use `count_filter()` from `sql_compat.py`

## 3. Frontend Page Tests

### ✅ Working Pages
- [x] Overview page
- [x] Question 1 (High Revenue Zones) - Full charts
- [x] Question 2 (Demand vs Efficiency) - Full charts
- [x] Question 3 (Surge Pricing) - Full charts
- [x] Question 8 (Minimum Distance Simulation) - Full charts

### ⚠️ Pages Needing Visualizations
- [ ] Question 4 (Wait Time Reduction) - API needs fixing first
- [ ] Question 5 (Congestion Analysis) - API needs fixing first
- [ ] Question 6 (Incentive Misalignment) - Backend fixed, frontend may need refresh
- [ ] Question 7 (Trip Duration Variability) - Backend fixed, frontend may need refresh

### Frontend Component Tests
- [ ] All Chart.js components render correctly
- [ ] Loading states work (spinners, skeleton loaders)
- [ ] Error handling displays properly
- [ ] Lazy loading works (check Network tab for code splitting)
- [ ] React Query caching works (no duplicate API calls)
- [ ] Context API state management works

## 4. Data Validation Tests

### Database Tests
- [ ] Verify data loaded correctly (check row counts)
- [ ] Verify date range filtering works (2025-01-01 to 2025-04-30)
- [ ] Verify zone IDs are valid (check against taxi_zones table)
- [ ] Verify no NULL values in critical fields (pickup/dropoff datetime, distance, fare)

### API Response Tests
- [ ] All endpoints return valid JSON
- [ ] All endpoints include "data" and "assumptions" keys
- [ ] Response times are acceptable (< 5 seconds for complex queries)
- [ ] No SQL errors in responses
- [ ] Data types are correct (numbers, strings, dates)

## 5. Integration Tests

### Frontend-Backend Integration
- [ ] All API calls from frontend succeed
- [ ] CORS is configured correctly
- [ ] Error responses are handled gracefully
- [ ] Loading states appear during API calls
- [ ] Data displays correctly in charts

### Cross-Browser Testing
- [ ] Chrome/Edge
- [ ] Firefox
- [ ] Safari (if available)

## 6. Performance Tests

### Backend Performance
- [ ] API response times < 5 seconds
- [ ] Database queries are optimized (check execution plans)
- [ ] No memory leaks during long-running queries
- [ ] Concurrent request handling works

### Frontend Performance
- [ ] Initial page load < 3 seconds
- [ ] Chart rendering < 1 second
- [ ] Lazy loading reduces initial bundle size
- [ ] React Query caching reduces API calls

## 7. Edge Cases & Error Handling

### Backend Error Handling
- [ ] Invalid query parameters handled gracefully
- [ ] Database connection errors handled
- [ ] Empty result sets handled
- [ ] SQL syntax errors caught and logged

### Frontend Error Handling
- [ ] Network errors display user-friendly messages
- [ ] 404 errors handled
- [ ] 500 errors handled
- [ ] Empty data states handled
- [ ] Invalid data formats handled

## 8. Documentation Tests

### Code Documentation
- [ ] All API endpoints have docstrings
- [ ] Complex SQL queries have comments
- [ ] Frontend components have JSDoc comments

### User Documentation
- [ ] README files are up to date
- [ ] Setup instructions are accurate
- [ ] API endpoint documentation is clear

## Priority Order for Testing

### 🔴 CRITICAL (Must Fix Before Deployment)
1. Fix SQL compatibility issues in:
   - `wait_time.py` (Question 4)
   - `congestion.py` (Question 5)
   - `surge.py` (Question 3)
   - `simulation.py` (Question 8)

### 🟡 HIGH (Should Fix Soon)
2. Test all API endpoints return valid data
3. Implement frontend visualizations for Questions 4-7
4. Verify Question 6 and 7 frontend pages work after backend fixes

### 🟢 MEDIUM (Nice to Have)
5. Add error handling improvements
6. Performance optimization
7. Cross-browser testing

## Testing Commands

### Test Backend Endpoints
```bash
# Health check
curl http://localhost:8000/health

# Overview
curl http://localhost:8000/api/v1/overview

# Question 1
curl http://localhost:8000/api/v1/zones/revenue?limit=10
curl http://localhost:8000/api/v1/zones/net-profit

# Question 2
curl http://localhost:8000/api/v1/efficiency/timeseries
curl http://localhost:8000/api/v1/efficiency/heatmap

# Question 3
curl http://localhost:8000/api/v1/surge/events?threshold=0.2

# Question 4
curl http://localhost:8000/api/v1/wait-time/current

# Question 5
curl http://localhost:8000/api/v1/congestion/zones

# Question 6
curl http://localhost:8000/api/v1/incentives/driver
curl http://localhost:8000/api/v1/incentives/system
curl http://localhost:8000/api/v1/incentives/misalignment

# Question 7
curl http://localhost:8000/api/v1/variability/heatmap
curl http://localhost:8000/api/v1/variability/distribution
curl http://localhost:8000/api/v1/variability/trends

# Question 8
curl http://localhost:8000/api/v1/simulation/min-distance?threshold=1.0
```

### Test Frontend
1. Open browser to `http://localhost:5173`
2. Navigate through all pages
3. Check browser console for errors
4. Check Network tab for API calls
5. Verify charts render correctly

## Next Steps

1. **Fix SQL compatibility issues** in wait_time.py, congestion.py, surge.py, simulation.py
2. **Test all API endpoints** using curl commands above
3. **Verify frontend pages** load and display data correctly
4. **Fix any broken visualizations** for Questions 4-7
5. **Run performance tests** and optimize slow queries
6. **Document any remaining issues** or assumptions




