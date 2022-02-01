-- object: refined.weekly_avg_trip | type: VIEW --
-- DROP VIEW IF EXISTS refined.weekly_avg_trip CASCADE;
CREATE VIEW refined.weekly_avg_trip
AS 

SELECT week_of_year_by_region.region,
    round(avg(week_of_year_by_region.count), 2) AS weekly_avg_trips
   FROM ( SELECT count(*) AS count,
            date_trunc('WEEK', trips.datetime) AS week_of_year,
            trips.region
           FROM refined.trips
          GROUP BY (date_trunc('WEEK', trips.datetime)), trips.region) week_of_year_by_region
  GROUP BY week_of_year_by_region.region;
-- ddl-end --
ALTER VIEW refined.weekly_avg_trip OWNER TO postgres;
-- ddl-end --

