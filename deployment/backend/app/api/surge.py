"""
Surge Pricing API endpoints - Question 3: Surge Pricing Paradox
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from app.services.sql_compat import is_sqlite, count_filter
from typing import Dict, Any

router = APIRouter()


@router.get("/surge/events")
async def get_surge_events(
    threshold: float = 0.2,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Detect surge pricing events"""
    db_service = DatabaseService(db)
    
    # SQLite-compatible: Use AVG instead of median for performance
    if is_sqlite():
        query = """
            WITH zone_avg_fares AS (
                SELECT 
                    pulocationid,
                    AVG(fare_amount) AS avg_fare
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND fare_amount > 0
                GROUP BY pulocationid
            )
            SELECT 
                t.tpep_pickup_datetime,
                t.pulocationid AS zone_id,
                t.fare_amount,
                zaf.avg_fare AS median_fare,
                CASE 
                    WHEN t.fare_amount > zaf.avg_fare * (1 + :threshold)
                    THEN 1 ELSE 0
                END AS is_surge
            FROM trips t
            JOIN zone_avg_fares zaf ON t.pulocationid = zaf.pulocationid
            WHERE t.tpep_pickup_datetime >= '2025-01-01'
                AND t.tpep_pickup_datetime < '2025-05-01'
                AND t.fare_amount > zaf.avg_fare * (1 + :threshold)
            ORDER BY t.tpep_pickup_datetime DESC
            LIMIT 1000
        """
    else:
        query = """
            WITH base_fares AS (
                SELECT 
                    pulocationid,
                    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fare_amount) AS median_fare
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND fare_amount > 0
                GROUP BY pulocationid
            )
            SELECT 
                t.tpep_pickup_datetime,
                t.pulocationid AS zone_id,
                t.fare_amount,
                bf.median_fare,
                CASE 
                    WHEN t.fare_amount > bf.median_fare * (1 + :threshold)
                    THEN 1 ELSE 0
                END AS is_surge
            FROM trips t
            JOIN base_fares bf ON t.pulocationid = bf.pulocationid
            WHERE t.tpep_pickup_datetime >= '2025-01-01'
                AND t.tpep_pickup_datetime < '2025-05-01'
                AND t.fare_amount > bf.median_fare * (1 + :threshold)
            ORDER BY t.tpep_pickup_datetime DESC
            LIMIT 1000
        """
    
    result = db_service.execute_query(query, {"threshold": threshold})
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "surge_threshold": f"{threshold * 100}% above median fare",
            "base_fare": "Average fare for each zone (SQLite uses AVG instead of median for performance)",
            "detection_method": "Statistical comparison to zone median"
        }
    }


@router.get("/surge/correlation")
async def get_surge_revenue_correlation(
    threshold: float = 0.2,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get correlation between surge events and daily revenue"""
    db_service = DatabaseService(db)
    
    # Simplified approach for SQLite - use AVG instead of median
    if is_sqlite():
        query = f"""
            WITH zone_avg_fares AS (
                SELECT 
                    pulocationid,
                    AVG(fare_amount) AS avg_fare
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND fare_amount > 0
                GROUP BY pulocationid
            ),
            daily_surge AS (
                SELECT 
                    DATE(t.tpep_pickup_datetime) AS date,
                    t.pulocationid AS zone_id,
                    {count_filter("t.fare_amount > zaf.avg_fare * (1 + :threshold)")} AS surge_count,
                    SUM(t.total_amount) AS daily_revenue
                FROM trips t
                JOIN zone_avg_fares zaf ON t.pulocationid = zaf.pulocationid
                WHERE t.tpep_pickup_datetime >= '2025-01-01'
                    AND t.tpep_pickup_datetime < '2025-05-01'
                GROUP BY DATE(t.tpep_pickup_datetime), t.pulocationid
            )
            SELECT 
                zone_id,
                AVG(surge_count) AS avg_surge_events,
                AVG(daily_revenue) AS avg_daily_revenue,
                COUNT(*) AS days_with_data
            FROM daily_surge
            GROUP BY zone_id
            HAVING COUNT(*) >= 5
            ORDER BY avg_surge_events DESC
        """
    else:
        query = f"""
            WITH base_fares AS (
                SELECT 
                    pulocationid,
                    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fare_amount) AS median_fare
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND fare_amount > 0
                GROUP BY pulocationid
            ),
            daily_surge AS (
                SELECT 
                    DATE(t.tpep_pickup_datetime) AS date,
                    t.pulocationid AS zone_id,
                    {count_filter("t.fare_amount > bf.median_fare * (1 + :threshold)")} AS surge_count,
                    SUM(t.total_amount) AS daily_revenue
                FROM trips t
                JOIN base_fares bf ON t.pulocationid = bf.pulocationid
                WHERE t.tpep_pickup_datetime >= '2025-01-01'
                    AND t.tpep_pickup_datetime < '2025-05-01'
                GROUP BY DATE(t.tpep_pickup_datetime), t.pulocationid
            )
            SELECT 
                zone_id,
                AVG(surge_count) AS avg_surge_events,
                AVG(daily_revenue) AS avg_daily_revenue,
                COUNT(*) AS days_with_data
            FROM daily_surge
            GROUP BY zone_id
            HAVING COUNT(*) >= 5
            ORDER BY avg_surge_events DESC
        """
    
    result = db_service.execute_query(query, {"threshold": threshold})
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "surge_threshold": f"{threshold * 100}% above median fare",
            "correlation_analysis": "Compares surge frequency to daily revenue",
            "note": "Negative correlation zones indicate surge pricing paradox"
        }
    }


@router.get("/surge/zones")
async def get_surge_zones(
    threshold: float = 0.2,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get zone-level surge analysis"""
    db_service = DatabaseService(db)
    
    # Simplified for SQLite - use AVG instead of median
    if is_sqlite():
        query = f"""
            WITH zone_avg_fares AS (
                SELECT 
                    pulocationid,
                    AVG(fare_amount) AS avg_fare
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND fare_amount > 0
                GROUP BY pulocationid
            )
            SELECT 
                t.pulocationid AS zone_id,
                COUNT(*) AS total_trips,
                {count_filter("t.fare_amount > zaf.avg_fare * (1 + :threshold)")} AS surge_trips,
                CAST({count_filter("t.fare_amount > zaf.avg_fare * (1 + :threshold)")} AS REAL) / COUNT(*) AS surge_percentage,
                SUM(t.total_amount) AS total_revenue
            FROM trips t
            JOIN zone_avg_fares zaf ON t.pulocationid = zaf.pulocationid
            WHERE t.tpep_pickup_datetime >= '2025-01-01'
                AND t.tpep_pickup_datetime < '2025-05-01'
            GROUP BY t.pulocationid
            HAVING COUNT(*) >= 100
            ORDER BY surge_percentage DESC
        """
    else:
        query = """
            WITH base_fares AS (
                SELECT 
                    pulocationid,
                    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fare_amount) AS median_fare
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND fare_amount > 0
                GROUP BY pulocationid
            )
            SELECT 
                t.pulocationid AS zone_id,
                COUNT(*) AS total_trips,
                {count_filter("t.fare_amount > bf.median_fare * (1 + :threshold)")} AS surge_trips,
                CAST({count_filter("t.fare_amount > bf.median_fare * (1 + :threshold)")} AS REAL) / COUNT(*) AS surge_percentage,
                SUM(t.total_amount) AS total_revenue
            FROM trips t
            JOIN base_fares bf ON t.pulocationid = bf.pulocationid
            WHERE t.tpep_pickup_datetime >= '2025-01-01'
                AND t.tpep_pickup_datetime < '2025-05-01'
            GROUP BY t.pulocationid
            HAVING COUNT(*) >= 100
            ORDER BY surge_percentage DESC
        """
    
    result = db_service.execute_query(query, {"threshold": threshold})
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "surge_threshold": f"{threshold * 100}% above median fare",
            "minimum_trips": 100
        }
    }

