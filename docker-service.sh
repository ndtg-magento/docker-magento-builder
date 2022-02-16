#!/bin/bash -e

get_host() {
  echo "$1" | awk -F':' '{print $1}'
}

get_port() {
  echo "$1" | awk -F':' '{print $2}'
}

has_domain() {
  if [ $(ping -c1 "$1" 1>/dev/null 2>/dev/null) ]; then
    echo 1
  else
    echo 0
  fi
}

create_network() {
  docker network rm builder || true
  docker network create -d bridge --subnet 192.168.16.0/24 builder || true
}

remove_mysql() {
  MYSQL_HOST=$(get_host "$1")

  docker stop "$MYSQL_HOST" || true
  docker rm "$MYSQL_HOST" || true
}

remove_redis() {
  REDIS_HOST=$(get_host "$1")

  docker stop "$REDIS_HOST" || true
  docker rm "$REDIS_HOST" || true
}

remove_elasticsearch() {
  ELASTICSEARCH_HOST=$(get_host "$1")

  docker stop "$ELASTICSEARCH_HOST" || true
  docker rm "$ELASTICSEARCH_HOST" || true
}

run_mysql() {
  MYSQL_HOST=$(get_host "$1")
  MYSQL_ROOT_PASSWORD=$2
  MYSQL_USER=$3
  MYSQL_PASSWORD=$4
  MYSQL_DATABASE=$5

  remove_mysql "$1"
  docker run --name "$MYSQL_HOST" --network builder \
    --health-cmd='mysqladmin ping -h localhost --silent' \
	  -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
	  -e MYSQL_USER="$MYSQL_USER" \
	  -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
	  -e MYSQL_DATABASE="$MYSQL_DATABASE" \
	  -d mariadb:10.4
}

run_redis() {
  REDIS_HOST=$(get_host "$1")

  remove_redis "$1"
  docker run --name "$REDIS_HOST" --network builder \
    --health-cmd='redis-cli ping' \
    -d redis:alpine
}

run_elasticsearch() {
  ELASTICSEARCH_HOST=$(get_host "$1")

  remove_elasticsearch "$1"
  docker run --name "$ELASTICSEARCH_HOST" --network builder \
    --health-cmd='localhost:9200/_cluster/health?wait_for_status=green&timeout=1s' \
    -e "discovery.type=single-node" \
    -d elasticsearch:7.10.1
}

waiting_service() {
  HOST=$1
  PORT=$2

  until nc -vzw 2 "${HOST}" "${PORT}" || [ "`docker inspect -f '{{.State.Health.Status}}' ${HOST}`" == "healthy" ]
  do
      note "Waiting for ${HOST}:${PORT} connection..."
      # wait for 5 seconds before check again
      sleep 5
  done

  note "${HOST}:${PORT} connected."
}
