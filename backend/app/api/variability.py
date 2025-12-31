"""
Variability API endpoints - Question 7: Trip Duration Variability
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from app.services.sql_compat import duration_minutes, extract_hour, is_sqlite
from typing import Dict, Any

router = APIRouter()


@router.get("/variability/heatmap")
async def get_variability_heatmap(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get coefficient of variation by hour and distance bin"""
    db_service = DatabaseService(db)
    
    if is_sqlite():
        # SQLite: Calculate stddev manually using variance formula
        query = f"""
            WITH trip_metrics AS (
                SELECT 
                    {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                    CASE 
                        WHEN trip_distance < 2 THEN '0-2'
                        WHEN trip_distance < 5 THEN '2-5'
                        WHEN trip_distance < 10 THEN '5-10'
                        ELSE '10+'
                    END AS distance_bin,
                    {duration_minutes()} AS duration_minutes
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
                    AND trip_distance > 0
            ),
            stats AS (
                SELECT 
                    hour_of_day,
                    distance_bin,
                    COUNT(*) AS trip_count,
                    AVG(duration_minutes) AS mean_duration,
                    AVG(duration_minutes * duration_minutes) AS mean_sq_duration
                FROM trip_metrics
                GROUP BY hour_of_day, distance_bin
                HAVING COUNT(*) >= 20
            )
            SELECT 
                hour_of_day,
                distance_bin,
                trip_count,
                mean_duration,
                SQRT(mean_sq_duration - mean_duration * mean_duration) AS std_duration,
                CASE 
                    WHEN mean_duration > 0 
                    THEN SQRT(mean_sq_duration - mean_duration * mean_duration) / mean_duration
                    ELSE NULL
                END AS coefficient_of_variation
            FROM stats
            ORDER BY hour_of_day, distance_bin
        """
    else:
        query = f"""
            WITH trip_metrics AS (
                SELECT 
                    {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                    CASE 
                        WHEN trip_distance < 2 THEN '0-2'
                        WHEN trip_distance < 5 THEN '2-5'
                        WHEN trip_distance < 10 THEN '5-10'
                        ELSE '10+'
                    END AS distance_bin,
                    {duration_minutes()} AS duration_minutes
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
                    AND trip_distance > 0
            )
            SELECT 
                hour_of_day,
                distance_bin,
                COUNT(*) AS trip_count,
                AVG(duration_minutes) AS mean_duration,
                STDDEV(duration_minutes) AS std_duration,
                CASE 
                    WHEN AVG(duration_minutes) > 0 
                    THEN STDDEV(duration_minutes) / AVG(duration_minutes)
                    ELSE NULL
                END AS coefficient_of_variation
            FROM trip_metrics
            GROUP BY hour_of_day, distance_bin
            HAVING COUNT(*) >= 20
            ORDER BY hour_of_day, distance_bin
        """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "coefficient_of_variation": "Std(Duration) / Mean(Duration)",
            "distance_bins": "0-2, 2-5, 5-10, 10+ miles",
            "interpretation": "Higher CV = more variability = less predictable"
        }
    }


@router.get("/variability/distribution")
async def get_duration_distribution(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get duration distribution by hour"""
    db_service = DatabaseService(db)
    
    if is_sqlite():
        # SQLite: Simplified distribution without percentiles
        query = f"""
            SELECT 
                {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                COUNT(*) AS trip_count,
                MIN({duration_minutes()}) AS min_duration,
                AVG({duration_minutes()}) AS mean_duration,
                MAX({duration_minutes()}) AS max_duration,
                SQRT(AVG({duration_minutes()} * {duration_minutes()}) - AVG({duration_minutes()}) * AVG({duration_minutes()})) AS std_duration
            FROM trips
            WHERE tpep_pickup_datetime >= '2025-01-01'
                AND tpep_pickup_datetime < '2025-05-01'
                AND tpep_dropoff_datetime > tpep_pickup_datetime
            GROUP BY {extract_hour('tpep_pickup_datetime')}
            ORDER BY hour_of_day
        """
    else:
        query = f"""
            SELECT 
                {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                COUNT(*) AS trip_count,
                MIN({duration_minutes()}) AS min_duration,
                PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY {duration_minutes()}) AS p25_duration,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY {duration_minutes()}) AS median_duration,
                PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY {duration_minutes()}) AS p75_duration,
                MAX({duration_minutes()}) AS max_duration,
                AVG({duration_minutes()}) AS mean_duration,
                STDDEV({duration_minutes()}) AS std_duration
            FROM trips
            WHERE tpep_pickup_datetime >= '2025-01-01'
                AND tpep_pickup_datetime < '2025-05-01'
                AND tpep_dropoff_datetime > tpep_pickup_datetime
            GROUP BY {extract_hour('tpep_pickup_datetime')}
            ORDER BY hour_of_day
        """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "distribution_metrics": "Min, Q1, Median, Q3, Max, Mean, StdDev",
            "use_case": "Box plot visualization"
        }
    }


@router.get("/variability/trends")
async def get_variability_trends(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get variability trends over time"""
    db_service = DatabaseService(db)
    
    if is_sqlite():
        # SQLite: Calculate stddev manually
        query = f"""
            WITH stats AS (
                SELECT 
                    DATE(tpep_pickup_datetime) AS date,
                    {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                    COUNT(*) AS trip_count,
                    AVG({duration_minutes()}) AS mean_duration,
                    AVG({duration_minutes()} * {duration_minutes()}) AS mean_sq_duration
                FROM trips
                WHERE tpep_pickup_datetime >= '2025-01-01'
                    AND tpep_pickup_datetime < '2025-05-01'
                    AND tpep_dropoff_datetime > tpep_pickup_datetime
                GROUP BY DATE(tpep_pickup_datetime), {extract_hour('tpep_pickup_datetime')}
                HAVING COUNT(*) >= 10
            )
            SELECT 
                date,
                hour_of_day,
                trip_count,
                mean_duration,
                SQRT(mean_sq_duration - mean_duration * mean_duration) AS std_duration,
                CASE 
                    WHEN mean_duration > 0
                    THEN SQRT(mean_sq_duration - mean_duration * mean_duration) / mean_duration
                    ELSE NULL
                END AS coefficient_of_variation
            FROM stats
            ORDER BY date, hour_of_day
        """
    else:
        query = f"""
            SELECT 
                DATE(tpep_pickup_datetime) AS date,
                {extract_hour('tpep_pickup_datetime')} AS hour_of_day,
                COUNT(*) AS trip_count,
                AVG({duration_minutes()}) AS mean_duration,
                STDDEV({duration_minutes()}) AS std_duration,
                CASE 
                    WHEN AVG({duration_minutes()}) > 0
                    THEN STDDEV({duration_minutes()}) / AVG({duration_minutes()})
                    ELSE NULL
                END AS coefficient_of_variation
            FROM trips
            WHERE tpep_pickup_datetime >= '2025-01-01'
                AND tpep_pickup_datetime < '2025-05-01'
                AND tpep_dropoff_datetime > tpep_pickup_datetime
            GROUP BY DATE(tpep_pickup_datetime), {extract_hour('tpep_pickup_datetime')}
            HAVING COUNT(*) >= 10
            ORDER BY date, hour_of_day
        """
    
    result = db_service.execute_query(query)
    
    return {
        "data": result.to_dict('records'),
        "assumptions": {
            "trend_analysis": "Shows variability patterns over time",
            "interpretation": "High variability = less predictable = worse rider experience"
        }
    }

