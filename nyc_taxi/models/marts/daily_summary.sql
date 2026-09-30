-- Résumé quotidien des trajets NYC Yellow Taxi 2025

SELECT
    PICKUP_DATE,
    DAY_TYPE,

    COUNT(*) AS TOTAL_TRIPS,

    ROUND(
        AVG(TRIP_DISTANCE),
        2
    ) AS AVG_TRIP_DISTANCE,

    ROUND(
        AVG(TRIP_DURATION_MINUTES),
        2
    ) AS AVG_TRIP_DURATION_MINUTES,

    ROUND(
        AVG(SPEED_MPH),
        2
    ) AS AVG_SPEED_MPH,

    ROUND(
        SUM(TOTAL_AMOUNT),
        2
    ) AS TOTAL_REVENUE,

    ROUND(
        AVG(TOTAL_AMOUNT),
        2
    ) AS AVG_REVENUE_PER_TRIP,

    ROUND(
        SUM(TIP_AMOUNT),
        2
    ) AS TOTAL_TIPS,

    ROUND(
        AVG(TIP_RATE_PERCENT),
        2
    ) AS AVG_TIP_RATE_PERCENT

FROM {{ ref('int_trip_metrics') }}

GROUP BY
    PICKUP_DATE,
    DAY_TYPE
    