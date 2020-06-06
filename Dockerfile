FROM ntuangiang/magento-cache:2.3.5-develop

RUN pecl install \
    xdebug-2.9.6

RUN docker-php-ext-enable \
    xdebug

COPY ./docker/php/php.ini "${PHP_INI_DIR}/php.ini"
COPY ./docker/aliases.sh /etc/profile.d/aliases.sh

RUN ln -s ${DOCUMENT_ROOT}/bin/magento /usr/local/bin/magento


