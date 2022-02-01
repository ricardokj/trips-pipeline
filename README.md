# Trips Pipeline Container
Container used to ingest CSV file to PostgreSQL environment.

## Getting Started

### Prerequisities


In order to run this container you'll need docker installed.

* [Windows](https://docs.docker.com/desktop/windows/)
* [OS X](https://docs.docker.com/desktop/mac/)
* [Linux](https://docs.docker.com/engine/install/)

Build and run these images locally:
* postgis:11-2.5-alpine
* dpage/pgadmin4

### Building and starting containerized environment
```shell
docker-compose up
```
#### Run script to import [trips.csv](https://github.com/ricardokj/trips-pipeline/blob/9dc2207846ba805cda480a5f83fe56de498c1158/input_file/trips.csv) file 
```shell
docker-compose exec postgis bash /tmp/codes/import.sh
```
#### Volumes

* `./codes/` - Code location
* `./input_file/` - File location

## Accessing
* http://localhost:16543
* Login on pgAdmin4 page: postgres@gmail.com
* Password on pgAdmin4 page: postgres

## Features
* There must be an automated process to ingest and store the data.
  *  Automated process built to import on-demand basis
* Trips with similar origin, destination, and time of day should be grouped together.
  *  Created a view, considering a 2 km radius to similar coordinates for trips at the same hour.
* Develop a way to obtain the weekly average number of trips for an area, defined by a bounding box (given by coordinates) or by a region.
  * Created a view grouped by region. The view could have a filter to select the last 12 months and to retrieve an up to date report.
* Develop a way to inform the user about the status of the data ingestion without using a polling solution.
  * Not finished.
* The solution should be scalable to 100 million entries. It is encouraged to simplify the data by a data model. Please add proof that the solution is scalable.
* Use a SQL database.
  * PostgreSQL used with PostGis extension.

# ERD
![erd](misc/ERD.png "erd")
