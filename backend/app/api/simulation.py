"""
Simulation API endpoints - Question 8: Minimum Distance Threshold Simulation
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from app.services.sql_compat import duration_minutes, count_filter, is_sqlite
from typing import Dict, Any, Optional

router = APIRouter()


@router.get("/simulation/min-distance")
async def simulate_min_distance(
    threshold: float = Query(1.0, description="Minimum distance threshold in miles"),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Simulate impact of removing trips below minimum distance threshold"""
    db_service = DatabaseService(db)
    
    # Before simulation
    if is_sqlite():
        before_query = f"""
            SELECT 
                COUNT(*) AS total_trips,
                SUM(total_amount) AS total_revenue,
                AVG({duration_minutes()}) AS avg_duration_minutes,
                {count_filter('trip_distance < :threshold')} AS trips_below_threshold
            FROM trips
            WHERE tpep_pickup_datetime >= '2025-01-01'
                AND tpep_pickup_datetime < '2025-05-01'
                AND tpep_dropoff_datetime > tpep_pickup_datetime
        """
    else:
        before_query = """
            SELECT 
                COUNT(*) AS total_trips,
                SUM(total_amount) AS total_revenue,
                AVG(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) AS avg_duration_minutes,
                COUNT(*) FILTER (WHERE trip_distance < :threshold) AS trips_below_threshold
            FROM trips
            WHERE tpep_pickup_datetime >= '2025-01-01'
                AND tpep_pickup_datetime < '2025-05-01'
                AND tpep_dropoff_datetime > tpep_pickup_datetime
        """
    
    before_result = db_service.execute_query(before_query, {"threshold": threshold}).iloc[0]
    
    # After simulation (remove trips below threshold)
    after_query = f"""
        SELECT 
            COUNT(*) AS total_trips,
            SUM(total_amount) AS total_revenue,
            AVG({duration_minutes()}) AS avg_duration_minutes
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-05-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
            AND trip_distance >= :threshold
    """
    
    after_result = db_service.execute_query(after_query, {"threshold": threshold}).iloc[0]
    
    # Calculate impact
    trips_removed = int(before_result['total_trips']) - int(after_result['total_trips'])
    revenue_impact = float(before_result['total_revenue']) - float(after_result['total_revenue'])
    revenue_percentage = (revenue_impact / float(before_result['total_revenue'])) * 100 if before_result['total_revenue'] else 0
    
    return {
        "data": {
            "threshold_miles": threshold,
            "before": {
                "total_trips": int(before_result['total_trips']),
                "total_revenue": float(before_result['total_revenue']),
                "avg_duration_minutes": float(before_result['avg_duration_minutes']) if before_result['avg_duration_minutes'] else 0,
                "trips_below_threshold": int(before_result['trips_below_threshold'])
            },
            "after": {
                "total_trips": int(after_result['total_trips']),
                "total_revenue": float(after_result['total_revenue']),
                "avg_duration_minutes": float(after_result['avg_duration_minutes']) if after_result['avg_duration_minutes'] else 0
            },
            "impact": {
                "trips_removed": trips_removed,
                "trips_removed_percentage": (trips_removed / int(before_result['total_trips'])) * 100 if before_result['total_trips'] else 0,
                "revenue_impact": revenue_impact,
                "revenue_impact_percentage": revenue_percentage,
                "avg_duration_change": float(after_result['avg_duration_minutes']) - float(before_result['avg_duration_minutes']) if before_result['avg_duration_minutes'] and after_result['avg_duration_minutes'] else 0
            }
        },
        "assumptions": {
            "simulation_method": "Static removal - assumes no behavioral changes",
            "limitations": [
                "Does not model driver behavior changes",
                "Does not account for passenger demand shifts",
                "Assumes removed trips don't affect remaining trips",
                "No congestion impact modeling"
            ],
            "fragility": "High - real-world impact would differ significantly"
        }
    }


@router.get("/simulation/results")
async def get_simulation_results(
    threshold: float = Query(1.0),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get detailed simulation results"""
    # Similar to POST endpoint but returns cached results
    return await simulate_min_distance(threshold, db)


@router.get("/simulation/sensitivity")
async def get_sensitivity_analysis(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Run sensitivity analysis with multiple thresholds"""
    db_service = DatabaseService(db)
    
    thresholds = [0.5, 1.0, 1.5, 2.0]
    results = []
    
    for threshold in thresholds:
        if is_sqlite():
            query = f"""
                SELECT 
                    :threshold AS threshold,
                    COUNT(*) AS total_trips,
                    {count_filter('trip_distance < :threshold')} AS trips_below,
                    SUM(total_amount) AS total_revenue,
                    SUM(CASE WHEN trip_distance >= :threshold THEN total_amount ELSE 0 END) AS revenue_after
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
            """
        else:
            query = f"""
                SELECT 
                    :threshold AS threshold,
                    COUNT(*) AS total_trips,
                    {count_filter('trip_distance < :threshold')} AS trips_below,
                    SUM(total_amount) AS total_revenue,
                    SUM(CASE WHEN trip_distance >= :threshold THEN total_amount ELSE 0 END) AS revenue_after
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
            """
        
        result = db_service.execute_query(query, {"threshold": threshold}).iloc[0]
        results.append({
            "threshold": threshold,
            "total_trips": int(result['total_trips']),
            "trips_removed": int(result['trips_below']),
            "trips_removed_percentage": (int(result['trips_below']) / int(result['total_trips'])) * 100 if result['total_trips'] else 0,
            "revenue_before": float(result['total_revenue']),
            "revenue_after": float(result['revenue_after']),
            "revenue_impact_percentage": ((float(result['total_revenue']) - float(result['revenue_after'])) / float(result['total_revenue'])) * 100 if result['total_revenue'] else 0
        })
    
    return {
        "data": results,
        "assumptions": {
            "sensitivity_analysis": "Tests multiple threshold values",
            "thresholds_tested": thresholds,
            "note": "Shows how sensitive metrics are to threshold changes"
        }
    }

