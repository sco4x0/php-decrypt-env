FROM php:7.3-apache

RUN sed -i "s/deb.debian.org/mirrors.aliyun.com/g" /etc/apt/sources.list && \
    apt update && apt install vim git -y
RUN git clone https://github.com/liexusong/php-beast /tmp/php-beast
WORKDIR /tmp/php-beast
RUN phpize && ./configure && make && make install && docker-php-ext-enable beast
COPY ./html/index.php /var/www/html/source.php
WORKDIR /var/www/html
RUN php /tmp/php-beast/tools/encode_file.php --oldfile source.php --newfile index.php && \
    cp index.php index.hook

# enable vld
RUN git clone https://github.com/derickr/vld /tmp/vld
WORKDIR /tmp/vld
COPY ./tools/compile_file.diff .
RUN git apply compile_file.diff && phpize && ./configure && make && make install && docker-php-ext-enable vld
WORKDIR /var/www/html
RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf && \
    a2enmod rewrite && \
    rm -rf /tmp/vld
COPY ./tools/htaccess .htaccess
