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
ALTER TABLE refined.trips OWNER TO postgres;
-- ddl-end --

