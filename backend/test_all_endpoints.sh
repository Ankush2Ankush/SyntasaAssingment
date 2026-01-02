#!/bin/bash
# Test all API endpoints
# Run this in your SSH session on EC2: bash test_all_endpoints.sh

BASE_URL="http://localhost:8000"
echo "=== Testing All API Endpoints ==="
echo "Base URL: $BASE_URL"
echo ""

test_endpoint() {
    local name=$1
    local url=$2
    echo "Testing: $name"
    echo "URL: $url"
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$url")
    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d: -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')
    
    if [ "$http_code" = "200" ]; then
        echo "✅ Success (HTTP $http_code)"
        echo "$body" | head -c 150
        echo "..."
    else
        echo "❌ Failed (HTTP $http_code)"
        echo "$body"
    fi
    echo ""
}

# Overview
test_endpoint "Overview" "$BASE_URL/api/v1/overview"

# Zones
test_endpoint "Zones Revenue" "$BASE_URL/api/v1/zones/revenue?limit=5"
test_endpoint "Zones Net Profit" "$BASE_URL/api/v1/zones/net-profit?idle_cost_per_hour=30"
test_endpoint "Zones Negative Zones" "$BASE_URL/api/v1/zones/negative-zones"

# Efficiency
test_endpoint "Efficiency Timeseries" "$BASE_URL/api/v1/efficiency/timeseries"
test_endpoint "Efficiency Heatmap" "$BASE_URL/api/v1/efficiency/heatmap"
test_endpoint "Efficiency Demand Correlation" "$BASE_URL/api/v1/efficiency/demand-correlation"

# Surge
test_endpoint "Surge Events" "$BASE_URL/api/v1/surge/events?threshold=0.2"
test_endpoint "Surge Correlation" "$BASE_URL/api/v1/surge/correlation"
test_endpoint "Surge Zones" "$BASE_URL/api/v1/surge/zones"

# Wait Time
test_endpoint "Wait Time Current" "$BASE_URL/api/v1/wait-time/current"
test_endpoint "Wait Time Tradeoffs" "$BASE_URL/api/v1/wait-time/tradeoffs"

# Congestion
test_endpoint "Congestion Zones" "$BASE_URL/api/v1/congestion/zones"
test_endpoint "Congestion Throughput" "$BASE_URL/api/v1/congestion/throughput"
test_endpoint "Congestion Short Trips" "$BASE_URL/api/v1/congestion/short-trips"

# Incentives
test_endpoint "Incentives Driver" "$BASE_URL/api/v1/incentives/driver"
test_endpoint "Incentives System" "$BASE_URL/api/v1/incentives/system"
test_endpoint "Incentives Misalignment" "$BASE_URL/api/v1/incentives/misalignment"

# Variability
test_endpoint "Variability Heatmap" "$BASE_URL/api/v1/variability/heatmap"
test_endpoint "Variability Distribution" "$BASE_URL/api/v1/variability/distribution"
test_endpoint "Variability Trends" "$BASE_URL/api/v1/variability/trends"

# Simulation
test_endpoint "Simulation Min Distance" "$BASE_URL/api/v1/simulation/min-distance?threshold=1.0"
test_endpoint "Simulation Results" "$BASE_URL/api/v1/simulation/results"
test_endpoint "Simulation Sensitivity" "$BASE_URL/api/v1/simulation/sensitivity"

# Health
test_endpoint "Health" "$BASE_URL/health"
test_endpoint "API Health" "$BASE_URL/api/health"

echo "=== All Tests Complete ==="
