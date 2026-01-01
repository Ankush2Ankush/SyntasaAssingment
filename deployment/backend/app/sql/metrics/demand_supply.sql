-- Calculate demand (pickups) and supply (dropoffs) by zone and hour
WITH demand AS (
    SELECT 
        pulocationid AS zone_id,
        DATE_TRUNC('hour', tpep_pickup_datetime) AS hour,
        COUNT(*) AS demand
    FROM trips
    WHERE tpep_pickup_datetime >= '2025-01-01'
        AND tpep_pickup_datetime < '2025-05-01'
    GROUP BY pulocationid, DATE_TRUNC('hour', tpep_pickup_datetime)
),
supply AS (
    SELECT 
        dolocationid AS zone_id,
        DATE_TRUNC('hour', tpep_dropoff_datetime) AS hour,
        COUNT(*) AS supply
    FROM trips
    WHERE tpep_dropoff_datetime >= '2025-01-01'
        AND tpep_dropoff_datetime < '2025-05-01'
    GROUP BY dolocationid, DATE_TRUNC('hour', tpep_dropoff_datetime)
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
ORDER BY zone_id, hour;

