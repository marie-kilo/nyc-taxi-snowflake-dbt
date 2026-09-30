-- Le test échoue si les dates sont incohérentes
-- ou si le pickup est hors de l'année 2025.

SELECT *
FROM {{ ref('stg_yellow_taxi_trips') }}

WHERE
    PICKUP_DATETIME < '2025-01-01'
    OR PICKUP_DATETIME >= '2026-01-01'
    OR DROPOFF_DATETIME <= PICKUP_DATETIME