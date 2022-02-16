FROM registry.gitlab.com/filmhouse/dungmoc/master-cached:latest as magento-builder

COPY ./composer.* ${DOCUMENT_ROOT}/

RUN cd $DOCUMENT_ROOT && composer install --no-ansi --no-interaction --optimize-autoloader --no-dev --prefer-dist 2>&1

ENV MAGENTO_MODE=production

# Database Configuration
ENV MAGENTO_DATABASE_HOST=mariadb-from-builder
ENV MAGENTO_DATABASE_PORT=3306
ENV MAGENTO_DATABASE_USER=dungmoc
ENV MAGENTO_DATABASE_PWD=dungmoc
ENV MAGENTO_DATABASE_DB=dungmoc

# Magento Setup
ENV MAGENTO_ADMIN_FIRSTNAME=System
ENV MAGENTO_ADMIN_LASTNAME=Manage
ENV MAGENTO_ADMIN_USER=dungmoc
ENV MAGENTO_ADMIN_PWD=dungmoc@123
ENV MAGENTO_ADMIN_EMAIL=ntuangiang@outlook.com

# Cache
ENV MAGENTO_CACHE_REDIS_HOST=redis-from-builder

# Search Engine
ENV MAGENTO_SEARCH_ENGINE_HOST=elasticsearch-from-builder
ENV MAGENTO_SEARCH_ENGINE=elasticsearch7
ENV MAGENTO_SEARCH_ENGINE_PORT=9200

# Url
ENV MAGENTO_BASE_URL=http://dungmoc.ntugi.com
ENV MAGENTO_BASE_URL_SECURE=https://dungmoc.ntugi.com

COPY ./auth.json "${DOCUMENT_ROOT}"/var/composer_home/composer.json
COPY ./app/design "${DOCUMENT_ROOT}"/app/design
COPY ./app/code "${DOCUMENT_ROOT}"/app/code

RUN cd $DOCUMENT_ROOT && \
    php -dmemory_limit=-1 bin/magento setup:install \
        --base-url-secure=$MAGENTO_BASE_URL_SECURE \
        --base-url=$MAGENTO_BASE_URL \
        --db-host="${MAGENTO_DATABASE_HOST}:${MAGENTO_DATABASE_PORT}" \
        --db-name=$MAGENTO_DATABASE_DB \
        --db-user=$MAGENTO_DATABASE_USER \
        --db-password=$MAGENTO_DATABASE_PWD \
        --search-engine=$MAGENTO_SEARCH_ENGINE \
        --elasticsearch-host=$MAGENTO_SEARCH_ENGINE_HOST \
        --elasticsearch-port=$MAGENTO_SEARCH_ENGINE_PORT \
        --admin-firstname=$MAGENTO_ADMIN_FIRSTNAME \
        --admin-lastname=$MAGENTO_ADMIN_LASTNAME \
        --admin-email=$MAGENTO_ADMIN_EMAIL \
        --admin-user=$MAGENTO_ADMIN_USER \
        --admin-password=$MAGENTO_ADMIN_PWD \
        --language=vi_VN --currency=VND --timezone=Asia/Ho_Chi_Minh

RUN cd $DOCUMENT_ROOT && \         
    php -dmemory_limit=-1 bin/magento deploy:mode:set $MAGENTO_MODE --skip-compilation && \
    php -dmemory_limit=-1 bin/magento config:set dev/js/enable_js_bundling 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/js/minify_files 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/css/minify_files 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/css/merge_css_files 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/template/minify_html 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/static/sign 1 && \
    php -dmemory_limit=-1 bin/magento setup:di:compile --no-ansi

RUN cd $DOCUMENT_ROOT && \
    php -dmemory_limit=-1 bin/magento setup:static-content:deploy --theme Magento/backend  --theme Ntugi/porto --language vi_VN && \
    php -dmemory_limit=-1 bin/magento cache:flush

#COPY "${DOCUMENT_ROOT}"/app/etc/env.php "${DOCUMENT_ROOT}"/app/etc/env.default.php
COPY ./app/etc/env.php.template $DOCUMENT_ROOT/app/etc/env.php

RUN mkdir -p "${DOCUMENT_ROOT}"/var/cache "${DOCUMENT_ROOT}"/var/report "${DOCUMENT_ROOT}"/var/tmp "${DOCUMENT_ROOT}"/app/code

RUN find "${DOCUMENT_ROOT}"/var "${DOCUMENT_ROOT}"/generated \( -type d -or -type f \) -exec chmod 775 {} +;

RUN chmod o+rwx "${DOCUMENT_ROOT}"/app/etc/env.php

RUN zip -qr "${ZIP_ROOT}/dungmoc.zip" "${DOCUMENT_ROOT}"

# --- PHP FPM ---
FROM ntuangiang/magento:2.4.2-arm64 as magento-phpfpm

COPY --from=magento-builder --chown=magento:magento \
    "${ZIP_ROOT}/dungmoc.zip" \
    ${ZIP_ROOT}/

# If we zip a folder, unzip will auto exact folder we zipped.
RUN unzip -qq "${ZIP_ROOT}/dungmoc.zip" -d "/"

ENV MAGENTO_MODE=production

# Database Configuration
ENV MAGENTO_DATABASE_HOST=production-auto-deploy.mysql-24612894-production
ENV MAGENTO_DATABASE_PORT=3306
ENV MAGENTO_DATABASE_USER=dungmoc
ENV MAGENTO_DATABASE_PWD=dungmoc
ENV MAGENTO_DATABASE_DB=dungmoc

# Cache
ENV MAGENTO_CACHE_REDIS_HOST=production-auto-deploy.redis-24564346-production
ENV MAGENTO_CACHE_REDIS_PORT=6379

# Search Engine
ENV MAGENTO_SEARCH_ENGINE_HOST=production-auto-deploy.elasticsearch-24612886-production
ENV MAGENTO_SEARCH_ENGINE=elasticsearch7
ENV MAGENTO_SEARCH_ENGINE_PORT=9200

USER root

RUN rm -rf "${ZIP_ROOT}/dungmoc.zip"

USER magento

# --- NGINX SERVER ---
FROM ntuangiang/magento-nginx:latest-arm64 as magento-nginx

COPY --from=magento-builder --chown=magento:magento \
    "${ZIP_ROOT}/dungmoc.zip" \
    ${ZIP_ROOT}/

# If we zip a folder, unzip will auto exact folder we zipped.
RUN unzip -qq "${ZIP_ROOT}/dungmoc.zip" -d "/"

RUN rm -rf "${ZIP_ROOT}/dungmoc.zip"

ENV MAGE_MODE=production
ENV NGINX_BACKEND_HOST=production-phpfpm-auto-deploy.dungmoc-24610986-production
