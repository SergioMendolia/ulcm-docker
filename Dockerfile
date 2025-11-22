FROM php:8.5.0-apache-bookworm

RUN curl -sL https://deb.nodesource.com/setup_22.x | bash -

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/home/.composer
RUN mkdir -p /home/.composer
RUN printf "deb http://http.us.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list.d/nonfree.list

# auto install dependencies and remove libs after installing ext: https://github.com/mlocati/docker-php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

COPY docker/install.sh /usr/bin/install.sh

# npm is included in nodejs, see https://askubuntu.com/a/1432138
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    dma  \
    ghostscript \
    openssl \
    postgresql-client \
    unzip \
    zip \
    && chmod +x /usr/bin/install.sh \
    && /usr/bin/install.sh \
    intl \
    opcache \
    pdo_mysql \
    bcmath \
    @composer \
    pgsql \
    pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

COPY docker/001-ulcm.conf /etc/apache2/sites-enabled/001-ulcm.conf
RUN touch /var/www/.bash_history && chmod 777 /var/www/.bash_history
# Run from unprivileged port 8080 only
RUN sed -e 's/Listen 80/Listen 8080/g' -i /etc/apache2/ports.conf

COPY ./docker/dma.conf /etc/dma/dma.conf
COPY ./docker/ulcm.ini /usr/local/etc/php/conf.d/ulcm.ini

ARG UNAME=www-data
ARG UGROUP=www-data
ARG UID=1000
ARG GID=1000
RUN usermod  --uid $UID $UNAME
RUN groupmod --gid $GID $UGROUP

RUN mkdir -p /var/www/.npm && chown -R $UID:$GID /var/www/.npm

USER www-data

WORKDIR /var/www/html
CMD ["docker-php-entrypoint", "apache2-foreground"]
