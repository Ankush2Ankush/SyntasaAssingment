"""
Incentives API endpoints - Question 6: Driver Incentive Misalignment
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from app.services.sql_compat import duration_minutes, extract_hour, is_sqlite
from typing import Dict, Any

router = APIRouter()


@router.get("/incentives/driver")
async def get_driver_incentives(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get driver incentive metrics by zone and time"""
    try:
        db_service = DatabaseService(db)
        
        query = f"""
            SELECT 
                pulocationid AS zone_id,
                {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                COUNT(*) AS trip_count,
                AVG(fare_amount + tip_amount) AS avg_earnings_per_trip,
                AVG({duration_minutes()}) AS avg_duration_minutes,
                -- Driver Incentive Score: Earnings per minute
                AVG(fare_amount + tip_amount) / NULLIF(AVG({duration_minutes()}), 0) AS driver_incentive_score
            FROM trips
            WHERE tpep_pickup_datetime >= '2025-01-01'
                AND tpep_pickup_datetime < '2025-05-01'
                AND tpep_dropoff_datetime > tpep_pickup_datetime
            GROUP BY pulocationid, {extract_hour('tpep_pickup_datetime')}
            HAVING COUNT(*) >= 10
            ORDER BY driver_incentive_score DESC
            LIMIT 1000
        """
        
        result = db_service.execute_query(query)
        
        return {
            "data": result.to_dict('records'),
            "assumptions": {
                "driver_incentive_score": "(Fare + Tip) / Trip Duration",
                "interpretation": "Higher score = better driver incentive"
            }
        }
    except Exception as e:
        import traceback
        print(f"Error in get_driver_incentives: {e}")
        traceback.print_exc()
        raise


@router.get("/incentives/system")
async def get_system_efficiency(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get system efficiency metrics by zone and time"""
    db_service = DatabaseService(db)
    
    query = f"""
        SELECT 
            pulocationid AS zone_id,
            {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
            COUNT(*) AS trip_count,
            SUM(total_amount) AS total_revenue,
            AVG({duration_minutes()}) AS avg_duration_minutes,
            -- System Efficiency Score: Revenue per vehicle hour (simplified)
            SUM(total_amount) / NULLIF(COUNT(*) * AVG({duration_minutes()}) / 60, 0) AS system_efficiency_score
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-05-01'
            AND tpep_dropoff_datetime > tpep_pickup_datetime
        GROUP BY pulocationid, {extract_hour('tpep_pickup_datetime')}
        HAVING COUNT(*) >= 10
        ORDER BY system_efficiency_score DESC
    """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "system_efficiency_score": "Total Revenue / Total Vehicle Hours",
            "note": "Simplified - doesn't include idle time"
        }
    }


@router.get("/incentives/misalignment")
async def get_incentive_misalignment(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Identify zones/times where driver incentives and system efficiency are misaligned"""
    db_service = DatabaseService(db)
    
    # SQLite-compatible version using averages as thresholds (simpler than percentiles)
    if is_sqlite():
        query = f"""
            WITH driver_metrics AS (
                SELECT 
                    pulocationid AS zone_id,
                    {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                    AVG(fare_amount + tip_amount) / NULLIF(AVG({duration_minutes()}), 0) AS driver_score,
                    COUNT(*) AS trip_count
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-02-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
                GROUP BY pulocationid, {extract_hour('tpep_pickup_datetime')}
                HAVING COUNT(*) >= 10
            ),
            system_metrics AS (
                SELECT 
                    pulocationid AS zone_id,
                    {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                    SUM(total_amount) / NULLIF(COUNT(*) * AVG({duration_minutes()}) / 60, 0) AS system_score,
                    COUNT(*) AS trip_count
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-02-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
                GROUP BY pulocationid, {extract_hour('tpep_pickup_datetime')}
                HAVING COUNT(*) >= 10
            ),
            driver_avg AS (
                SELECT AVG(driver_score) * 1.2 AS threshold_driver FROM driver_metrics
            ),
            system_avg AS (
                SELECT AVG(system_score) * 0.8 AS threshold_system FROM system_metrics
            )
            SELECT 
                d.zone_id,
                d.hour_of_day,
                d.driver_score,
                s.system_score,
                CASE 
                    WHEN d.driver_score > (SELECT threshold_driver FROM driver_avg)
                        AND s.system_score < (SELECT threshold_system FROM system_avg)
                    THEN 1 ELSE 0
                END AS is_misaligned
            FROM driver_metrics d
            JOIN system_metrics s ON d.zone_id = s.zone_id AND d.hour_of_day = s.hour_of_day
            WHERE d.driver_score > (SELECT threshold_driver FROM driver_avg)
                AND s.system_score < (SELECT threshold_system FROM system_avg)
            ORDER BY d.driver_score DESC, s.system_score ASC
            LIMIT 100
        """
    else:
        query = f"""
            WITH driver_metrics AS (
                SELECT 
                    pulocationid AS zone_id,
                    {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                    AVG(fare_amount + tip_amount) / NULLIF(AVG({duration_minutes()}), 0) AS driver_score
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-02-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
                GROUP BY pulocationid, {extract_hour('tpep_pickup_datetime')}
                HAVING COUNT(*) >= 10
            ),
            system_metrics AS (
                SELECT 
                    pulocationid AS zone_id,
                    {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                    SUM(total_amount) / NULLIF(COUNT(*) * AVG({duration_minutes()}) / 60, 0) AS system_score
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-02-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
                GROUP BY pulocationid, {extract_hour('tpep_pickup_datetime')}
                HAVING COUNT(*) >= 10
            )
            SELECT 
                d.zone_id,
                d.hour_of_day,
                d.driver_score,
                s.system_score,
                CASE 
                    WHEN d.driver_score > (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY driver_score) FROM driver_metrics)
                        AND s.system_score < (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY system_score) FROM system_metrics)
                    THEN 1 ELSE 0
                END AS is_misaligned
            FROM driver_metrics d
            JOIN system_metrics s ON d.zone_id = s.zone_id AND d.hour_of_day = s.hour_of_day
            WHERE d.driver_score > (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY driver_score) FROM driver_metrics)
                AND s.system_score < (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY system_score) FROM system_metrics)
            ORDER BY d.driver_score DESC, s.system_score ASC
        """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "misalignment_definition": "High driver incentive but low system efficiency",
            "threshold": "Top 25% driver score, bottom 50% system score",
            "interpretation": "Zones where drivers are incentivized but system efficiency is low"
        }
    }

