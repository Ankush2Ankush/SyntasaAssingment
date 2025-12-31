"""
Congestion API endpoints - Question 5: High Trip, High Congestion Zones
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from typing import Dict, Any

router = APIRouter()


@router.get("/congestion/zones")
async def get_congestion_zones(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get congestion metrics by zone"""
    db_service = DatabaseService(db)
    
    query = """
        SELECT 
            pulocationid AS zone_id,
            COUNT(*) AS trip_count,
            AVG(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) AS avg_duration_minutes,
            AVG(trip_distance) AS avg_distance,
            -- Congestion Index: Duration / Distance (higher = more congestion)
            AVG(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) / NULLIF(AVG(trip_distance), 0) AS congestion_index
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-05-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
            AND trip_distance > 0
        GROUP BY pulocationid
        HAVING COUNT(*) >= 50  -- At least 50 trips
        ORDER BY congestion_index DESC
    """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "congestion_index": "Average duration / Average distance",
            "interpretation": "Higher index = more time per mile = more congestion"
        }
    }


@router.get("/congestion/throughput")
async def get_throughput_analysis(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get throughput analysis (trips per unit time)"""
    db_service = DatabaseService(db)
    
    query = """
        SELECT 
            pulocationid AS zone_id,
            COUNT(*) AS trip_count,
            AVG(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) AS avg_duration_minutes,
            -- Throughput: Trips per hour (simplified - doesn't include idle time)
            COUNT(*) / NULLIF(EXTRACT(EPOCH FROM (MAX(tpep_pickup_datetime) - MIN(tpep_pickup_datetime)) / 3600), 0) AS throughput_per_hour
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-05-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
        GROUP BY pulocationid
        HAVING COUNT(*) >= 50
        ORDER BY trip_count DESC, throughput_per_hour ASC
    """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "throughput_calculation": "Trips per hour (simplified)",
            "note": "Full throughput requires idle time calculation"
        }
    }


@router.get("/congestion/short-trips")
async def get_short_trip_impact(
    short_trip_threshold: float = 1.0,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Analyze impact of short trips on productivity metrics"""
    db_service = DatabaseService(db)
    
    query = """
        SELECT 
            pulocationid AS zone_id,
            COUNT(*) AS total_trips,
            COUNT(*) FILTER (WHERE trip_distance < :threshold) AS short_trips,
            COUNT(*) FILTER (WHERE trip_distance < :threshold)::FLOAT / COUNT(*) AS short_trip_percentage,
            AVG(trip_distance) AS avg_distance,
            AVG(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) AS avg_duration_minutes,
            SUM(total_amount) AS total_revenue,
            SUM(total_amount) / NULLIF(COUNT(*), 0) AS revenue_per_trip
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-05-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
        GROUP BY pulocationid
        HAVING COUNT(*) >= 50
        ORDER BY short_trip_percentage DESC
    """
    
    result = db_service.execute_query(query, {"threshold": short_trip_threshold})
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "short_trip_threshold": f"{short_trip_threshold} miles",
            "productivity_impact": "Short trips may distort productivity metrics",
            "note": "High short trip percentage may indicate low productivity despite high trip count"
        }
    }

