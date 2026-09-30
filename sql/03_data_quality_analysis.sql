-- ============================================================
-- NYC Taxi Data Warehouse
-- 03 - Data quality analysis
-- ============================================================
--
-- Analyse réalisée sur :
-- NYC_TAXI_DB.RAW.YELLOW_TAXI_TRIPS
--
-- Volume RAW observé :
-- 48 722 602 trajets
--
-- Objectifs :
-- - identifier les dates incohérentes ;
-- - analyser les distances aberrantes ;
-- - détecter les montants négatifs ;
-- - analyser les valeurs NULL ;
-- - contrôler les durées de trajet ;
-- - quantifier le taux global de rejet.
-- ============================================================


USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE NYC_TAXI_DB;
USE SCHEMA RAW;


-- ------------------------------------------------------------
-- 1. Volume total RAW
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS TOTAL_RAW_ROWS
FROM YELLOW_TAXI_TRIPS;

-- Résultat observé :
-- 48 722 602


-- ------------------------------------------------------------
-- 2. Analyse des dates
-- ------------------------------------------------------------

-- Période brute observée
SELECT
    MIN(TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6))
        AS MIN_PICKUP_DATETIME,

    MAX(TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6))
        AS MAX_PICKUP_DATETIME

FROM YELLOW_TAXI_TRIPS;


-- Nombre de trajets dont le pickup est hors de l'année 2025
SELECT
    COUNT(*) AS PICKUP_OUTSIDE_2025

FROM YELLOW_TAXI_TRIPS

WHERE
    TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6) < '2025-01-01'
    OR TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6) >= '2026-01-01';

-- Résultat observé :
-- 29 trajets


-- Répartition par année des dates hors périmètre
SELECT
    YEAR(
        TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6)
    ) AS PICKUP_YEAR,

    COUNT(*) AS TOTAL_TRIPS

FROM YELLOW_TAXI_TRIPS

WHERE
    TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6) < '2025-01-01'
    OR TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6) >= '2026-01-01'

GROUP BY PICKUP_YEAR
ORDER BY PICKUP_YEAR;


-- ------------------------------------------------------------
-- 3. Analyse des distances
-- ------------------------------------------------------------

SELECT
    COUNT_IF(TRIP_DISTANCE < 0)
        AS NEGATIVE_DISTANCE,

    COUNT_IF(TRIP_DISTANCE = 0)
        AS ZERO_DISTANCE,

    COUNT_IF(TRIP_DISTANCE > 1000)
        AS DISTANCE_OVER_1000,

    MIN(TRIP_DISTANCE)
        AS MIN_DISTANCE,

    MAX(TRIP_DISTANCE)
        AS MAX_DISTANCE,

    AVG(TRIP_DISTANCE)
        AS AVG_DISTANCE

FROM YELLOW_TAXI_TRIPS;

-- Résultats observés :
-- NEGATIVE_DISTANCE   = 0
-- ZERO_DISTANCE       = 1 402 958
-- DISTANCE_OVER_1000  = 2 037
-- MAX_DISTANCE        = 397 994.37


-- Exemples de distances extrêmes
SELECT
    TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6)
        AS PICKUP_DATETIME,

    TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        AS DROPOFF_DATETIME,

    TRIP_DISTANCE,
    TOTAL_AMOUNT

FROM YELLOW_TAXI_TRIPS

WHERE TRIP_DISTANCE > 1000

ORDER BY TRIP_DISTANCE DESC

LIMIT 20;


-- ------------------------------------------------------------
-- 4. Analyse des montants négatifs
-- ------------------------------------------------------------

SELECT
    COUNT_IF(FARE_AMOUNT < 0)
        AS NEGATIVE_FARE_AMOUNT,

    COUNT_IF(EXTRA < 0)
        AS NEGATIVE_EXTRA,

    COUNT_IF(MTA_TAX < 0)
        AS NEGATIVE_MTA_TAX,

    COUNT_IF(TIP_AMOUNT < 0)
        AS NEGATIVE_TIP_AMOUNT,

    COUNT_IF(TOLLS_AMOUNT < 0)
        AS NEGATIVE_TOLLS_AMOUNT,

    COUNT_IF(IMPROVEMENT_SURCHARGE < 0)
        AS NEGATIVE_IMPROVEMENT_SURCHARGE,

    COUNT_IF(CONGESTION_SURCHARGE < 0)
        AS NEGATIVE_CONGESTION_SURCHARGE,

    COUNT_IF(AIRPORT_FEE < 0)
        AS NEGATIVE_AIRPORT_FEE,

    COUNT_IF(CBD_CONGESTION_FEE < 0)
        AS NEGATIVE_CBD_CONGESTION_FEE,

    COUNT_IF(TOTAL_AMOUNT < 0)
        AS NEGATIVE_TOTAL_AMOUNT

FROM YELLOW_TAXI_TRIPS;


-- Nombre de trajets ayant au moins un montant négatif
SELECT
    COUNT(*) AS TRIPS_WITH_NEGATIVE_AMOUNT

FROM YELLOW_TAXI_TRIPS

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
    OR CBD_CONGESTION_FEE < 0;

-- Résultat observé :
-- 2 856 096 trajets


-- ------------------------------------------------------------
-- 5. Analyse des valeurs NULL
-- ------------------------------------------------------------

SELECT
    COUNT_IF(PASSENGER_COUNT IS NULL)
        AS NULL_PASSENGER_COUNT,

    COUNT_IF(RATECODEID IS NULL)
        AS NULL_RATECODEID,

    COUNT_IF(STORE_AND_FWD_FLAG IS NULL)
        AS NULL_STORE_AND_FWD_FLAG,

    COUNT_IF(CONGESTION_SURCHARGE IS NULL)
        AS NULL_CONGESTION_SURCHARGE,

    COUNT_IF(AIRPORT_FEE IS NULL)
        AS NULL_AIRPORT_FEE

FROM YELLOW_TAXI_TRIPS;

-- Résultat observé :
-- 11 611 894 NULL pour chacune de ces cinq colonnes.


-- Vérification que ces NULL concernent le même ensemble de lignes
SELECT
    COUNT_IF(
        PASSENGER_COUNT IS NULL
        AND RATECODEID IS NULL
        AND STORE_AND_FWD_FLAG IS NULL
        AND CONGESTION_SURCHARGE IS NULL
        AND AIRPORT_FEE IS NULL
    ) AS ALL_FIVE_NULL,

    COUNT_IF(
        PASSENGER_COUNT IS NULL
        OR RATECODEID IS NULL
        OR STORE_AND_FWD_FLAG IS NULL
        OR CONGESTION_SURCHARGE IS NULL
        OR AIRPORT_FEE IS NULL
    ) AS AT_LEAST_ONE_NULL

FROM YELLOW_TAXI_TRIPS;

-- Résultats observés :
-- ALL_FIVE_NULL      = 11 611 894
-- AT_LEAST_ONE_NULL  = 11 611 894
--
-- Choix de traitement :
-- ces lignes sont conservées car les colonnes analytiques critiques
-- restent exploitables. Aucune imputation artificielle à zéro
-- n'est réalisée.


-- ------------------------------------------------------------
-- 6. Analyse des durées
-- ------------------------------------------------------------

SELECT
    COUNT_IF(
        DATEDIFF(
            'second',
            TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6),
            TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        ) < 0
    ) AS NEGATIVE_DURATION,

    COUNT_IF(
        DATEDIFF(
            'second',
            TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6),
            TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        ) = 0
    ) AS ZERO_DURATION,

    COUNT_IF(
        DATEDIFF(
            'second',
            TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6),
            TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        ) > 86400
    ) AS DURATION_OVER_24H,

    MIN(
        DATEDIFF(
            'second',
            TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6),
            TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        )
    ) AS MIN_DURATION_SECONDS,

    MAX(
        DATEDIFF(
            'second',
            TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6),
            TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        )
    ) AS MAX_DURATION_SECONDS

FROM YELLOW_TAXI_TRIPS;

-- Résultats observés :
-- NEGATIVE_DURATION = 2 235
-- ZERO_DURATION     = 544 069
-- DURATION_OVER_24H = 351
--
-- Règle retenue :
-- durée > 0 et <= 86 400 secondes (24 heures).


-- ------------------------------------------------------------
-- 7. Quantification globale du nettoyage
-- ------------------------------------------------------------

WITH QUALITY_FLAGS AS (

    SELECT
        *,

        TO_TIMESTAMP_NTZ(
            TPEP_PICKUP_DATETIME,
            6
        ) AS PICKUP_DATETIME,

        TO_TIMESTAMP_NTZ(
            TPEP_DROPOFF_DATETIME,
            6
        ) AS DROPOFF_DATETIME

    FROM YELLOW_TAXI_TRIPS

),

QUALITY_COUNTS AS (

    SELECT
        COUNT(*) AS TOTAL_RAW_ROWS,

        COUNT_IF(

            -- Pickup hors périmètre 2025
            PICKUP_DATETIME < '2025-01-01'
            OR PICKUP_DATETIME >= '2026-01-01'

            -- Distance invalide
            OR TRIP_DISTANCE <= 0
            OR TRIP_DISTANCE > 1000

            -- Dates/durée incohérentes
            OR DROPOFF_DATETIME <= PICKUP_DATETIME

            OR DATEDIFF(
                'second',
                PICKUP_DATETIME,
                DROPOFF_DATETIME
            ) > 86400

            -- Montants négatifs
            OR FARE_AMOUNT < 0
            OR EXTRA < 0
            OR MTA_TAX < 0
            OR TIP_AMOUNT < 0
            OR TOLLS_AMOUNT < 0
            OR IMPROVEMENT_SURCHARGE < 0
            OR TOTAL_AMOUNT < 0

            OR COALESCE(
                CONGESTION_SURCHARGE,
                0
            ) < 0

            OR COALESCE(
                AIRPORT_FEE,
                0
            ) < 0

            OR CBD_CONGESTION_FEE < 0

        ) AS REJECTED_ROWS

    FROM QUALITY_FLAGS

)

SELECT
    TOTAL_RAW_ROWS,

    REJECTED_ROWS,

    TOTAL_RAW_ROWS - REJECTED_ROWS
        AS VALID_ROWS,

    ROUND(
        REJECTED_ROWS
        / TOTAL_RAW_ROWS
        * 100,
        6
    ) AS REJECTION_RATE_PERCENT

FROM QUALITY_COUNTS;

-- Résultats observés :
--
-- TOTAL_RAW_ROWS          = 48 722 602
-- REJECTED_ROWS           = 4 543 942
-- VALID_ROWS              = 44 178 660
-- REJECTION_RATE_PERCENT  = 9.326148
--
-- Environ 90.67 % des données sont conservées
-- pour les analyses.