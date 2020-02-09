FROM php:7.3-fpm-alpine

MAINTAINER Nguyen Tuan Giang "https://github.com/ntuangiang"

ENV MAGENTO_VERSION=2.3.3
ENV MAGENTO_MODE=production

ENV DOCUMENT_ROOT=/usr/share/nginx/html

# Install package
RUN apk add --no-cache freetype \
    libpng \
    libjpeg \
    libjpeg \
    libxslt \
    libjpeg-turbo \
    icu-dev \
    libzip-dev \
    libpng-dev \
    libxslt-dev \
    freetype-dev \
    libjpeg-turbo-dev

RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS

RUN docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-configure intl

# Install PHP package
RUN docker-php-ext-install -j$(nproc) iconv gd

RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    zip \
    bcmath \
    intl \
    soap \
    xsl \
    sockets

# Install Redis Cache
RUN pecl install redis
RUN docker-php-ext-enable redis

RUN apk del .phpize-deps \
    && apk del --no-cache \
       libpng-dev \
       libxslt-dev \
       freetype-dev \
       libjpeg-turbo-dev \
    && rm -rf /var/cache/apk/*

# Install Magento
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy Scripts
COPY ./docker/rootfs /rootfs
COPY ./docker/php/php.ini "${PHP_INI_DIR}/php.ini"
COPY ./docker/aliases.sh /etc/profile.d/aliases.sh
COPY ./docker/docker-magento-entrypoint /usr/local/bin/docker-magento-entrypoint
COPY ./docker/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint

RUN chmod u+x /rootfs/* /usr/local/bin/docker-magento-entrypoint
RUN ln -s ${DOCUMENT_ROOT}/bin/magento /usr/local/bin/magento

WORKDIR ${DOCUMENT_ROOT}

# Create a user group 'xyzgroup'
RUN addgroup -S magento

# Create a user 'appuser' under 'xyzgroup'
RUN adduser -SD magento magento

RUN chown -R magento:magento ${DOCUMENT_ROOT}/

