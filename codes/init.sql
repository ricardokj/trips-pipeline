-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler version: 0.9.4
-- PostgreSQL version: 13.0
-- Project Site: pgmodeler.io
-- Model Author: ---

-- Database creation must be performed outside a multi lined SQL file. 
-- These commands were put in this file only as a convenience.
-- 
-- object: trips_db | type: DATABASE --
-- DROP DATABASE IF EXISTS trips_db;
-- CREATE DATABASE trips_db;
-- ddl-end --


-- object: refined | type: SCHEMA --
DROP SCHEMA IF EXISTS refined CASCADE;
CREATE SCHEMA refined;
-- ddl-end --
ALTER SCHEMA refined OWNER TO postgres;
-- ddl-end --

-- object: stg_data | type: SCHEMA --
DROP SCHEMA IF EXISTS stg_data CASCADE;
CREATE SCHEMA stg_data;
-- ddl-end --
ALTER SCHEMA stg_data OWNER TO postgres;
-- ddl-end --

SET search_path TO pg_catalog,public,refined,stg_data;
-- ddl-end --

-- object: postgis | type: EXTENSION --
DROP EXTENSION IF EXISTS postgis CASCADE;
CREATE EXTENSION postgis
WITH SCHEMA public;
-- ddl-end --

-- object: refined.trips | type: TABLE --
-- DROP TABLE IF EXISTS refined.trips CASCADE;
CREATE TABLE refined.trips (
	trip_id bigserial NOT NULL,
	datetime timestamp,
	region varchar NOT NULL,
	datasource varchar NOT NULL,
	origin_coord geography,
	destination_coord geography,
	CONSTRAINT pk_id_trips PRIMARY KEY (trip_id)
);
-- ddl-end --
COMMENT ON COLUMN refined.trips.origin_coord IS E'Origin coordinates or centroid of coordinates when the trips are grouped.';
-- ddl-end --
COMMENT ON COLUMN refined.trips.destination_coord IS E'Origin coordinates or centroid of coordinates when the trips are grouped.';
-- ddl-end --
ALTER TABLE refined.trips OWNER TO postgres;
-- ddl-end --

-- object: stg_data.stg_trips | type: TABLE --
-- DROP TABLE IF EXISTS stg_data.stg_trips CASCADE;
CREATE UNLOGGED TABLE stg_data.stg_trips (
	region varchar,
	origin_coord varchar,
	destination_coord varchar,
	datetime timestamp,
	datasource varchar

);
-- ddl-end --
ALTER TABLE stg_data.stg_trips OWNER TO postgres;
-- ddl-end --

-- object: refined.weekly_avg_trip | type: VIEW --
-- DROP VIEW IF EXISTS refined.weekly_avg_trip CASCADE;
CREATE VIEW refined.weekly_avg_trip
AS 

SELECT week_of_year_by_region.region,
    round(avg(week_of_year_by_region.count), 2) AS weekly_avg_trips
   FROM ( SELECT count(*) AS count,
            date_trunc('WEEK'::text, trips.datetime) AS week_of_year,
            trips.region
           FROM refined.trips
          GROUP BY (date_trunc('WEEK'::text, trips.datetime)), trips.region) week_of_year_by_region
  GROUP BY week_of_year_by_region.region;
-- ddl-end --
ALTER VIEW refined.weekly_avg_trip OWNER TO postgres;
-- ddl-end --

-- object: refined.load_refined_trips | type: PROCEDURE --
-- DROP PROCEDURE IF EXISTS refined.load_refined_trips() CASCADE;
CREATE PROCEDURE refined.load_refined_trips ()
	LANGUAGE sql
	SECURITY INVOKER
	AS $$
INSERT INTO refined.trips
	(region, datasource, datetime, origin_coord, destination_coord)
SELECT 
     region
	,datasource
	,datetime
	,ST_GeogFromText('SRID=4326;'||origin_coord)
	,ST_GeogFromText('SRID=4326;'||destination_coord)
FROM stg_data.stg_trips
$$;
-- ddl-end --
ALTER PROCEDURE refined.load_refined_trips() OWNER TO postgres;
-- ddl-end --

-- object: refined.similar_trips | type: VIEW --
-- DROP VIEW IF EXISTS refined.similar_trips CASCADE;
CREATE VIEW refined.similar_trips
AS 

WITH trip_radius AS (
         SELECT DISTINCT trips.trip_id,
            trips.region,
            (date_part('hour'::text, trips.datetime))::smallint AS hour_of_day,
            st_transform(geometry(st_buffer(trips.origin_coord, (2000)::double precision)), 4326) AS origin_radius,
            st_transform(geometry(st_buffer(trips.destination_coord, (2000)::double precision)), 4326) AS destination_radius,
            trips.origin_coord,
            trips.destination_coord
           FROM refined.trips
        )
 SELECT DISTINCT a.trip_id,
    a.region,
    a.hour_of_day,
    (count(*) OVER (PARTITION BY a.region, a.hour_of_day))::integer AS trips_count,
    st_centroid(st_makeline((a.origin_coord)::geometry) OVER (PARTITION BY a.region, a.hour_of_day)) AS origin_centroid,
    st_centroid(st_makeline((a.destination_coord)::geometry) OVER (PARTITION BY a.region, a.hour_of_day)) AS destination_centroid
   FROM trip_radius a,
    trip_radius b
  WHERE ((a.origin_radius && b.origin_radius) AND ((a.origin_coord)::bytea <> (b.origin_coord)::bytea) AND ((a.destination_radius && b.destination_radius) AND ((a.destination_coord)::bytea <> (b.destination_coord)::bytea)) AND (a.hour_of_day = b.hour_of_day));
-- ddl-end --
ALTER VIEW refined.similar_trips OWNER TO postgres;
-- ddl-end --

-- object: "grant_CU_eb94f049ac" | type: PERMISSION --
GRANT CREATE,USAGE
   ON SCHEMA public
   TO postgres;
-- ddl-end --

-- object: "grant_CU_cd8e46e7b6" | type: PERMISSION --
GRANT CREATE,USAGE
   ON SCHEMA public
   TO PUBLIC;
-- ddl-end --


