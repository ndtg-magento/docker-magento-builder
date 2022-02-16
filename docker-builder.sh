#!/bin/bash -e
export DOCKER_BUILDKIT=0

. ./docker-logger.sh
. ./docker-service.sh

# Domain
MAGENTO_BASE_URL="magento.local.dev"

# Mysql Params
MYSQL_ROOT_PASSWORD="root"
MYSQL_USER="magento"
MYSQL_PASSWORD="magento@123"
MYSQL_DATABASE="magento"

# Dns
MYSQL_DNS="mariadb-from-builder:3306"
REDIS_DNS="redis-from-builder:6379"
ELASTICSEARCH_DNS="elasticsearch-from-builder:9200"

# Image Tag
CI_APPLICATION_REPOSITORY="ntuangiang/magento"
CI_APPLICATION_TAG="2.4.3-p1"

_dump_database() {
  docker exec -it mysql-from-builder mysqldump -u"$1" -p"$2" "$3" | gzip > magento.sql.gz
}

_waiting_service_ready() {
  HOST_DOMAIN="127.0.0.1"

  PUBLIC_IP="192.168.0.155"

  MAGENTO_BASE_URL=$1

  MAGENTO_CACHE_REDIS_HOST=$(get_host "$2")
  MAGENTO_CACHE_REDIS_PORT=$(get_port "$2")

  MAGENTO_SEARCH_ENGINE_HOST=$(get_host "$3")
  MAGENTO_SEARCH_ENGINE_PORT=$(get_port "$3")

  MAGENTO_DATABASE_HOST=$(get_host "$4")
  MAGENTO_DATABASE_PORT=$(get_port "$4")

  waiting_service "$MAGENTO_CACHE_REDIS_HOST" "$MAGENTO_CACHE_REDIS_PORT"
  note "[i] Redis already now."

  waiting_service "$MAGENTO_DATABASE_HOST" "$MAGENTO_DATABASE_PORT"
  note "[i] Database already now."

  waiting_service "$MAGENTO_SEARCH_ENGINE_HOST" "$MAGENTO_SEARCH_ENGINE_PORT"
  note "[i] Elasticsearch already now."

  note "[i] Sleeping 3 sec before setup."
  sleep 3
}

_main() {
  IMAGE_TAGGED="$CI_APPLICATION_REPOSITORY-nginx:$CI_APPLICATION_TAG"
  IMAGE_PHPFPM_TAGGED="$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG"

  create_network
  run_redis "$2"
  run_elasticsearch "$3"
  run_mysql "$4" "$5" "$6" "$7" "$8"

  _waiting_service_ready "$1" "$2" "$3" "$4"

  note "Attempting to pull a previously built image for use with --cache-from..."
  # shellcheck disable=SC2154 # missing variable warning for the lowercase variables
  # shellcheck disable=SC2086 # double quoting for globbing warning for $build_secret_args and $AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS
  
  docker build -f "$DOCKERFILE_PATH" --network builder --tag "$IMAGE_TAGGED" . --target "magento-nginx"

  docker build -f "$DOCKERFILE_PATH" --network builder --tag "$IMAGE_PHPFPM_TAGGED" . --target "magento-phpfpm"

   _dump_database $MYSQL_USER $MYSQL_PASSWORD $MYSQL_DATABASE

  remove_mysql
  remove_redis
  remove_elasticsearch

  docker push "$IMAGE_TAGGED"
  docker push "$IMAGE_PHPFPM_TAGGED"
}

_main "$MAGENTO_BASE_URL" $REDIS_DNS $ELASTICSEARCH_DNS $MYSQL_DNS $MYSQL_ROOT_PASSWORD $MYSQL_USER $MYSQL_PASSWORD $MYSQL_DATABASE

