
FROM php:8.0-fpm as cassandra-build

ENV EXT_CASSANDRA_VERSION=master

RUN docker-php-source extract \
    && apt update -y \
    && apt install cmake build-essential git libuv1-dev libssl-dev libgmp-dev openssl zlib1g-dev libpcre3-dev -y \
    && git clone --branch $EXT_CASSANDRA_VERSION --depth 1 https://github.com/nano-interactive/php-driver.git /usr/src/php/ext/cassandra \
    && cd /usr/src/php/ext/cassandra && git submodule update --init \
    && mkdir -p /usr/src/php/ext/cassandra/lib/cpp-driver/build \
    && cmake -DCMAKE_CXX_FLAGS="-fPIC" -DCASS_BUILD_STATIC=OFF -DCASS_BUILD_SHARED=ON -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_LIBDIR:PATH=lib -DCASS_USE_ZLIB=ON /usr/src/php/ext/cassandra/lib/cpp-driver \
    && make -j$(nproc) \
    && make install


RUN cd /usr/src/php/ext/cassandra/ext \
    && phpize \
    && LDFLAGS="-L/usr/local/lib" LIBS="-lssl -lz -luv -lm -lgmp -lstdc++" ./configure --with-cassandra=/usr/local \
    && make -j$(nproc) && make install

FROM php:8.0-fpm as amqp-build

ENV EXT_AMQP_VERSION=master

RUN docker-php-source extract \
    && apt update -y \
    && apt install git librabbitmq-dev -y \
    && git clone --branch $EXT_AMQP_VERSION --depth 1 https://github.com/php-amqp/php-amqp.git /usr/src/php/ext/amqp \
    && cd /usr/src/php/ext/amqp && git submodule update --init \
    && docker-php-ext-install amqp


FROM php:8.0-fpm


COPY --from=amqp-build /usr/local/lib/php/extensions/no-debug-non-zts-20200930/amqp.so /usr/local/lib/php/extensions/no-debug-non-zts-20200930/amqp.so
COPY --from=cassandra-build /usr/local/lib/libcassandra.so.2.15.1 /usr/local/lib/libcassandra.so.2.15.1
COPY --from=cassandra-build /usr/local/lib/php/extensions/no-debug-non-zts-20200930/cassandra.so /usr/local/lib/php/extensions/no-debug-non-zts-20200930/cassandra.so

RUN ln -s /usr/local/lib/libcassandra.so.2.15.1 /usr/local/lib/libcassandra.so

# Install Core Extensions
RUN apt-get update && apt-get install -y \
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
    && apt update && apt install libmaxminddb0 libmaxminddb-dev mmdb-bin \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install -j$(nproc) gmp \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-configure pcntl \
    && docker-php-ext-install -j$(nproc) pcntl \
    && docker-php-ext-configure pdo_mysql \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-configure pdo_pgsql \
    && docker-php-ext-install -j$(nproc) pdo_pgsql \
    && docker-php-ext-configure pgsql \
    && docker-php-ext-install -j$(nproc) pgsql \
    && docker-php-ext-configure bcmath \
    && docker-php-ext-install -j$(nproc) bcmath \
    && docker-php-ext-configure zip \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-configure exif \
    && docker-php-ext-install -j$(nproc) exif \
    && pecl install memcached \
    && docker-php-ext-enable memcached \
    && pecl install igbinary \
    && docker-php-ext-enable igbinary \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && pecl install ast \
    && docker-php-ext-enable ast \
    && pecl install grpc \
    && docker-php-ext-enable grpc    \
    && pecl install protobuf \
    && docker-php-ext-enable protobuf \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && pecl install maxminddb \
    && docker-php-ext-enable maxminddb \
    && pecl install mongodb \
    && docker-php-ext-enable mongodb

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

COPY ./php.ini /usr/local/etc/php

COPY ./conf.d/docker-php-ext-amqp.ini /usr/local/etc/php/conf.d/docker-php-ext-amqp.ini
COPY ./conf.d/docker-php-ext-apcu.ini /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini
COPY ./conf.d/docker-php-ext-igbinary.ini /usr/local/etc/php/conf.d/docker-php-ext-igbinary.ini
COPY ./conf.d/docker-php-ext-redis.ini /usr/local/etc/php/conf.d/docker-php-ext-redis.ini
COPY ./conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
COPY ./conf.d/docker-php-ext-cassandra.ini /usr/local/etc/php/conf.d/docker-php-ext-cassandra.ini
