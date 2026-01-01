"""
SQL helper functions for database compatibility
"""
from app.database.connection import DATABASE_URL


def get_duration_minutes_sql():
    """Get SQL for calculating duration in minutes (SQLite vs PostgreSQL)"""
    if DATABASE_URL.startswith("sqlite"):
        return "(julianday(tpep_dropoff_datetime) - julianday(tpep_pickup_datetime)) * 24 * 60"
    else:
        return "EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60"


def get_date_trunc_sql(column: str, unit: str = "hour"):
    """Get SQL for date truncation (SQLite vs PostgreSQL)"""
    if DATABASE_URL.startswith("sqlite"):
        if unit == "hour":
            return f"datetime({column}, 'start of hour')"
        elif unit == "day":
            return f"date({column})"
        else:
            return f"datetime({column}, 'start of {unit}')"
    else:
        return f"DATE_TRUNC('{unit}', {column})"


def get_extract_sql(column: str, part: str):
    """Get SQL for extracting date parts (SQLite vs PostgreSQL)"""
    if DATABASE_URL.startswith("sqlite"):
        if part == "HOUR":
            return f"CAST(strftime('%H', {column}) AS INTEGER)"
        elif part == "DOW":
            return f"CAST(strftime('%w', {column}) AS INTEGER)"
        elif part == "EPOCH":
            return f"julianday({column})"
        else:
            return f"strftime('%{part}', {column})"
    else:
        return f"EXTRACT({part} FROM {column})"


def get_percentile_sql(column: str, percentile: float):
    """Get SQL for percentile calculation (SQLite vs PostgreSQL)"""
    if DATABASE_URL.startswith("sqlite"):
        # SQLite doesn't have PERCENTILE_CONT, use approximate method
        # For exact percentile, we'd need to sort and pick, but for now use a simpler approach
        return f"""
            (SELECT {column} FROM trips 
             ORDER BY {column} 
             LIMIT 1 OFFSET (SELECT CAST(COUNT(*) * {percentile} AS INTEGER) FROM trips))
        """
    else:
        return f"PERCENTILE_CONT({percentile}) WITHIN GROUP (ORDER BY {column})"

