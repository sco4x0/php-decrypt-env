FROM php:5.6-apache

RUN echo 'deb [check-valid-until=no] http://archive.debian.org/debian/ stretch main non-free contrib' > /etc/apt/sources.list && \
    echo 'deb-src [check-valid-until=no] http://archive.debian.org/debian/ stretch main non-free contrib' >> /etc/apt/sources.list && \
    apt update && apt install git zlib1g-dev -y
RUN git clone https://github.com/Luavis/php-screw /tmp/php-screw
WORKDIR /tmp/php-screw
RUN phpize && ./configure && make && make install && docker-php-ext-enable php_screw
WORKDIR /tmp/php-screw/tools
RUN make && cp screw /usr/bin/screw
COPY ./html/index.php /var/www/html/index.php
WORKDIR /var/www/html
RUN /usr/bin/screw index.php && \
    mv index.php.screw source.php
