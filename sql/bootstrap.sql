DROP DATABASE IF EXISTS podiumdb;
CREATE DATABASE podiumdb
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

SOURCE sql/schema/001_core_schema.sql;
SOURCE sql/routines/001_routines_and_triggers.sql;
SOURCE sql/seed/001_synthetic_competition.sql;
SOURCE sql/analytics/001_views.sql;

