FROM php:8.2-apache

# Install dependencies and PHP extensions commonly needed (mysqli, pdo, gd, zip)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) mysqli pdo pdo_mysql gd zip opcache \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# Set upload limit and memory limit
RUN echo "upload_max_filesize = 128M\npost_max_size = 128M\nmemory_limit = 256M" > /usr/local/etc/php/conf.d/custom.ini \
    && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf
