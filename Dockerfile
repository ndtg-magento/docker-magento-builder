FROM ntuangiang/magento-cache:2.3.3

MAINTAINER Nguyen Tuan Giang "https://github.com/ntuangiang"

RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS

# Install Redis Cache, XDebug
RUN pecl install xdebug-2.8.1
RUN docker-php-ext-enable xdebug

WORKDIR ${DOCUMENT_ROOT}


