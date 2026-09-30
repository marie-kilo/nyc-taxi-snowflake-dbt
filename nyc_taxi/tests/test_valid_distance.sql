-- Le test échoue si une distance invalide est trouvée.

SELECT *
FROM {{ ref('stg_yellow_taxi_trips') }}

WHERE
    TRIP_DISTANCE <= 0
    OR TRIP_DISTANCE > 1000