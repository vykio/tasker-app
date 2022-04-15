FROM composer:2 as composer

FROM php:7.4-apache

# Installer extensions + clean
RUN apt-get update \
    && apt-get install -y zlib1g-dev libpq-dev git libicu-dev libxml2-dev libzip-dev libcurl3-dev wget \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-install zip xml \
    ##&& docker-php-ext-install mysqli && docker-php-ext-enable mysqli \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql

# Installer composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Installer symfony
RUN wget https://get.symfony.com/cli/installer -O - | bash
RUN mv /root/.symfony/bin/symfony /usr/local/bin/symfony

# Set timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# PHP conf
COPY config/php/php.ini /usr/local/etc/php/conf.d/app.ini

# Apache conf
COPY config/apache/vhost.conf /etc/apache2/sites-available/000-default.conf

# Conf apache
RUN a2enmod rewrite \
    && a2enmod ssl \
    && a2enmod headers


WORKDIR /var/www/html
COPY . .
