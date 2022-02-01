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

