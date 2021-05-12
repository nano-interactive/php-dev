
FROM php:7.4-fpm as cassandra-build

ENV EXT_CASSANDRA_VERSION=master

RUN docker-php-source extract \
    && apt update -y \
    && apt install cmake build-essential git libuv1-dev libssl-dev libgmp-dev openssl zlib1g-dev libpcre3-dev -y \
    && git clone --branch $EXT_CASSANDRA_VERSION --depth 1 https://github.com/datastax/php-driver.git /usr/src/php/ext/cassandra \
    && cd /usr/src/php/ext/cassandra && git submodule update --init \
    && mkdir -p /usr/src/php/ext/cassandra/lib/cpp-driver/build \
    && cmake -DCMAKE_CXX_FLAGS="-fPIC" -DCASS_BUILD_STATIC=OFF -DCASS_BUILD_SHARED=ON -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_LIBDIR:PATH=lib -DCASS_USE_ZLIB=ON /usr/src/php/ext/cassandra/lib/cpp-driver \
    && make -j8 \
    && make install


RUN cd /usr/src/php/ext/cassandra/ext \
    && phpize \
    && LDFLAGS="-L/usr/local/lib" LIBS="-lssl -lz -luv -lm -lgmp -lstdc++" ./configure --with-cassandra=/usr/local \
    && make -j8 && make install


FROM php:7.4-fpm


COPY --from=cassandra-build /usr/local/lib/libcassandra.so.2.15.1 /usr/local/lib/libcassandra.so.2.15.1
COPY --from=cassandra-build /usr/local/lib/php/extensions/no-debug-non-zts-20190902/cassandra.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/cassandra.so
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

ENV PHP_IDE_CONFIG="serverName=NanoCisEngine"


# Install Core Extensions
RUN groupadd -g 101 nginx && useradd -m -s /bin/bash -u 101 -g 101 nginx && \
    ln -s /usr/local/lib/libcassandra.so.2.15.1 /usr/local/lib/libcassandra.so \
    && apt-get update && apt-get install -y \
    git \
    libboost-all-dev \
    libuv1-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libcurl4-openssl-dev \
    libgmp-dev \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    libmemcached-dev \
    librabbitmq-dev \
    zlib1g-dev \
    libpcre3-dev \
    unzip \
    libmaxminddb0 \
    libmaxminddb-dev \
    mmdb-bin \
    libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j8 gd \
    && install-php-extensions intl zip bcmath pgsql pdo_pgsql pdo_mysql pcntl psr phalcon gmp geospatial xhprof yaml zstd opcache uuid timezonedb pcntl amqp json_post imagick memcached apcu igbinary ast grpc protobuf redis maxminddb mongodb msgpack \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

COPY ./php.ini /usr/local/etc/php

COPY ./conf.d/docker-php-ext-amqp.ini /usr/local/etc/php/conf.d/docker-php-ext-amqp.ini
COPY ./conf.d/docker-php-ext-apcu.ini /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini
COPY ./conf.d/docker-php-ext-igbinary.ini /usr/local/etc/php/conf.d/docker-php-ext-igbinary.ini
COPY ./conf.d/docker-php-ext-redis.ini /usr/local/etc/php/conf.d/docker-php-ext-redis.ini
COPY ./conf.d/docker-php-ext-cassandra.ini /usr/local/etc/php/conf.d/docker-php-ext-cassandra.ini
COPY ./php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

CMD ["/bin/bash"]
