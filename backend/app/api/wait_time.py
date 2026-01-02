"""
Wait Time API endpoints - Question 4: Wait Time Reduction Levers
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from app.services.sql_compat import date_trunc_hour, is_sqlite
from typing import Dict, Any

router = APIRouter()


@router.get("/wait-time/current")
async def get_current_wait_time(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get current wait time metrics (demand/supply ratio)"""
    db_service = DatabaseService(db)
    
    if is_sqlite():
        # SQLite: Use LEFT JOIN + UNION instead of FULL OUTER JOIN
        query = f"""
            WITH demand AS (
                SELECT 
                    pulocationid AS zone_id,
                    {date_trunc_hour('tpep_pickup_datetime')} AS hour,
                    COUNT(*) AS demand
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-02-01'
                GROUP BY pulocationid, {date_trunc_hour('tpep_pickup_datetime')}
            ),
            supply AS (
                SELECT 
                    dolocationid AS zone_id,
                    {date_trunc_hour('tpep_dropoff_datetime')} AS hour,
                    COUNT(*) AS supply
                FROM trips
                WHERE tpep_dropoff_datetime >= '2025-01-01'
                    AND tpep_dropoff_datetime < '2025-02-01'
                GROUP BY dolocationid, {date_trunc_hour('tpep_dropoff_datetime')}
            ),
            combined AS (
                SELECT 
                    COALESCE(d.zone_id, s.zone_id) AS zone_id,
                    COALESCE(d.hour, s.hour) AS hour,
                    COALESCE(d.demand, 0) AS demand,
                    COALESCE(s.supply, 0) AS supply
                FROM demand d
                LEFT JOIN supply s ON d.zone_id = s.zone_id AND d.hour = s.hour
                UNION
                SELECT 
                    s.zone_id,
                    s.hour,
                    COALESCE(d.demand, 0) AS demand,
                    s.supply
                FROM supply s
                LEFT JOIN demand d ON s.zone_id = d.zone_id AND s.hour = d.hour
                WHERE d.zone_id IS NULL
            )
            SELECT 
                zone_id,
                hour,
                demand,
                supply,
                CASE 
                    WHEN supply > 0 
                    THEN CAST(demand AS REAL) / supply
                    ELSE NULL
                END AS wait_time_proxy
            FROM combined
            ORDER BY wait_time_proxy DESC
            LIMIT 1000
        """
    else:
        # PostgreSQL
        query = f"""
            WITH demand AS (
                SELECT 
                    pulocationid AS zone_id,
                    {date_trunc_hour('tpep_pickup_datetime')} AS hour,
                    COUNT(*) AS demand
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-02-01'
                GROUP BY pulocationid, {date_trunc_hour('tpep_pickup_datetime')}
            ),
            supply AS (
                SELECT 
                    dolocationid AS zone_id,
                    {date_trunc_hour('tpep_dropoff_datetime')} AS hour,
                    COUNT(*) AS supply
                FROM trips
                WHERE tpep_dropoff_datetime >= '2025-01-01'
                    AND tpep_dropoff_datetime < '2025-02-01'
                GROUP BY dolocationid, {date_trunc_hour('tpep_dropoff_datetime')}
            )
            SELECT 
                COALESCE(d.zone_id, s.zone_id) AS zone_id,
                COALESCE(d.hour, s.hour) AS hour,
                COALESCE(d.demand, 0) AS demand,
                COALESCE(s.supply, 0) AS supply,
                CASE 
                    WHEN COALESCE(s.supply, 0) > 0 
                    THEN COALESCE(d.demand, 0)::FLOAT / s.supply
                    ELSE NULL
                END AS wait_time_proxy
            FROM demand d
            FULL OUTER JOIN supply s ON d.zone_id = s.zone_id AND d.hour = s.hour
            ORDER BY wait_time_proxy DESC NULLS LAST
            LIMIT 1000
        """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "wait_time_proxy": "Demand/Supply ratio (higher = longer wait times)",
            "supply_definition": "Dropoff count as proxy for available vehicles",
            "note": "This is a proxy metric, not actual wait time data"
        }
    }


@router.post("/wait-time/simulate")
async def simulate_wait_time_reduction(
    lever: str = "vehicle_distribution",
    reduction_target: float = 0.1,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Simulate impact of wait time reduction levers"""
    # This would implement simulation logic
    # For now, return placeholder
    return {
        "data": {
            "lever": lever,
            "reduction_target": reduction_target,
            "simulated_wait_time_reduction": reduction_target,
            "impact": "Simulation not yet implemented"
        },
        "assumptions": {
            "lever_options": ["vehicle_distribution", "minimum_distance"],
            "note": "Full simulation requires complex modeling"
        }
    }


@router.get("/wait-time/tradeoffs")
async def get_wait_time_tradeoffs(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Analyze trade-offs of wait time reduction strategies"""
    return {
        "data": {
            "lever_1": {
                "name": "Optimize vehicle distribution",
                "benefits": ["Reduced wait time in high-demand zones"],
                "tradeoffs": ["Increased wait time in low-demand zones", "Potential driver earnings impact"]
            },
            "lever_2": {
                "name": "Reduce minimum trip distance",
                "benefits": ["Faster vehicle turnover", "More trips per hour"],
                "tradeoffs": ["Lower revenue per trip", "Increased congestion from more trips"]
            }
        },
        "assumptions": {
            "analysis_method": "Theoretical analysis based on data patterns",
            "note": "Full trade-off analysis requires simulation implementation"
        }
    }

