input_dir=/tmp/files/
input_file=trips.csv
dest_table=stg_data.stg_trips

if [ -f ${input_dir}${input_file} ]; then

    # Truncate stg table.
    psql -U postgres -h localhost -d trips_db -c "truncate table $dest_table;"

    echo -e "Loading $file to $dest_table..\n"

    # Copy from file to stg table.
    /usr/bin/time -f "%E"  psql -U postgres -h localhost -d trips_db -c "\copy $dest_table (region,origin_coord,destination_coord,datetime,datasource) 
    FROM '${input_dir}${input_file}' DELIMITER ',' CSV HEADER ESCAPE '''';"
    RC=$?

    if [ $RC -eq 0 ];  then
        mv /tmp/files/trips.csv /tmp/files/processed/trips.csv_`date +%Y%m%d-%H%M%S`
        echo -e "Moving file to processed\n"
        echo -e "Inserting new rows to refined.trips..\n"

        # Insert table.
        /usr/bin/time -f "%E" psql -U postgres -h localhost -d trips_db -c "call refined.load_refined_trips();"
        
        # Truncate stg table.
        psql -U postgres -h localhost -d trips_db -c "truncate table $dest_table;"
    fi

    else echo -e "No trips.csv file in folder."
fi