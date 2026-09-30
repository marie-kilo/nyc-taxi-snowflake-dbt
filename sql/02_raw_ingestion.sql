-- ============================================================
-- NYC Taxi Data Warehouse
-- 02 - RAW data ingestion
-- ============================================================
--
-- Source : NYC Yellow Taxi Trip Records - année 2025
-- Format : Parquet
--
-- Les 12 fichiers mensuels ont été déposés dans un stage interne
-- Snowflake via Snowsight :
-- Data > Add Data > Load files into a Stage
--
-- Stage utilisé : RAW.NYC_TAXI_STAGE
--
-- Le choix d'un stage interne a été retenu pour ce projet
-- pédagogique afin de rester dans l'environnement Snowflake
-- disponible sans infrastructure cloud externe supplémentaire.
-- ============================================================


USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE NYC_TAXI_DB;
USE SCHEMA RAW;


-- ------------------------------------------------------------
-- 1. Format de fichier Parquet
-- ------------------------------------------------------------

CREATE OR REPLACE FILE FORMAT PARQUET_FORMAT
    TYPE = PARQUET;


-- ------------------------------------------------------------
-- 2. Stage interne contenant les fichiers Parquet
-- ------------------------------------------------------------

CREATE OR REPLACE STAGE NYC_TAXI_STAGE
    FILE_FORMAT = PARQUET_FORMAT;


-- Les fichiers suivants doivent être déposés dans le stage :
--
-- yellow_tripdata_2025-01.parquet
-- yellow_tripdata_2025-02.parquet
-- yellow_tripdata_2025-03.parquet
-- yellow_tripdata_2025-04.parquet
-- yellow_tripdata_2025-05.parquet
-- yellow_tripdata_2025-06.parquet
-- yellow_tripdata_2025-07.parquet
-- yellow_tripdata_2025-08.parquet
-- yellow_tripdata_2025-09.parquet
-- yellow_tripdata_2025-10.parquet
-- yellow_tripdata_2025-11.parquet
-- yellow_tripdata_2025-12.parquet


-- Vérification du contenu du stage
LIST @NYC_TAXI_STAGE;


-- ------------------------------------------------------------
-- 3. Analyse du schéma des fichiers Parquet
-- ------------------------------------------------------------

SELECT *
FROM TABLE(
    INFER_SCHEMA(
        LOCATION => '@NYC_TAXI_STAGE',
        FILE_FORMAT => 'PARQUET_FORMAT'
    )
);


-- ------------------------------------------------------------
-- 4. Création de la table RAW
-- ------------------------------------------------------------
--
-- Les types correspondent au schéma observé dans les fichiers
-- Parquet.
--
-- Les timestamps pickup/dropoff sont conservés sous leur forme
-- brute NUMBER dans RAW. Leur conversion en TIMESTAMP est réalisée
-- uniquement dans la couche STAGING.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS YELLOW_TAXI_TRIPS (

    VENDORID NUMBER(38,0),

    TPEP_PICKUP_DATETIME NUMBER(38,0),
    TPEP_DROPOFF_DATETIME NUMBER(38,0),

    PASSENGER_COUNT NUMBER(38,0),

    TRIP_DISTANCE FLOAT,

    RATECODEID NUMBER(38,0),

    STORE_AND_FWD_FLAG VARCHAR,

    PULOCATIONID NUMBER(38,0),
    DOLOCATIONID NUMBER(38,0),

    PAYMENT_TYPE NUMBER(38,0),

    FARE_AMOUNT FLOAT,
    EXTRA FLOAT,
    MTA_TAX FLOAT,
    TIP_AMOUNT FLOAT,
    TOLLS_AMOUNT FLOAT,
    IMPROVEMENT_SURCHARGE FLOAT,
    TOTAL_AMOUNT FLOAT,
    CONGESTION_SURCHARGE FLOAT,
    AIRPORT_FEE FLOAT,
    CBD_CONGESTION_FEE FLOAT

);


-- ------------------------------------------------------------
-- 5. Chargement des 12 mois de 2025
-- ------------------------------------------------------------

COPY INTO YELLOW_TAXI_TRIPS
FROM @NYC_TAXI_STAGE
FILE_FORMAT = (
    FORMAT_NAME = 'PARQUET_FORMAT'
)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
PATTERN = '.*yellow_tripdata_2025-[0-9]{2}[.]parquet';


-- ------------------------------------------------------------
-- 6. Contrôles après ingestion
-- ------------------------------------------------------------

-- Nombre total de lignes RAW
SELECT COUNT(*) AS TOTAL_RAW_ROWS
FROM YELLOW_TAXI_TRIPS;


-- Vérification de la période brute disponible
SELECT
    MIN(
        TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6)
    ) AS MIN_PICKUP_DATETIME,

    MAX(
        TO_TIMESTAMP_NTZ(TPEP_PICKUP_DATETIME, 6)
    ) AS MAX_PICKUP_DATETIME

FROM YELLOW_TAXI_TRIPS;