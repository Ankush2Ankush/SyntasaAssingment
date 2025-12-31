-- Calculate revenue metrics by pickup zone
SELECT 
    pulocationid AS zone_id,
    COUNT(*) AS trip_count,
    SUM(fare_amount) AS total_revenue,
    SUM(tip_amount) AS total_tips,
    SUM(total_amount) AS total_amount,
    AVG(fare_amount) AS avg_fare,
    AVG(trip_distance) AS avg_distance,
    AVG(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60) AS avg_duration_minutes
FROM trips
WHERE tpep_pickup_datetime >= '2025-01-01'
    AND tpep_pickup_datetime < '2025-05-01'
    AND tpep_dropoff_datetime > tpep_pickup_datetime
GROUP BY pulocationid
ORDER BY total_revenue DESC;

