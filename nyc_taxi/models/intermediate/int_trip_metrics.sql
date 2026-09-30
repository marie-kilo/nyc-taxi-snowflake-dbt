-- Enrichissement des trajets nettoyés :
-- durée, vitesse, pourboire et dimensions analytiques

WITH trips AS (

    SELECT *
    FROM {{ ref('stg_yellow_taxi_trips') }}

),

enriched AS (

    SELECT
        *,

        TO_DATE(PICKUP_DATETIME) AS PICKUP_DATE,

        HOUR(PICKUP_DATETIME) AS PICKUP_HOUR,

        DATEDIFF(
            'second',
            PICKUP_DATETIME,
            DROPOFF_DATETIME
        ) AS TRIP_DURATION_SECONDS,

        DATEDIFF(
            'second',
            PICKUP_DATETIME,
            DROPOFF_DATETIME
        ) / 60.0 AS TRIP_DURATION_MINUTES,

        TRIP_DISTANCE /
        (
            DATEDIFF(
                'second',
                PICKUP_DATETIME,
                DROPOFF_DATETIME
            ) / 3600.0
        ) AS SPEED_MPH,

        TIP_AMOUNT
            / NULLIF(FARE_AMOUNT, 0)
            * 100 AS TIP_RATE_PERCENT,

        CASE
            WHEN TRIP_DISTANCE <= 2 THEN 'SHORT'
            WHEN TRIP_DISTANCE <= 5 THEN 'MEDIUM'
            WHEN TRIP_DISTANCE <= 10 THEN 'LONG'
            ELSE 'VERY_LONG'
        END AS DISTANCE_CATEGORY,

        CASE
            WHEN HOUR(PICKUP_DATETIME) BETWEEN 6 AND 11
                THEN 'MORNING'
            WHEN HOUR(PICKUP_DATETIME) BETWEEN 12 AND 17
                THEN 'AFTERNOON'
            WHEN HOUR(PICKUP_DATETIME) BETWEEN 18 AND 23
                THEN 'EVENING'
            ELSE 'NIGHT'
        END AS TIME_PERIOD,

        CASE
            WHEN DAYOFWEEKISO(PICKUP_DATETIME) IN (6, 7)
                THEN 'WEEKEND'
            ELSE 'WEEKDAY'
        END AS DAY_TYPE

    FROM trips

)

SELECT *
FROM enriched