input_dir=/tmp/files/
input_file=trips.csv
dest_table=raw_data.raw_trips

if [ -f ${input_dir}${input_file} ]; then

    echo "Loading $file to $dest_table.."

    /usr/bin/time -f "%E"  psql -U postgres -h localhost -d trips_db -c "\copy $dest_table (region,origin_coord,destination_coord,datetime,datasource) 
    FROM '${input_dir}${input_file}' DELIMITER ',' CSV HEADER ESCAPE '''';"
    RC=$?

    if [ $RC -eq 0 ];  then
        mv /tmp/files/trips.csv /tmp/files/processed/trips.csv_`date +%Y%m%d-%H%M%S`
        echo "Inserting new rows to refined.trips.."
        /usr/bin/time -f "%E" psql -U postgres -h localhost -d trips_db -c "call refined.load_refined_trips();"
    fi
    
    else echo "No trips.csv file in folder."
fi