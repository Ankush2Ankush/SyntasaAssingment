"""
SQL compatibility layer for SQLite and PostgreSQL
"""
from app.database.connection import DATABASE_URL


def is_sqlite():
    """Check if using SQLite"""
    return DATABASE_URL.startswith("sqlite")


def duration_minutes():
    """Get SQL for calculating duration in minutes"""
    if is_sqlite():
        return "(julianday(tpep_dropoff_datetime) - julianday(tpep_pickup_datetime)) * 24 * 60"
    return "EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60"


def date_trunc_hour(column: str):
    """Get SQL for truncating to hour"""
    if is_sqlite():
        # SQLite: Use strftime to truncate to hour
        return f"datetime(strftime('%Y-%m-%d %H:00:00', {column}))"
    return f"DATE_TRUNC('hour', {column})"


def extract_hour(column: str):
    """Get SQL for extracting hour"""
    if is_sqlite():
        return f"CAST(strftime('%H', {column}) AS INTEGER)"
    return f"EXTRACT(HOUR FROM {column})"


def extract_dow(column: str):
    """Get SQL for extracting day of week"""
    if is_sqlite():
        return f"CAST(strftime('%w', {column}) AS INTEGER)"
    return f"EXTRACT(DOW FROM {column})"


def median_fare_by_zone():
    """Get SQL for calculating median fare by zone (SQLite compatible)"""
    if is_sqlite():
        # SQLite: Use subquery to get median
        return """
            (SELECT fare_amount FROM trips t2 
             WHERE t2.pulocationid = t1.pulocationid 
               AND t2.fare_amount > 0
             ORDER BY t2.fare_amount 
             LIMIT 1 OFFSET (SELECT CAST(COUNT(*) * 0.5 AS INTEGER) FROM trips t3 
                            WHERE t3.pulocationid = t1.pulocationid AND t3.fare_amount > 0))
        """
    return "PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fare_amount)"


def count_filter(condition: str):
    """Get SQL for COUNT FILTER (SQLite uses CASE WHEN)"""
    if is_sqlite():
        return f"SUM(CASE WHEN {condition} THEN 1 ELSE 0 END)"
    return f"COUNT(*) FILTER (WHERE {condition})"

