-- object: refined.similar_trips | type: VIEW --
-- DROP VIEW IF EXISTS refined.similar_trips CASCADE;
CREATE VIEW refined.similar_trips
AS 

WITH trip_radius AS (
         SELECT DISTINCT trips.trip_id,
            trips.region,
	 		datetime,
            date_part('hour'::text, trips.datetime)::smallint AS hour_of_day,
            st_transform(geometry(st_buffer(trips.origin_coord, 2000)), 4326) AS origin_radius,
            st_transform(geometry(st_buffer(trips.destination_coord, 2000)), 4326) AS destination_radius,
            trips.origin_coord,
            trips.destination_coord
           FROM refined.trips
        )
 SELECT DISTINCT a.trip_id,
    a.region,
    a.datetime,
    count(*) OVER (PARTITION BY a.region, a.hour_of_day)::integer AS trips_count,
    st_centroid(st_makeline(a.origin_coord::geometry) OVER (PARTITION BY a.region, a.hour_of_day)) AS origin_centroid,
    st_centroid(st_makeline(a.destination_coord::geometry) OVER (PARTITION BY a.region, a.hour_of_day)) AS destination_centroid
   FROM trip_radius a,
    trip_radius b
  WHERE a.origin_radius && b.origin_radius 
   AND a.origin_coord <> b.origin_coord 
   AND a.destination_radius && b.destination_radius 
   AND a.destination_coord <> b.destination_coord 
   AND a.hour_of_day = b.hour_of_day;
-- ddl-end --
ALTER VIEW refined.similar_trips OWNER TO postgres;
-- ddl-end --

