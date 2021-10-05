#!/bin/bash
if [ ! -d db ]; then
  echo "First start: docker-compose -f docker-compose_guacamole.yml up -d"
  exit
fi
docker run --rm lprat/guacamole-client /opt/guacamole/bin/initdb.sh --postgres > ./db/initdb.sql
docker-compose exec postgres createdb -U guacamole guacamole_db
docker-compose exec postgres psql -U guacamole -d guacamole_db -f /db/initdb.sql
chown -R 1000.1000 `grep 'LOCAL_PATH_RECORD' .env |awk -F '=' '{print $2}'`
chown -R 1000.1000 `grep 'LOCAL_PATH_RDP' .env |awk -F '=' '{print $2}'`
