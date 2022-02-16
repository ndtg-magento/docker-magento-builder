#!/bin/bash -e

. ./.gitlab-ci/docker-logger.sh
. ./.gitlab-ci/docker-service.sh

# Domain
MAGENTO_BASE_URL="dungmoc.ntugi.com"

# Mysql Params
MYSQL_ROOT_PASSWORD="tuangiang"
MYSQL_USER="dungmoc"
MYSQL_PASSWORD="dungmoc"
MYSQL_DATABASE="dungmoc"
MYSQL_DNS="production-auto-deploy.mysql-24612894-production:3306"

# Redis
REDIS_DNS="production-auto-deploy.redis-24564346-production:6379"

# Elasticsearch
ELASTICSEARCH_DNS="elasticsearch-filmhouse.ntugi.com:9200"

_dump_database() {
  docker exec -it mysql-from-builder mysqldump -u"$1" -p"$2" "$3" | gzip > magento2.sql.gz
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

  if [ "${MAGENTO_BASE_URL}" != "$HOST_DOMAIN" ]; then
    BASE_URL=${MAGENTO_BASE_URL#*//}
    BASE_URL=${BASE_URL%/*}

    echo -e "$PUBLIC_IP\t$BASE_URL" >> /etc/hosts
  fi

  if [ "$MAGENTO_DATABASE_HOST" != "$HOST_DOMAIN" ]; then
    echo -e "$PUBLIC_IP\t$MAGENTO_DATABASE_HOST" >> /etc/hosts
  fi
  
  if [ "$MAGENTO_CACHE_REDIS_HOST" != "$HOST_DOMAIN" ]; then
    echo -e "$PUBLIC_IP\t$MAGENTO_CACHE_REDIS_HOST" >> /etc/hosts
  fi

  if [ "$MAGENTO_SEARCH_ENGINE_HOST" != "$HOST_DOMAIN" ]; then
    echo -e "$PUBLIC_IP\t$MAGENTO_SEARCH_ENGINE_HOST" >> /etc/hosts
  fi

  cat /etc/hosts

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
  IMAGE_TAGGED="$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG"
  IMAGE_PHPFPM_TAGGED="$CI_APPLICATION_REPOSITORY-phpfpm:$CI_APPLICATION_TAG"

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

  # _dump_database $MYSQL_USER $MYSQL_PASSWORD $MYSQL_DATABASE
  remove_mysql
  remove_redis
  remove_elasticsearch

  docker push "$IMAGE_TAGGED"
  docker push "$IMAGE_PHPFPM_TAGGED"
}

# Custom Variables
DOCKER_USER="ntuangiang"

DOCKER_PASSWORD="Thaongan12"

NODE_ARCH=$([ "$CI_RUNNER_EXECUTABLE_ARCH" == "linux/arm64" ] && echo "arm64v8" || echo "amd64")
echo "NODE_ARCH: $NODE_ARCH"

if [[ -z "$CI_COMMIT_TAG" ]]; then
    export CI_APPLICATION_REPOSITORY=${CI_APPLICATION_REPOSITORY:-$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG}
    export CI_APPLICATION_TAG=${CI_APPLICATION_TAG:-$CI_COMMIT_SHA}
else
    export CI_APPLICATION_REPOSITORY=${CI_APPLICATION_REPOSITORY:-$CI_REGISTRY_IMAGE}
    export CI_APPLICATION_TAG=${CI_APPLICATION_TAG:-$CI_COMMIT_TAG}
fi

# Build stage script for Auto-DevOps

if ! docker info &>/dev/null; then
  if [ -z "$DOCKER_HOST" ] && [ "$KUBERNETES_PORT" ]; then
    export DOCKER_HOST='tcp://localhost:2375'
  fi
fi

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USER" --password-stdin

if [[ -n "$CI_REGISTRY" && -n "$CI_REGISTRY_USER" ]]; then
  echo "Logging to GitLab Container Registry with CI credentials..."
  echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
fi

if [[ -n "${DOCKERFILE_PATH}" ]]; then
  echo "Building Dockerfile-based application using '${DOCKERFILE_PATH}'..."
else
  export DOCKERFILE_PATH="Dockerfile"

  if [[ -f "${DOCKERFILE_PATH}" ]]; then
    echo "Building Dockerfile-based application..."
  else
    echo "Building Heroku-based application using gliderlabs/herokuish docker image..."
    erb -T - /build/Dockerfile.erb > "${DOCKERFILE_PATH}"
  fi
fi

_main "$MAGENTO_BASE_URL" $REDIS_DNS $ELASTICSEARCH_DNS $MYSQL_DNS $MYSQL_ROOT_PASSWORD $MYSQL_USER $MYSQL_PASSWORD $MYSQL_DATABASE

