-- Le test échoue si un montant financier négatif subsiste.

SELECT *
FROM {{ ref('stg_yellow_taxi_trips') }}

WHERE
    FARE_AMOUNT < 0
    OR EXTRA < 0
    OR MTA_TAX < 0
    OR TIP_AMOUNT < 0
    OR TOLLS_AMOUNT < 0
    OR IMPROVEMENT_SURCHARGE < 0
    OR TOTAL_AMOUNT < 0
    OR COALESCE(CONGESTION_SURCHARGE, 0) < 0
    OR COALESCE(AIRPORT_FEE, 0) < 0
    OR CBD_CONGESTION_FEE < 0