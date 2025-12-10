# Multi-stage build untuk Laravel dengan Nginx + PHP-FPM
FROM php:8.3-fpm-alpine AS php-fpm

# Set working directory
WORKDIR /var/www/html

# Install system dependencies untuk Alpine
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    icu-dev \
    postgresql-dev \
    postgresql-client \
    autoconf \
    g++ \
    make \
    linux-headers \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        pgsql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        intl \
        opcache \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf g++ make linux-headers \
    && rm -rf /var/cache/apk/* /tmp/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy existing application directory contents from src folder
COPY src/ /var/www/html

# Install dependencies
#RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts --prefer-dist
RUN composer update

# Run post-install scripts
#RUN composer dump-autoload --optimize --no-dev --classmap-authoritative

# Laravel optimization for production
RUN php artisan config:cache || true && \
    php artisan route:cache || true && \
    php artisan view:cache || true

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Final stage dengan Nginx + PHP-FPM
FROM nginx:1.27-alpine

# Install PHP-FPM dan dependencies
RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-pdo \
    php83-pdo_pgsql \
    php83-pgsql \
    php83-mbstring \
    php83-exif \
    php83-pcntl \
    php83-bcmath \
    php83-gd \
    php83-zip \
    php83-xml \
    php83-session \
    php83-tokenizer \
    php83-opcache \
    php83-intl \
    php83-dom \
    php83-xmlwriter \
    php83-xmlreader \
    php83-simplexml \
    php83-fileinfo \
    php83-ctype \
    php83-redis \
    postgresql-client \
    supervisor \
    curl \
    && rm -rf /var/cache/apk/*

# Copy aplikasi dari stage php-fpm
COPY --from=php-fpm /var/www/html /var/www/html

# Copy konfigurasi Nginx
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy konfigurasi PHP
COPY php/php.ini /etc/php83/conf.d/99-laravel.ini
COPY php/php-fpm.conf /etc/php83/php-fpm.d/www.conf

# Buat direktori log untuk PHP-FPM
RUN mkdir -p /var/log/php-fpm && \
    chown -R nginx:nginx /var/log/php-fpm && \
    mkdir -p /var/log/supervisor
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:php-fpm]
command=php-fpm83 -F
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/php-fpm.err.log
stdout_logfile=/var/log/supervisor/php-fpm.out.log

[program:nginx]
command=nginx -g 'daemon off;'
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/nginx.err.log
stdout_logfile=/var/log/supervisor/nginx.out.log
EOF

# Set permissions
RUN chown -R nginx:nginx /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Security: Remove default nginx configs
RUN rm -f /etc/nginx/conf.d/default.conf.bak

# Create nginx user if not exists and set proper ownership
RUN chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Labels for metadata
LABEL maintainer="DevOps Team" \
      version="1.0" \
      description="Laravel 12 Production Image with Nginx 1.27 and PHP 8.3"

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
