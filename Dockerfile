FROM ntuangiang/magento-cache-system:2.4.3-p1 as magento-builder

COPY ./composer.* ${DOCUMENT_ROOT}/

RUN composer update && composer install --no-ansi --no-interaction --optimize-autoloader --no-dev --prefer-dist 2>&1

COPY ./environment /etc/
COPY ./auth.json "${DOCUMENT_ROOT}"/var/composer_home/composer.json
COPY ./app/design "${DOCUMENT_ROOT}"/app/design
COPY ./app/code "${DOCUMENT_ROOT}"/app/code

RUN . /etc/environment && php -dmemory_limit=-1 bin/magento setup:install \
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

RUN . /etc/environment && php -dmemory_limit=-1 bin/magento deploy:mode:set $MAGENTO_MODE --skip-compilation && \
    php -dmemory_limit=-1 bin/magento config:set dev/js/enable_js_bundling 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/js/minify_files 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/css/minify_files 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/css/merge_css_files 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/template/minify_html 1 && \
    php -dmemory_limit=-1 bin/magento config:set dev/static/sign 1 && \
    php -dmemory_limit=-1 bin/magento setup:di:compile --no-ansi

COPY ./app/etc/env.php.template "${DOCUMENT_ROOT}"/app/etc/env.php

RUN mkdir -p "${DOCUMENT_ROOT}"/var/cache "${DOCUMENT_ROOT}"/var/report "${DOCUMENT_ROOT}"/var/tmp "${DOCUMENT_ROOT}"/app/code

RUN find "${DOCUMENT_ROOT}"/var "${DOCUMENT_ROOT}"/generated \( -type d -or -type f \) -exec chmod 775 {} +;

RUN chmod o+rwx "${DOCUMENT_ROOT}"/app/etc/env.php

RUN zip -qr "${ZIP_ROOT}/magento.zip" "${DOCUMENT_ROOT}"

# --- PHP FPM ---
FROM ntuangiang/magento-system:2.4.3-p1 as magento-phpfpm

USER root

RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS

RUN pecl install redis xdebug-2.9.6
RUN docker-php-ext-enable redis xdebug

COPY --from=magento-builder \
    "${ZIP_ROOT}/magento.zip" \
    ${ZIP_ROOT}/

# If we zip a folder, unzip will auto exact folder we zipped.
RUN unzip -qq "${ZIP_ROOT}/magento.zip" -d "/"

RUN rm -rf "${ZIP_ROOT}/magento.zip"

# --- NGINX SERVER ---
FROM ntuangiang/magento-nginx-system:2.4.3-p1 as magento-nginx
 
USER root

COPY --from=magento-builder \
    "${ZIP_ROOT}/magento.zip" \
    ${ZIP_ROOT}/

# If we zip a folder, unzip will auto exact folder we zipped.
RUN unzip -qq "${ZIP_ROOT}/magento.zip" -d "/"

RUN rm -rf "${ZIP_ROOT}/dungmoc.zip"
