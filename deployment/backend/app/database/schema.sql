-- Database schema for NYC TLC Analytics
-- This file contains SQL DDL statements for creating tables and indexes
-- Note: Some PostgreSQL-specific features may not work with SQLite

-- Create trips table
CREATE TABLE IF NOT EXISTS trips (
    id SERIAL PRIMARY KEY,
    tpep_pickup_datetime TIMESTAMP NOT NULL,
    tpep_dropoff_datetime TIMESTAMP NOT NULL,
    pulocationid INTEGER NOT NULL,
    dolocationid INTEGER NOT NULL,
    trip_distance FLOAT,
    fare_amount FLOAT,
    tip_amount FLOAT,
    total_amount FLOAT,
    extra FLOAT,
    mta_tax FLOAT,
    tolls_amount FLOAT,
    payment_type INTEGER,
    ratecodeid INTEGER,
    passenger_count INTEGER,
    vendorid INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create taxi_zones table
CREATE TABLE IF NOT EXISTS taxi_zones (
    locationid INTEGER PRIMARY KEY,
    borough VARCHAR(255),
    zone VARCHAR(255),
    service_zone VARCHAR(255)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pickup_datetime ON trips(tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_dropoff_datetime ON trips(tpep_dropoff_datetime);
CREATE INDEX IF NOT EXISTS idx_pulocationid ON trips(pulocationid);
CREATE INDEX IF NOT EXISTS idx_dolocationid ON trips(dolocationid);
CREATE INDEX IF NOT EXISTS idx_pickup_location_time ON trips(pulocationid, tpep_pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_dropoff_location_time ON trips(dolocationid, tpep_dropoff_datetime);

-- Note: Materialized views are not supported in SQLite
-- Use regular views instead for SQLite compatibility
CREATE VIEW IF NOT EXISTS zone_daily_metrics AS
SELECT 
    pulocationid AS zone_id,
    DATE(tpep_pickup_datetime) AS date,
    COUNT(*) AS trip_count,
    SUM(fare_amount) AS total_revenue,
    AVG(trip_distance) AS avg_distance,
    AVG((julianday(tpep_dropoff_datetime) - julianday(tpep_pickup_datetime)) * 24 * 60) AS avg_duration_minutes
FROM trips
GROUP BY pulocationid, DATE(tpep_pickup_datetime);

