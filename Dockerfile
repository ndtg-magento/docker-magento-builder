FROM php:7.4-fpm-alpine

MAINTAINER Nguyen Tuan Giang "https://github.com/ntuangiang"

ENV MAGENTO_VERSION=2.4.2

ENV DOCUMENT_ROOT=/usr/share/nginx/html

# Install package
RUN apk add --no-cache vim freetype \
    libpng \
    zlib \
    libwebp \
    libjpeg \
    libjpeg \
    libxslt \
    libjpeg-turbo \
    icu-dev \
    libzip-dev \
    libpng-dev \
    libxslt-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    busybox-suid ssmtp \
    dcron libcap

RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS

RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg \
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

COPY ./docker/php/php.ini "${PHP_INI_DIR}/php.ini"
COPY ./docker/php/ssmtp.conf /etc/ssmtp/ssmtp.conf

COPY ./docker/thread.sh /usr/local/bin/thread
COPY ./docker/aliases.sh /etc/profile.d/aliases.sh
COPY ./docker/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint
COPY ./docker/docker-magento-entrypoint /usr/local/bin/docker-magento-entrypoint

RUN addgroup magento && \
    adduser --disabled-password --gecos "" --ingroup magento magento

RUN chmod u+x /usr/local/bin/docker-magento-entrypoint

RUN chown magento:magento /usr/sbin/crond /usr/bin/crontab && \
    chown -R magento:magento /var/spool/cron /etc/crontabs

RUN setcap cap_setgid=ep /usr/bin/crontab && \
    setcap cap_setgid=ep /usr/sbin/crond

RUN ln -s ${DOCUMENT_ROOT}/bin/magento /usr/local/bin/magento
RUN sed -i 's/www-data/magento/g' /usr/local/etc/php-fpm.d/*.conf

WORKDIR ${DOCUMENT_ROOT}

RUN chown -R magento:magento ${DOCUMENT_ROOT}/

USER magento
