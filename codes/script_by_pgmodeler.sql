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

-- object: raw_data | type: SCHEMA --
DROP SCHEMA IF EXISTS raw_data CASCADE;
CREATE SCHEMA raw_data;
-- ddl-end --
ALTER SCHEMA raw_data OWNER TO postgres;
-- ddl-end --

SET search_path TO pg_catalog,public,refined,raw_data;
-- ddl-end --

-- object: refined.regions | type: TABLE --
-- DROP TABLE IF EXISTS refined.regions CASCADE;
CREATE TABLE refined.regions (
	id serial NOT NULL,
	region varchar NOT NULL,
	CONSTRAINT regions_id_pk PRIMARY KEY (id)
);
-- ddl-end --
ALTER TABLE refined.regions OWNER TO postgres;
-- ddl-end --

INSERT INTO refined.regions (id, region) VALUES (E'1', E'Hamburg');
-- ddl-end --
INSERT INTO refined.regions (id, region) VALUES (E'2', E'Prague');
-- ddl-end --
INSERT INTO refined.regions (id, region) VALUES (E'3', E'Turin');
-- ddl-end --

-- object: refined.datasources | type: TABLE --
-- DROP TABLE IF EXISTS refined.datasources CASCADE;
CREATE TABLE refined.datasources (
	id serial NOT NULL,
	datasource varchar NOT NULL,
	CONSTRAINT datasources_id_pk PRIMARY KEY (id)
);
-- ddl-end --
ALTER TABLE refined.datasources OWNER TO postgres;
-- ddl-end --

INSERT INTO refined.datasources (id, datasource) VALUES (E'1', E'baba_car');
-- ddl-end --
INSERT INTO refined.datasources (id, datasource) VALUES (E'2', E'bad_diesel_vehicles');
-- ddl-end --
INSERT INTO refined.datasources (id, datasource) VALUES (E'3', E'cheap_mobile');
-- ddl-end --
INSERT INTO refined.datasources (id, datasource) VALUES (E'4', E'funny_car');
-- ddl-end --
INSERT INTO refined.datasources (id, datasource) VALUES (E'5', E'pt_search_app');
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
	raw_id bigserial NOT NULL,
	region_id serial NOT NULL,
	datasource_id serial NOT NULL,
	datetime timestamp,
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

-- object: raw_data.raw_trips | type: TABLE --
-- DROP TABLE IF EXISTS raw_data.raw_trips CASCADE;
CREATE TABLE raw_data.raw_trips (
	id bigserial NOT NULL,
	region varchar,
	origin_coord varchar,
	destination_coord varchar,
	datetime timestamp,
	datasource varchar,
	CONSTRAINT pk_raw_id PRIMARY KEY (id)
);
-- ddl-end --
ALTER TABLE raw_data.raw_trips OWNER TO postgres;
-- ddl-end --

-- object: refined.weekly_avg_trip | type: VIEW --
-- DROP VIEW IF EXISTS refined.weekly_avg_trip CASCADE;
CREATE VIEW refined.weekly_avg_trip
AS 

SELECT week_of_year_by_region.region_id,
    round(avg(week_of_year_by_region.count), 2) AS weekly_avg_trips
   FROM ( SELECT count(*) AS count,
            date_trunc('WEEK'::text, trips.datetime) AS week_of_year,
            trips.region_id
           FROM refined.trips
          GROUP BY (date_trunc('WEEK'::text, trips.datetime)), trips.region_id) week_of_year_by_region
  GROUP BY week_of_year_by_region.region_id;
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
	(raw_id, region_id, datasource_id, datetime, origin_coord, destination_coord)
SELECT 
 	 raw.id
	,r.id as region_id
	,ds.id as datasource_id
	,raw.datetime
	,ST_GeogFromText('SRID=4326;'||raw.origin_coord)
	,ST_GeogFromText('SRID=4326;'||raw.destination_coord)
FROM raw_data.raw_trips raw
	JOIN refined.regions r
		ON raw.region = r.region
	JOIN refined.datasources ds
		ON raw.datasource = ds.datasource
-- Only new rows from raw data.	
WHERE NOT EXISTS
		(SELECT 1
			FROM REFINED.TRIPS RT
			WHERE RT.RAW_ID = RAW.ID)
$$;
-- ddl-end --
ALTER PROCEDURE refined.load_refined_trips() OWNER TO postgres;
-- ddl-end --

-- object: refined.similar_trips | type: VIEW --
-- DROP VIEW IF EXISTS refined.similar_trips CASCADE;
CREATE VIEW refined.similar_trips
AS 

-- Creating coordinate radius to find near coordinates.
with trip_radius as (
SELECT 
 	 rt.trip_id
	,r.id as region_id
	,cast(extract(hour from rt.datetime) as smallint) as hour_of_day
	,ST_Transform(geometry(ST_Buffer(rt.origin_coord,2000)),4326) as  origin_radius
	,ST_Transform(geometry(ST_Buffer(rt.destination_coord,2000)),4326) as  destination_radius
	,rt.origin_coord
	,rt.destination_coord
FROM refined.trips rt 
	JOIN refined.regions r
		ON rt.region_id = r.id
	)
-- Grouping similar origin, destination, and same hour of day.
select 
 a.trip_id
,a.region_id
,a.hour_of_day
,cast(count(*) over (partition by a.region_id,a.hour_of_day) as int) as trips_count
,ST_Centroid(ST_MakeLine(a.origin_coord::geometry) over (partition by a.region_id,a.hour_of_day) ) AS origin_centroid
,ST_Centroid(ST_MakeLine(a.destination_coord::geometry) over (partition by a.region_id,a.hour_of_day)) AS destination_centroid	
	
from trip_radius a, trip_radius b
where 
	(
		(a.origin_radius && b.origin_radius and a.origin_coord != b.origin_coord)
	and	(a.destination_radius && b.destination_radius and a.destination_coord != b.destination_coord)
	and (a.hour_of_day = b.hour_of_day) 
	);
-- ddl-end --
ALTER VIEW refined.similar_trips OWNER TO postgres;
-- ddl-end --

-- object: fk_trips_id_region | type: CONSTRAINT --
-- ALTER TABLE refined.trips DROP CONSTRAINT IF EXISTS fk_trips_id_region CASCADE;
ALTER TABLE refined.trips ADD CONSTRAINT fk_trips_id_region FOREIGN KEY (region_id)
REFERENCES refined.regions (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_datasource_id | type: CONSTRAINT --
-- ALTER TABLE refined.trips DROP CONSTRAINT IF EXISTS fk_datasource_id CASCADE;
ALTER TABLE refined.trips ADD CONSTRAINT fk_datasource_id FOREIGN KEY (datasource_id)
REFERENCES refined.datasources (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_raw_id | type: CONSTRAINT --
-- ALTER TABLE refined.trips DROP CONSTRAINT IF EXISTS fk_raw_id CASCADE;
ALTER TABLE refined.trips ADD CONSTRAINT fk_raw_id FOREIGN KEY (raw_id)
REFERENCES raw_data.raw_trips (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
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


