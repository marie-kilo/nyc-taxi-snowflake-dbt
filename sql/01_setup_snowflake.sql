-- ============================================================
-- NYC Taxi Data Warehouse
-- 01 - Snowflake infrastructure setup
-- ============================================================

-- Rôle utilisé pour le projet
USE ROLE ACCOUNTADMIN;

-- Warehouse utilisé pour les traitements
USE WAREHOUSE COMPUTE_WH;

-- Création de la base principale
CREATE DATABASE IF NOT EXISTS NYC_TAXI_DB;

USE DATABASE NYC_TAXI_DB;

-- Couche RAW : données brutes importées
CREATE SCHEMA IF NOT EXISTS RAW;

-- Couche STAGING : données nettoyées et transformées
CREATE SCHEMA IF NOT EXISTS STAGING;

-- Couche FINAL : tables analytiques
CREATE SCHEMA IF NOT EXISTS FINAL;