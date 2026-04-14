# syntax=docker/dockerfile:1.4

# ================================================================
# Stage 1 — Builder
# php:8.2-cli-alpine — ~30MB, has everything needed to clone + unzip
# ================================================================
FROM php:8.2-cli-alpine AS builder

ARG GITHUB_USERNAME
ARG REPOSITORY_NAME
ARG APPLICATION_CODE_FILE_NAME

# apk is faster than dnf — no weak deps, no docs by default
RUN apk add --no-cache \
        git \
        git-lfs \
        unzip \
        curl \
    && git lfs install

WORKDIR /app

RUN --mount=type=secret,id=personal_access_token \
    PAT=$(tr -d '[:space:]' < /run/secrets/personal_access_token) && \
    printf 'machine github.com\nlogin %s\npassword %s\n' "${GITHUB_USERNAME}" "${PAT}" \
        > /root/.netrc && \
    chmod 600 /root/.netrc && \
    git clone https://github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}.git . && \
    git lfs pull && \
    rm -f /root/.netrc && \
    unzip ${APPLICATION_CODE_FILE_NAME}.zip && \
    cp -R ${APPLICATION_CODE_FILE_NAME}/. /app/ && \
    rm -rf ${APPLICATION_CODE_FILE_NAME} ${APPLICATION_CODE_FILE_NAME}.zip \
           .git .gitattributes .gitignore

# ================================================================
# Stage 2 — Runtime
# php:8.2-apache — Apache + mod_php on debian:bookworm-slim
# No start-services.sh needed — apache2-foreground handles everything
# ================================================================
FROM php:8.2-apache AS final

ARG PROJECT_NAME
ARG ENVIRONMENT
ARG RECORD_NAME
ARG DOMAIN_NAME
ARG GITHUB_USERNAME
ARG REPOSITORY_NAME
ARG SERVICE_PROVIDER_FILE_NAME
ARG APPLICATION_CODE_FILE_NAME
ARG RDS_ENDPOINT
ARG RDS_DB_NAME
ARG RDS_DB_USERNAME

ENV PROJECT_NAME=$PROJECT_NAME \
    ENVIRONMENT=$ENVIRONMENT \
    RECORD_NAME=$RECORD_NAME \
    DOMAIN_NAME=$DOMAIN_NAME \
    GITHUB_USERNAME=$GITHUB_USERNAME \
    REPOSITORY_NAME=$REPOSITORY_NAME \
    SERVICE_PROVIDER_FILE_NAME=$SERVICE_PROVIDER_FILE_NAME \
    APPLICATION_CODE_FILE_NAME=$APPLICATION_CODE_FILE_NAME \
    RDS_ENDPOINT=$RDS_ENDPOINT \
    RDS_DB_NAME=$RDS_DB_NAME \
    RDS_DB_USERNAME=$RDS_DB_USERNAME \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm

# Install only the C libraries needed to compile extensions
# Purge dev headers after compile — .so files are all runtime needs
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        libzip-dev \
        libcurl4-openssl-dev \
        curl \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        bcmath \
        mbstring \
        xml \
        zip \
        gd \
        opcache \
    && apt-get purge -y --auto-remove \
        libpng-dev libonig-dev libxml2-dev libzip-dev libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# PHP tuning via conf.d drop-in — cleaner than patching php.ini
RUN { \
        echo 'memory_limit = 256M'; \
        echo 'max_execution_time = 300'; \
        echo 'upload_max_filesize = 64M'; \
        echo 'post_max_size = 64M'; \
        echo 'expose_php = Off'; \
    } > /usr/local/etc/php/conf.d/laravel.ini \
    && { \
        echo 'opcache.enable=1'; \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.validate_timestamps=0'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# Enable mod_rewrite for Laravel routing
# Point document root at public/ — never expose app internals to the web
RUN a2enmod rewrite \
    && sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' \
        /etc/apache2/sites-available/000-default.conf \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' \
        /etc/apache2/apache2.conf \
    && printf '<Directory /var/www/html/public>\n\tAllowOverride All\n\tRequire all granted\n</Directory>\n' \
        >> /etc/apache2/apache2.conf \
    && echo "ServerTokens Prod" >> /etc/apache2/apache2.conf \
    && echo "ServerSignature Off" >> /etc/apache2/apache2.conf

WORKDIR /var/www/html

COPY --from=builder /app /var/www/html
COPY ${SERVICE_PROVIDER_FILE_NAME}.php app/Providers/AppServiceProvider.php

RUN --mount=type=secret,id=rds_db_password \
    RDS_DB_PASSWORD=$(tr -d '[:space:]' < /run/secrets/rds_db_password) && \
    sed -i "/^APP_NAME=/    s|=.*$|=${PROJECT_NAME}-${ENVIRONMENT}|"         .env && \
    sed -i "/^APP_URL=/     s|=.*$|=https://${RECORD_NAME}.${DOMAIN_NAME}/|" .env && \
    sed -i "/^APP_ENV=/     s|=.*$|=production|"                             .env && \
    sed -i "/^APP_DEBUG=/   s|=.*$|=false|"                                  .env && \
    sed -i "/^DB_HOST=/     s|=.*$|=${RDS_ENDPOINT}|"                        .env && \
    sed -i "/^DB_DATABASE=/ s|=.*$|=${RDS_DB_NAME}|"                         .env && \
    sed -i "/^DB_USERNAME=/ s|=.*$|=${RDS_DB_USERNAME}|"                     .env && \
    sed -i "/^DB_PASSWORD=/ s|=.*$|=${RDS_DB_PASSWORD}|"                     .env && \
    chown -R www-data:www-data /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    chmod -R 775 /var/www/html/storage && \
    chmod -R 775 /var/www/html/bootstrap/cache

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Built-in entrypoint for php:*-apache images
# Replaces start-services.sh entirely — no custom startup script needed
CMD ["apache2-foreground"]