export PGPASSWORD=postgres
psql -U postgres -h localhost -d trips_db -c 'truncate table raw_data.raw_trips;'
time psql -U postgres -h localhost -d trips_db -c "\copy raw_data.raw_trips FROM '/tmp/files/trips.csv' DELIMITER ',' CSV HEADER ESCAPE '''';"