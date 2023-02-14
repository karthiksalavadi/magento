FROM php:7.4-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    git \
    curl \
    vim \
    wget \
    openssl

# Install required PHP extensions
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install intl \
    && docker-php-ext-install opcache \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install soap \
    && docker-php-ext-install zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Download and install Magento
RUN git clone -b 2.4 git@github.com:magento/magento2.git /var/www/html/magento2
RUN cd /var/www/html/magento2 \
    && composer install --no-dev

# Set file permissions
RUN chown -R www-data:www-data /var/www/html/magento2 \
    && chmod -R 755 /var/www/html/magento2 \
    && find /var/www/html/magento2 -type d -exec chmod 777 {} \;

# Enable Apache rewrite module
RUN a2enmod rewrite

# Copy custom Apache configuration
COPY magento.conf /etc/apache2/sites-available/

# Enable virtual host and disable default site
RUN a2dissite 000-default.conf \
    && a2ensite magento.conf \
    && service apache2 restart
