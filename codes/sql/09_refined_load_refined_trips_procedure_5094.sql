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

