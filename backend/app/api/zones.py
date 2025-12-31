"""
Zones API endpoints - Question 1: High Revenue Zones
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from app.services.sql_compat import duration_minutes
from typing import Dict, Any, Optional

router = APIRouter()


@router.get("/zones/revenue")
async def get_zone_revenue(
    limit: Optional[int] = Query(20, description="Number of top zones to return"),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get revenue metrics by zone"""
    db_service = DatabaseService(db)
    
    query = """
        SELECT 
            pulocationid AS zone_id,
            COUNT(*) AS trip_count,
            SUM(fare_amount) AS total_revenue,
            SUM(tip_amount) AS total_tips,
            SUM(total_amount) AS total_amount,
            AVG(fare_amount) AS avg_fare,
            AVG(trip_distance) AS avg_distance,
            AVG({duration_sql}) AS avg_duration_minutes
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-05-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
        GROUP BY pulocationid
        ORDER BY total_revenue DESC
        LIMIT :limit
    """.format(duration_sql=duration_minutes())
    
    result = db_service.execute_query(query, {"limit": limit})
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "idle_time_cost": "Not yet calculated - requires zone-level idle time analysis",
            "empty_return_cost": "Not yet calculated - requires return trip probability analysis",
            "note": "Net profit calculation requires additional metrics (idle time, empty returns)"
        }
    }


@router.get("/zones/net-profit")
async def get_zone_net_profit(
    idle_cost_per_hour: float = Query(30.0, description="Cost per hour of idle time"),
    empty_return_cost_multiplier: float = Query(0.5, description="Cost multiplier for empty returns"),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Calculate net profit by zone (revenue - costs)"""
    db_service = DatabaseService(db)
    
    # This is a simplified version - full implementation would include:
    # 1. Zone-level idle time calculation
    # 2. Empty return probability calculation
    # 3. Cost application
    
    query = """
        SELECT 
            pulocationid AS zone_id,
            COUNT(*) AS trip_count,
            SUM(total_amount) AS gross_revenue,
            AVG({duration_sql}) AS avg_duration_minutes,
            -- Simplified cost calculation (placeholder)
            SUM(total_amount) - (COUNT(*) * :idle_cost_per_hour * AVG({duration_sql}) / 60) AS net_profit
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-05-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
        GROUP BY pulocationid
        ORDER BY net_profit DESC
    """.format(duration_sql=duration_minutes())
    result = db_service.execute_query(query, {
        "idle_cost_per_hour": idle_cost_per_hour,
        "empty_return_cost_multiplier": empty_return_cost_multiplier
    })
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "idle_time_calculation": "Zone-level average idle time (simplified)",
            "idle_cost_per_hour": idle_cost_per_hour,
            "empty_return_cost": "Not yet fully implemented",
            "note": "This is a simplified calculation. Full implementation requires spatiotemporal analysis"
        }
    }


@router.get("/zones/negative-zones")
async def get_negative_zones(
    idle_cost_per_hour: float = Query(30.0),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get zones that become net negative after accounting for costs"""
    db_service = DatabaseService(db)
    
    query = """
        WITH zone_metrics AS (
            SELECT 
                pulocationid AS zone_id,
                SUM(total_amount) AS gross_revenue,
                COUNT(*) AS trip_count,
                AVG({duration_sql}) AS avg_duration_minutes
            FROM trips
            WHERE tpep_pickup_datetime >= '2025-01-01'
                AND tpep_pickup_datetime < '2025-05-01'
                AND tpep_dropoff_datetime > tpep_pickup_datetime
            GROUP BY pulocationid
        )
        SELECT 
            zone_id,
            gross_revenue,
            trip_count,
            avg_duration_minutes,
            gross_revenue - (trip_count * :idle_cost_per_hour * avg_duration_minutes / 60) AS net_profit
        FROM zone_metrics
        WHERE gross_revenue - (trip_count * :idle_cost_per_hour * avg_duration_minutes / 60) < 0
        ORDER BY net_profit ASC
    """.format(duration_sql=duration_minutes())
    result = db_service.execute_query(query, {"idle_cost_per_hour": idle_cost_per_hour})
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "idle_cost_per_hour": idle_cost_per_hour,
            "calculation_method": "Simplified - uses average duration as proxy for idle time",
            "note": "Full implementation requires zone-level idle time and empty return analysis"
        }
    }

