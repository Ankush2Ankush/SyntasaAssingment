-- Calculate trip duration in minutes
SELECT 
    id,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60 AS trip_duration_minutes
FROM trips
WHERE tpep_dropoff_datetime > tpep_pickup_datetime
    AND tpep_pickup_datetime >= '2025-01-01'
    AND tpep_pickup_datetime < '2025-05-01';

