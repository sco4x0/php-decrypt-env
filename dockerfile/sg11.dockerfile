FROM php:7.3-apache

RUN sed -i "s/deb.debian.org/mirrors.aliyun.com/g" /etc/apt/sources.list && \
    apt update && apt install -y vim git

RUN git clone https://github.com/derickr/vld /tmp/vld
COPY ./tools/ixed.7.3.lin /usr/local/lib/php/extensions/no-debug-non-zts-20180731/ixed.7.3.lin
WORKDIR /tmp/vld
COPY ./tools/execute_ex.diff .
RUN git apply execute_ex.diff && phpize && ./configure && make && make install && \
    docker-php-ext-enable vld ixed.7.3.lin
COPY ./html/index-sg11.php /var/www/html/index.php
WORKDIR /var/www/html
RUN rm -rf /tmp/vld