-- ============================================================
-- NYC Taxi Data Warehouse
-- 04 - STAGING transformations
-- ============================================================
--
-- Source :
-- NYC_TAXI_DB.RAW.YELLOW_TAXI_TRIPS
--
-- Objectifs :
-- - convertir les timestamps bruts ;
-- - appliquer les règles de qualité retenues ;
-- - calculer durée, vitesse et taux de pourboire ;
-- - créer les dimensions analytiques.
--
-- Volume attendu après nettoyage :
-- 44 178 660 trajets
-- ============================================================


USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE NYC_TAXI_DB;
USE SCHEMA STAGING;


-- ------------------------------------------------------------
-- 1. Création de la table STAGING nettoyée et enrichie
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE YELLOW_TAXI_TRIPS AS

WITH BASE AS (

    SELECT
        VENDORID,

        TO_TIMESTAMP_NTZ(
            TPEP_PICKUP_DATETIME,
            6
        ) AS PICKUP_DATETIME,

        TO_TIMESTAMP_NTZ(
            TPEP_DROPOFF_DATETIME,
            6
        ) AS DROPOFF_DATETIME,

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
        CBD_CONGESTION_FEE,

        DATEDIFF(
            'second',
            TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6),
            TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        ) AS TRIP_DURATION_SECONDS

    FROM NYC_TAXI_DB.RAW.YELLOW_TAXI_TRIPS

    WHERE
        -- Périmètre analytique : année 2025
        TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6) >= '2025-01-01'
        AND TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6) < '2026-01-01'

        -- Distance valide
        AND TRIP_DISTANCE > 0
        AND TRIP_DISTANCE <= 1000

        -- Dates cohérentes
        AND TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
            > TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6)

        -- Durée strictement positive
        AND DATEDIFF(
            'second',
            TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6),
            TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        ) > 0

        -- Durée maximale : 24 heures
        AND DATEDIFF(
            'second',
            TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6),
            TO_TIMESTAMP_NTZ(TPEP_DROPOFF_DATETIME, 6)
        ) <= 86400

        -- Montants financiers non négatifs
        AND FARE_AMOUNT >= 0
        AND EXTRA >= 0
        AND MTA_TAX >= 0
        AND TIP_AMOUNT >= 0
        AND TOLLS_AMOUNT >= 0
        AND IMPROVEMENT_SURCHARGE >= 0
        AND TOTAL_AMOUNT >= 0

        -- NULL accepté pour ces deux colonnes
        AND COALESCE(CONGESTION_SURCHARGE, 0) >= 0
        AND COALESCE(AIRPORT_FEE, 0) >= 0

        AND CBD_CONGESTION_FEE >= 0
)

SELECT
    VENDORID,

    PICKUP_DATETIME,
    DROPOFF_DATETIME,

    -- Dimensions temporelles
    TO_DATE(PICKUP_DATETIME)
        AS PICKUP_DATE,

    HOUR(PICKUP_DATETIME)
        AS PICKUP_HOUR,

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
    CBD_CONGESTION_FEE,

    -- Durée
    TRIP_DURATION_SECONDS,

    ROUND(
        TRIP_DURATION_SECONDS / 60.0,
        2
    ) AS TRIP_DURATION_MINUTES,

    -- Vitesse moyenne en miles par heure
    ROUND(
        TRIP_DISTANCE /
        (
            TRIP_DURATION_SECONDS / 3600.0
        ),
        2
    ) AS SPEED_MPH,

    -- Taux de pourboire par rapport au tarif de base
    ROUND(
        TIP_AMOUNT
        / NULLIF(FARE_AMOUNT, 0)
        * 100,
        2
    ) AS TIP_RATE_PERCENT,

    -- Catégorisation de la distance
    CASE
        WHEN TRIP_DISTANCE <= 2
            THEN 'SHORT'

        WHEN TRIP_DISTANCE <= 5
            THEN 'MEDIUM'

        WHEN TRIP_DISTANCE <= 10
            THEN 'LONG'

        ELSE 'VERY_LONG'
    END AS DISTANCE_CATEGORY,

    -- Catégorisation de la période horaire
    CASE
        WHEN HOUR(PICKUP_DATETIME) BETWEEN 6 AND 11
            THEN 'MORNING'

        WHEN HOUR(PICKUP_DATETIME) BETWEEN 12 AND 17
            THEN 'AFTERNOON'

        WHEN HOUR(PICKUP_DATETIME) BETWEEN 18 AND 23
            THEN 'EVENING'

        ELSE 'NIGHT'
    END AS TIME_PERIOD,

    -- Type de jour
    CASE
        WHEN DAYOFWEEKISO(PICKUP_DATETIME) IN (6, 7)
            THEN 'WEEKEND'

        ELSE 'WEEKDAY'
    END AS DAY_TYPE

FROM BASE;


-- ------------------------------------------------------------
-- 2. Vérification du volume STAGING
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS TOTAL_STAGING_ROWS
FROM NYC_TAXI_DB.STAGING.YELLOW_TAXI_TRIPS;

-- Résultat attendu :
-- 44 178 660


-- ------------------------------------------------------------
-- 3. Contrôle qualité final
-- ------------------------------------------------------------

SELECT
    COUNT_IF(
        PICKUP_DATETIME < '2025-01-01'
        OR PICKUP_DATETIME >= '2026-01-01'
    ) AS INVALID_DATE,

    COUNT_IF(
        TRIP_DISTANCE <= 0
        OR TRIP_DISTANCE > 1000
    ) AS INVALID_DISTANCE,

    COUNT_IF(
        TRIP_DURATION_SECONDS <= 0
        OR TRIP_DURATION_SECONDS > 86400
    ) AS INVALID_DURATION,

    COUNT_IF(
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
    ) AS INVALID_AMOUNT

FROM NYC_TAXI_DB.STAGING.YELLOW_TAXI_TRIPS;

-- Résultats obtenus :
--
-- INVALID_DATE      = 0
-- INVALID_DISTANCE  = 0
-- INVALID_DURATION  = 0
-- INVALID_AMOUNT    = 0