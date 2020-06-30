FROM ntuangiang/magento-cache:2.3.5-develop

RUN pecl install redis xdebug-2.9.6
RUN docker-php-ext-enable redis xdebug

RUN apk del .phpize-deps

# Copy Scripts
COPY ./docker/rootfs /rootfs
COPY ./docker/php/php.ini "${PHP_INI_DIR}/php.ini"
COPY ./docker/aliases.sh /etc/profile.d/aliases.sh

COPY ./docker/docker-magento-entrypoint /usr/local/bin/docker-magento-entrypoint
COPY ./docker/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint

RUN chmod u+x /rootfs/* /usr/local/bin/docker-magento-entrypoint

RUN ln -s /rootfs/magento:setup /usr/local/bin/magento:setup
RUN ln -s ${DOCUMENT_ROOT}/bin/magento /usr/local/bin/magento
RUN ln -s /rootfs/magento:install /usr/local/bin/magento:install
