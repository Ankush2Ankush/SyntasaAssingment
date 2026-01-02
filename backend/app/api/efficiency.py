"""
Efficiency API endpoints - Question 2: Demand vs Efficiency
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from app.services.sql_compat import duration_minutes, date_trunc_hour, extract_hour, extract_dow
from typing import Dict, Any

router = APIRouter()


@router.get("/efficiency/timeseries")
async def get_efficiency_timeseries(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get system efficiency over time"""
    db_service = DatabaseService(db)
    
    query = f"""
        SELECT 
            {date_trunc_hour('tpep_pickup_datetime')} AS hour,
            COUNT(*) AS total_trips,
            SUM(total_amount) AS total_revenue,
            AVG({duration_minutes()}) AS avg_duration_minutes,
            -- System efficiency: Revenue per vehicle hour (simplified)
            SUM(total_amount) / NULLIF(COUNT(*) * AVG({duration_minutes()}) / 60, 0) AS efficiency
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-02-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
        GROUP BY {date_trunc_hour('tpep_pickup_datetime')}
        ORDER BY hour
    """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "efficiency_calculation": "Revenue per vehicle hour (simplified - doesn't include idle time)",
            "note": "Full efficiency calculation requires idle time analysis"
        }
    }


@router.get("/efficiency/heatmap")
async def get_efficiency_heatmap(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get efficiency by hour of day and day of week"""
    db_service = DatabaseService(db)
    
    query = f"""
        SELECT 
            {extract_dow('tpep_pickup_datetime')} AS day_of_week,
            {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
            COUNT(*) AS total_trips,
            SUM(total_amount) AS total_revenue,
            SUM(total_amount) / NULLIF(COUNT(*) * AVG({duration_minutes()}) / 60, 0) AS efficiency
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-02-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
        GROUP BY {extract_dow('tpep_pickup_datetime')}, {extract_hour('tpep_pickup_datetime')}
        ORDER BY day_of_week, hour_of_day
    """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "efficiency_calculation": "Revenue per vehicle hour",
            "day_of_week": "0 = Sunday, 6 = Saturday"
        }
    }


@router.get("/efficiency/demand-correlation")
async def get_demand_efficiency_correlation(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get correlation between demand (trips) and efficiency"""
    db_service = DatabaseService(db)
    
    query = f"""
        SELECT 
            {date_trunc_hour('tpep_pickup_datetime')} AS hour,
            COUNT(*) AS demand_trips,
            SUM(total_amount) / NULLIF(COUNT(*) * AVG({duration_minutes()}) / 60, 0) AS efficiency
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-02-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
        GROUP BY {date_trunc_hour('tpep_pickup_datetime')}
        HAVING COUNT(*) > 10  -- Filter out low-volume hours
        ORDER BY demand_trips DESC
    """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "correlation_analysis": "Shows relationship between trip count and efficiency",
            "note": "Negative correlation indicates times when increased demand reduces efficiency"
        }
    }

