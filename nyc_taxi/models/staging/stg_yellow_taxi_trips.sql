-- Nettoyage et standardisation des données brutes NYC Yellow Taxi 2025

WITH source AS (

    SELECT *
    FROM {{ source('raw', 'yellow_taxi_trips') }}

),

typed AS (

    SELECT
        VENDORID,

        TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6) AS PICKUP_DATETIME,
        TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6) AS DROPOFF_DATETIME,

        PASSENGER_COUNT,
        TRIP_DISTANCE,
        RATECODEID,
        STORE_AND_FWD_FLAG,
        PULOCATIONID,
        DOLOCATIONID,
        PAYMENT_TYPE,

        FARE_AMOUNT,
        EXTRA,
        MTA_TAX,
        TIP_AMOUNT,
        TOLLS_AMOUNT,
        IMPROVEMENT_SURCHARGE,
        TOTAL_AMOUNT,
        CONGESTION_SURCHARGE,
        AIRPORT_FEE,
        CBD_CONGESTION_FEE

    FROM source

),

cleaned AS (

    SELECT *

    FROM typed

    WHERE
        -- Périmètre analytique : année 2025
        PICKUP_DATETIME >= '2025-01-01'
        AND PICKUP_DATETIME < '2026-01-01'

        -- Distance valide
        AND TRIP_DISTANCE > 0
        AND TRIP_DISTANCE <= 1000

        -- Dates cohérentes
        AND DROPOFF_DATETIME > PICKUP_DATETIME

        -- Durée maximale retenue : 24 heures
        AND DATEDIFF(
            'second',
            PICKUP_DATETIME,
            DROPOFF_DATETIME
        ) <= 86400

        -- Montants financiers non négatifs
        AND FARE_AMOUNT >= 0
        AND EXTRA >= 0
        AND MTA_TAX >= 0
        AND TIP_AMOUNT >= 0
        AND TOLLS_AMOUNT >= 0
        AND IMPROVEMENT_SURCHARGE >= 0
        AND TOTAL_AMOUNT >= 0

        -- Les NULL restent acceptés pour ces colonnes
        AND COALESCE(CONGESTION_SURCHARGE, 0) >= 0
        AND COALESCE(AIRPORT_FEE, 0) >= 0

        AND CBD_CONGESTION_FEE >= 0

)

SELECT *
FROM cleaned