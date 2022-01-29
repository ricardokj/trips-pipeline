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
	id smallserial NOT NULL,
	region varchar,
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
	id bigserial NOT NULL,
	region_id smallserial,
	datasource_id serial,
	datetime timestamp NOT NULL,
	origin geometry NOT NULL,
	destination geometry NOT NULL,
	CONSTRAINT pk_id_trips PRIMARY KEY (id)
);
-- ddl-end --
ALTER TABLE refined.trips OWNER TO postgres;
-- ddl-end --

-- object: raw_data.raw_trips | type: TABLE --
-- DROP TABLE IF EXISTS raw_data.raw_trips CASCADE;
CREATE TABLE raw_data.raw_trips (
	region varchar,
	origin_coord varchar,
	destination_coord varchar,
	datetime timestamp,
	datasource varchar

)
PARTITION BY RANGE ((date_part('year'::text, datetime)));
-- ddl-end --
ALTER TABLE raw_data.raw_trips OWNER TO postgres;
-- ddl-end --

-- Appended SQL commands --
CREATE TABLE raw_data."2012" PARTITION OF raw_data.raw_trips FOR VALUES FROM ('2012') TO ('2014');
ALTER TABLE IF EXISTS raw_data."2012"   OWNER to postgres;

CREATE TABLE raw_data."2014" PARTITION OF raw_data.raw_trips FOR VALUES FROM ('2014') TO ('2016');
ALTER TABLE IF EXISTS raw_data."2014"   OWNER to postgres;

CREATE TABLE raw_data."2016" PARTITION OF raw_data.raw_trips FOR VALUES FROM ('2016') TO ('2018');
ALTER TABLE IF EXISTS raw_data."2016"   OWNER to postgres;

CREATE TABLE raw_data."2018" PARTITION OF raw_data.raw_trips FOR VALUES FROM ('2018') TO ('2020');
ALTER TABLE IF EXISTS raw_data."2018"   OWNER to postgres;

CREATE TABLE raw_data."2020" PARTITION OF raw_data.raw_trips FOR VALUES FROM ('2020') TO ('2022');
ALTER TABLE IF EXISTS raw_data."2020"   OWNER to postgres;
-- ddl-end --

-- object: fk_id_region | type: CONSTRAINT --
-- ALTER TABLE refined.trips DROP CONSTRAINT IF EXISTS fk_id_region CASCADE;
ALTER TABLE refined.trips ADD CONSTRAINT fk_id_region FOREIGN KEY (region_id)
REFERENCES refined.regions (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: fk_id_datasources | type: CONSTRAINT --
-- ALTER TABLE refined.trips DROP CONSTRAINT IF EXISTS fk_id_datasources CASCADE;
ALTER TABLE refined.trips ADD CONSTRAINT fk_id_datasources FOREIGN KEY (datasource_id)
REFERENCES refined.datasources (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --


