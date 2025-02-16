# Do not edit this file. It is automatically generated by https://www.oliverdavies.uk/build-configs.

FROM php:8.1-fpm-bullseye AS base

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN which composer && composer -V

ARG DOCKER_UID=1000
ENV DOCKER_UID="${DOCKER_UID}"

WORKDIR /app

RUN adduser --disabled-password --uid "${DOCKER_UID}" app \
  && chown app:app -R /app

USER app

ENV PATH="${PATH}:/app/bin:/app/vendor/bin"

COPY --chown=app:app composer.* ./

################################################################################

FROM base AS build

USER root


RUN apt-get update -yqq \
  && apt-get install -yqq --no-install-recommends \
    git libpng-dev libjpeg-dev libzip-dev mariadb-client unzip \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean

RUN docker-php-ext-configure gd --with-jpeg

RUN docker-php-ext-install gd pdo_mysql zip

COPY --chown=app:app phpunit.xml* ./



USER app

RUN composer validate
RUN composer install

COPY --chown=app:app tools/docker/images/php/root /

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-php"]
CMD ["php-fpm"]




################################################################################

FROM nginx:1 as web

EXPOSE 8080

WORKDIR /app

COPY tools/docker/images/web/root /
