FROM php:7.3-apache

RUN sed -i "s/deb.debian.org/mirrors.aliyun.com/g" /etc/apt/sources.list && \
    apt update && apt install git zlib1g-dev libzip-dev unzip -y && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/bin/composer && \
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ && \
    docker-php-ext-install zip
COPY ./html/ast.php /var/www/html/ast.php
COPY ./html/phpjiami.php /var/www/html/index.php
COPY ./html/phpjiami.php /var/www/html/index.hook
WORKDIR /var/www/html
RUN composer require nikic/php-parser

# enable vld
RUN git clone https://github.com/derickr/vld /tmp/vld
WORKDIR /tmp/vld
COPY ./tools/compile_string.diff .
RUN git apply compile_string.diff && phpize && ./configure && make && make install && docker-php-ext-enable vld
WORKDIR /var/www/html
RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf && \
    a2enmod rewrite && \
    rm -rf /tmp/vld
COPY ./tools/htaccess .htaccess