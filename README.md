![Docker Stars](https://img.shields.io/docker/stars/ntuangiang/magento.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/ntuangiang/magento.svg)
![Docker Automated build](https://img.shields.io/docker/automated/ntuangiang/magento.svg)

# Magento 2.3.3 Docker

[https://devdocs.magento.com](https://devdocs.magento.com) Meet the small business, mid-sized business, and enterprise-level companies who are benefiting from the power and flexibility of Magento on their web stores. We built the eCommerce platform, so you can build your business.

## Docker Repository
[ntuangiang/magento](https://hub.docker.com/r/ntuangiang/magento) 
## Usage
## Developer
- Write a `Dockerfile` file.

```Dockerfile
FROM ntuangiang/magento:2.3.3-develop as magento-php-fpm

COPY --chown=magento:magento ./composer.* ${DOCUMENT_ROOT}/

RUN sh /rootfs/magento-composer-installer

COPY --chown=magento:magento ./app ${DOCUMENT_ROOT}/

WORKDIR ${DOCUMENT_ROOT}

# --- Install Nginx ---

FROM ntuangiang/magento-nginx as magento-nginx

COPY --from=magento-php-fpm \
    ${DOCUMENT_ROOT}/ \
    ${DOCUMENT_ROOT}/

WORKDIR ${NGINX_DOCUMENT_ROOT}
```
- Changing DocumentRoot

```Dockerfile
FROM ntuangiang/magento:2.3.3-develop as magento-php-fpm

ENV MAGENTO_UPDATE_PACKAGE=true
ENV DOCUMENT_ROOT=/yourDir

COPY --chown=magento:magento ./composer.* ${DOCUMENT_ROOT}/

RUN sh /rootfs/magento-composer-installer

COPY --chown=magento:magento ./app ${DOCUMENT_ROOT}/

RUN composer clear-cache

WORKDIR ${DOCUMENT_ROOT}

# --- Install Nginx ---

FROM ntuangiang/magento-nginx as magento-nginx

ENV NGINX_DOCUMENT_ROOT=/yourDir

COPY --from=magento-php-fpm \
    ${NGINX_DOCUMENT_ROOT}/ \
    ${NGINX_DOCUMENT_ROOT}/

WORKDIR ${NGINX_DOCUMENT_ROOT}
```

- Write `docker-compose.env` to config container.

```env
# XDebug
XDEBUG_CONFIG=remote_host=host.docker.internal idekey=PHPSTORM remote_port=9000 remote_enable=1 remote_autostart=1

# Install New
#DOCUMENT_ROOT=
MAGENTO_INSTALL_NEW=true
MAGENTO_UPDATE_PACKAGE=true
MAGENTO_SAMPLEDATA_INSTALL=false
#MAGENTO_CRONTAB_DISABLED=true

# Magento 2 Admin Account
#MAGENTO_ADMIN_USER=admin
MAGENTO_ADMIN_PWD=admin123

MAGENTO_BASE_URL=http://magento2.dev.traefik

# Database Config
MAGENTO_DATABASE_HOST=m2db
#MAGENTO_DATABASE_PORT=3306
#MAGENTO_DATABASE_USER=root
MAGENTO_DATABASE_PWD=root
MAGENTO_DATABASE_DB=magento2


# MAGENTO REDIS
MAGENTO_CACHE_REDIS_HOST=m2redis
#MAGENTO_CACHE_REDIS_PORT=6379

# MAGENTO VARNISH
VARNISH_CACHE_ENABLED=true
VARNISH_HTTP_CACHE_HOST=host.docker.internal,m2nginx

# MAGENTO MODE
MAGENTO_MODE=developer

# Order
#MAGENTO_GENERATE_DEVELOP_MODE=true
#MAGENTO_MINIFY_STATIC_FILE=true
#MAGENTO_REFRESH_ALL_PERMISSION
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
      - traefik.frontend.rule=Host:magento2.dev.traefik;PathPrefix:/
    networks:
      - traefik

  m2nginx:
    image: ntuangiang/magento-nginx:build
    volumes:
      - ./:/home/tuangiang/PhpstormProjects/template
    environment:
      - NGINX_BACKEND_HOST=m2php
      - MAGE_MODE=developer
    networks:
      - backend
      - traefik

  m2php:
    image: ntuangiang/magento-php:build
    env_file: docker-compose.env
    volumes:
      - ./:/home/tuangiang/PhpstormProjects/template
    networks:
      - backend

  m2db:
    image: mysql
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - /yourDir:/var/lib/mysql
    ports:
      - '2336:3306'
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=magento2
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

## LICENSE

MIT License