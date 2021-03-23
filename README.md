![Docker Stars](https://img.shields.io/docker/stars/ntuangiang/magento.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/ntuangiang/magento.svg)
![Docker Automated build](https://img.shields.io/docker/automated/ntuangiang/magento.svg)

# Magento 2.4.2 Docker

[https://devdocs.magento.com](https://devdocs.magento.com) Meet the small business, mid-sized business, and enterprise-level companies who are benefiting from the power and flexibility of Magento on their web stores. We built the eCommerce platform, so you can build your business.

## Docker Repository
[ntuangiang/magento](https://hub.docker.com/r/ntuangiang/magento) 
## Usage
## Developer
- Write a `Dockerfile` file.

```Dockerfile
FROM ntuangiang/magento-cache:2.4.2 as magento-build

ENV MAGENTO_MODE=production

ENV MAGENTO_DATABASE_HOST=127.0.0.1
ENV MAGENTO_DATABASE_USER=magento2
ENV MAGENTO_DATABASE_PWD=magento2
ENV MAGENTO_DATABASE_DB=magento2
ENV MAGENTO_ADMIN_PWD=magento2
ENV MAGENTO_CACHE_REDIS_HOST=127.0.0.1
ENV MAGENTO_BASE_URL=http://magento2.dev.traefik
ENV MAGENTO_BASE_URL_SECURE=https://magento2.dev.traefik

COPY --chown=magento:magento ./composer.* ${DOCUMENT_ROOT}/

RUN magento:install

COPY --chown=magento:magento ./app/ ${DOCUMENT_ROOT}/app/

RUN magento:setup

FROM ntuangiang/magento:2.4.2 as magento-php-fpm

COPY --from=magento-build --chown=magento:magento \
    ${DOCUMENT_ROOT}/ \
    ${DOCUMENT_ROOT}/
```
- Write `docker-compose.yml` to start services.

```yml
version: '3.7'

services:
  m2varnish:
    image: ntuangiang/magento-varnish
    environment:
      - VARNISH_BACKEND_PORT=80
      - VARNISH_PURGE_HOST=m2nginx
      - VARNISH_BACKEND_HOST=m2nginx
      - VARNISH_HEALTH_CHECK_FILE=/health_check.php
    labels:
      - traefik.port=80
      - traefik.enable=true
      - traefik.docker.network=traefik_proxy
      - traefik.frontend.entryPoints=https,http
      - traefik.frontend.rule=Host:magento2.sql.dev.traefik;PathPrefix:/
    networks:
      - traefik

  m2nginx:
    image: ntuangiang/magento-nginx:build
    volumes:
      - ./pub/media:/usr/share/nginx/html/pub/media
    environment:
      - NGINX_BACKEND_HOST=m2php
      - MAGE_MODE=production
    networks:
      - backend
      - traefik

  m2php:
    image: ntuangiang/magento-php:build
    environment:
      # Database Config
      - MAGENTO_DATABASE_HOST=m2db
      - MAGENTO_DATABASE_PORT=3306
      - MAGENTO_DATABASE_USER=root
      - MAGENTO_DATABASE_PWD=root
      - MAGENTO_DATABASE_DB=magento2.sql
      - MAGENTO_MINIFY_STATIC_FILE=false
      # MAGENTO REDIS
      - MAGENTO_CACHE_REDIS_HOST=m2redis
      - MAGENTO_CACHE_REDIS_PORT=6379
      # MAGENTO VARNISH
      - MAGENTO_HTTP_CACHE_HOSTS=m2nginx:80
    volumes:
      - ./pub/media:/usr/share/nginx/html/pub/media
    networks:
      - backend

  m2db:
    image: mysql
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - ./data/db:/var/lib/mysql
    ports:
      - '2336:3306'
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=magento2.sql
    networks:
      - backend

  m2redis:
    image: redis:alpine
    networks:
      - backend

networks:
  backend:
  traefik:
    external:
      name: traefik_proxy
```

- Build Images

```shell
docker build -t ntuangiang/magento-php:build . --target=magento-php-fpm
docker build -t ntuangiang/magento-nginx:build . --target=magento-nginx
```

- Start Services

```yml
docker-compose up 
```
 - Or
 
 ```yml
 docker-compose up -d 
 ```
## LICENSE

MIT License
