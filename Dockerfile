FROM ntuangiang/magento-cache:2.3.3

MAINTAINER Nguyen Tuan Giang "https://github.com/ntuangiang"

RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS

# Install Redis Cache, XDebug
RUN pecl install xdebug-2.8.1

RUN docker-php-ext-enable xdebug

COPY ./docker/aliases.sh /etc/profile.d/aliases.sh
COPY ./docker/php/php.ini "${PHP_INI_DIR}/php.ini"
COPY ./docker/magento-entrypoint /usr/local/bin/magento-entrypoint
COPY ./docker/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint

RUN chmod u+x /usr/local/bin/magento-entrypoint

WORKDIR ${DOCUMENT_ROOT}

# Create a user group 'xyzgroup'
RUN addgroup -S magento

# Create a user 'appuser' under 'xyzgroup'
RUN adduser -SD magento magento

COPY ./docker/rootfs /rootfs

RUN chmod u+x /rootfs/*

RUN chown -R magento:magento ${DOCUMENT_ROOT}/

RUN ln -s ${DOCUMENT_ROOT}/bin/magento /usr/local/bin/magento

