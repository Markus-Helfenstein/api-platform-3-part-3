#syntax=docker/dockerfile:1

# The different stages of this Dockerfile are meant to be built into separate images
# https://docs.docker.com/develop/develop-images/multistage-build/#stop-at-a-specific-build-stage
# https://docs.docker.com/compose/compose-file/#target


# Base FrankenPHP image
FROM dunglas/frankenphp:1.3.6-php8.4-bookworm AS frankenphp_base

WORKDIR /app

VOLUME /app/var/

# persistent / runtime deps
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
	acl \
	file \
	gettext \
	git \
	&& rm -rf /var/lib/apt/lists/*

RUN set -eux; \
	install-php-extensions \
		@composer \
		apcu \
		intl \
		opcache \
		zip \
	;

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

# Transport to use by Mercure (default to Bolt)
ENV MERCURE_TRANSPORT_URL=bolt:///data/mercure.db

ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

###> recipes ###
###> doctrine/doctrine-bundle ###
RUN install-php-extensions pdo_pgsql
###< doctrine/doctrine-bundle ###
###< recipes ###

COPY --link frankenphp/conf.d/10-app.ini $PHP_INI_DIR/app.conf.d/
COPY --link --chmod=755 frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
COPY --link frankenphp/Caddyfile /etc/frankenphp/Caddyfile

ENTRYPOINT ["docker-entrypoint"]

HEALTHCHECK --start-period=60s CMD curl -f http://localhost:2019/metrics || exit 1
CMD [ "frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile" ]

# Dev FrankenPHP image
FROM frankenphp_base AS frankenphp_dev

# Install dde development depencencies
# .dde/configure-image.sh will be created automatically
COPY .dde/configure-image.sh /tmp/dde-configure-image.sh
ARG DDE_UID
ARG DDE_GID
RUN /tmp/dde-configure-image.sh

ENV APP_ENV=dev
ENV XDEBUG_MODE=off
ENV FRANKENPHP_WORKER_CONFIG=watch


ENV APP_RUNTIME=Runtime\\FrankenPhpSymfony\\Runtime
ENV TZ=Europe/Zurich

RUN adduser --disabled-password --no-create-home smartlearn && \
    setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp && \
    chown -R smartlearn:smartlearn /config && \
    chown -R smartlearn:smartlearn /data/caddy && \
    apt update && \
    apt install -y --no-install-recommends vim unzip sshpass xorriso fonts-noto-color-emoji clamav-daemon opendoas openssh-client runit graphviz curl iproute2 npm ghostscript socat && \
    echo "permit nopass keepenv :root" > /etc/doas.conf && \
    echo "" >> /etc/doas.conf && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
    curl -o - https://getcomposer.org/installer | php -- --quiet --2 --install-dir /usr/local/bin --filename composer && \
    install-php-extensions bcmath ldap pcntl soap sockets gmp redis gd intl pdo_mysql sodium zip excimer opcache apcu && \
    cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    echo "date.timezone=$TZ" > /usr/local/etc/php/conf.d/99_timezone.ini && \
    mkdir /home/smartlearn && \
    chown -R smartlearn:smartlearn /home/smartlearn

RUN apt update && \
    apt install -y --no-install-recommends graphviz mariadb-client nodejs git && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
    install-php-extensions xdebug-^3 && \
    install -d -m 0755 -o $DDE_UID -g $DDE_GID var && \
    install -d -m 0755 -o $DDE_UID -g $DDE_GID var/generated && \
    install -d -m 0755 -o $DDE_UID -g $DDE_GID vendor && \
    chown -R $DDE_UID:$DDE_GID /config && \
    chown -R $DDE_UID:$DDE_GID /data/caddy


RUN set -eux;

COPY --link frankenphp/conf.d/20-app.dev.ini $PHP_INI_DIR/app.conf.d/

CMD [ "frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile", "--watch" ]

WORKDIR /var/www/
ENTRYPOINT []
