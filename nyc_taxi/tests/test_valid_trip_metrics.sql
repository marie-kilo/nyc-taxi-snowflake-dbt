-- Le test échoue si une durée ou une vitesse invalide existe.

SELECT *
FROM {{ ref('int_trip_metrics') }}

WHERE
    TRIP_DURATION_SECONDS <= 0
    OR TRIP_DURATION_SECONDS > 86400
    OR SPEED_MPH IS NULL
    OR SPEED_MPH <= 0