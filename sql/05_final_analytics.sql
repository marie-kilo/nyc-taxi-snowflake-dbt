-- ============================================================
-- NYC Taxi Data Warehouse
-- 05 - FINAL analytical tables
-- ============================================================
--
-- Source :
-- NYC_TAXI_DB.STAGING.YELLOW_TAXI_TRIPS
--
-- Objectifs :
-- - produire des KPIs quotidiens ;
-- - analyser les zones de départ ;
-- - analyser les patterns horaires ;
-- - préparer les données pour un dashboard.
-- ============================================================


USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE NYC_TAXI_DB;
USE SCHEMA FINAL;


-- ============================================================
-- 1. DAILY_SUMMARY
-- ============================================================

CREATE OR REPLACE TABLE DAILY_SUMMARY AS

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

FROM NYC_TAXI_DB.STAGING.YELLOW_TAXI_TRIPS

GROUP BY
    PICKUP_DATE,
    DAY_TYPE;


-- Vérification
SELECT
    COUNT(*) AS NUMBER_OF_DAYS,
    MIN(PICKUP_DATE) AS FIRST_DATE,
    MAX(PICKUP_DATE) AS LAST_DATE,
    SUM(TOTAL_TRIPS) AS TOTAL_TRIPS
FROM FINAL.DAILY_SUMMARY;

-- Résultats observés :
-- NUMBER_OF_DAYS = 365
-- FIRST_DATE     = 2025-01-01
-- LAST_DATE      = 2025-12-31
-- TOTAL_TRIPS    = 44 178 660



-- ============================================================
-- 2. ZONE_ANALYSIS
-- ============================================================

CREATE OR REPLACE TABLE ZONE_ANALYSIS AS

SELECT
    PULOCATIONID,

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

FROM NYC_TAXI_DB.STAGING.YELLOW_TAXI_TRIPS

GROUP BY
    PULOCATIONID;


-- Vérification
SELECT
    COUNT(*) AS NUMBER_OF_ZONES,
    SUM(TOTAL_TRIPS) AS TOTAL_TRIPS
FROM FINAL.ZONE_ANALYSIS;

-- Résultats observés :
-- NUMBER_OF_ZONES = 262
-- TOTAL_TRIPS     = 44 178 660


-- Top 10 des zones de départ
SELECT *
FROM FINAL.ZONE_ANALYSIS
ORDER BY TOTAL_TRIPS DESC
LIMIT 10;



-- ============================================================
-- 3. HOURLY_PATTERNS
-- ============================================================

CREATE OR REPLACE TABLE HOURLY_PATTERNS AS

SELECT
    PICKUP_HOUR,
    TIME_PERIOD,
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
        AVG(TIP_RATE_PERCENT),
        2
    ) AS AVG_TIP_RATE_PERCENT

FROM NYC_TAXI_DB.STAGING.YELLOW_TAXI_TRIPS

GROUP BY
    PICKUP_HOUR,
    TIME_PERIOD,
    DAY_TYPE;


-- Vérification
SELECT
    COUNT(*) AS NUMBER_OF_HOURLY_PATTERNS,
    SUM(TOTAL_TRIPS) AS TOTAL_TRIPS
FROM FINAL.HOURLY_PATTERNS;

-- Résultats observés :
-- NUMBER_OF_HOURLY_PATTERNS = 48
-- TOTAL_TRIPS               = 44 178 660


-- Heures les plus demandées
SELECT
    PICKUP_HOUR,
    SUM(TOTAL_TRIPS) AS TOTAL_TRIPS
FROM FINAL.HOURLY_PATTERNS

GROUP BY PICKUP_HOUR

ORDER BY TOTAL_TRIPS DESC;

-- Heure de pointe observée :
-- 18h = 2 975 870 trajets



-- ============================================================
-- 4. Contrôle global STAGING -> FINAL
-- ============================================================

SELECT
    'STAGING' AS TABLE_NAME,
    COUNT(*) AS TOTAL_TRIPS
FROM NYC_TAXI_DB.STAGING.YELLOW_TAXI_TRIPS

UNION ALL

SELECT
    'FINAL.DAILY_SUMMARY',
    SUM(TOTAL_TRIPS)
FROM NYC_TAXI_DB.FINAL.DAILY_SUMMARY

UNION ALL

SELECT
    'FINAL.ZONE_ANALYSIS',
    SUM(TOTAL_TRIPS)
FROM NYC_TAXI_DB.FINAL.ZONE_ANALYSIS

UNION ALL

SELECT
    'FINAL.HOURLY_PATTERNS',
    SUM(TOTAL_TRIPS)
FROM NYC_TAXI_DB.FINAL.HOURLY_PATTERNS;


-- Résultat attendu pour les quatre lignes :
-- 44 178 660 trajets