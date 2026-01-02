"""
Overview API endpoints
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.connection import get_db
from app.services.db_service import DatabaseService
from typing import Dict, Any

router = APIRouter()


@router.get("/overview")
async def get_overview(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Get overview statistics"""
    db_service = DatabaseService(db)
    
    # Total trips
    total_trips_query = """
        SELECT COUNT(*) as total_trips
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-02-01'
    """
    total_trips = db_service.execute_scalar(total_trips_query)
    
    # Date range
    # SQLite uses different date functions
    date_range_query = """
        SELECT 
            MIN(tpep_pickup_datetime) as start_date,
            MAX(tpep_pickup_datetime) as end_date
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-02-01'
    """
    date_range = db_service.execute_query(date_range_query).iloc[0]
    
    # Total zones
    zones_query = "SELECT COUNT(DISTINCT pulocationid) as zone_count FROM trips"
    zone_count = db_service.execute_scalar(zones_query)
    
    # Total revenue
    revenue_query = """
        SELECT SUM(total_amount) as total_revenue
        FROM trips
        WHERE tpep_pickup_datetime >= '2025-01-01'
            AND tpep_pickup_datetime < '2025-02-01'
    """
    total_revenue = db_service.execute_scalar(revenue_query) or 0
    
    return {
        "data": {
            "total_trips": int(total_trips) if total_trips else 0,
            "start_date": str(date_range['start_date']) if date_range['start_date'] else None,
            "end_date": str(date_range['end_date']) if date_range['end_date'] else None,
            "zone_count": int(zone_count) if zone_count else 0,
            "total_revenue": float(total_revenue) if total_revenue else 0.0
        },
        "assumptions": {
            "date_range": "2025-01-01 to 2025-01-31",
            "data_source": "NYC TLC Yellow Taxi Trip Records"
        }
    }

