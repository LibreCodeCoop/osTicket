FROM php:8.3.36-apache-bookworm

# Reject upstream PHP images without fixes for CVE-2026-109618 / CVE-2026-109619.
# The PHP variables must remain shell-quoted, not expanded by /bin/sh.
RUN php -r '$minimum = ["8.2" => "8.2.35", "8.3" => "8.3.36", "8.4" => "8.4.27", "8.5" => "8.5.12"]; $series = PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION; if (!isset($minimum[$series]) || version_compare(PHP_VERSION, $minimum[$series], "<")) { fwrite(STDERR, "Unpatched or unsupported PHP runtime: " . PHP_VERSION . PHP_EOL); exit(1); }'

ENV APACHE_DOCUMENT_ROOT=/var/www/html \
    OSTICKET_APP=/var/www/html \
    OSTICKET_SRC=/srv/osticket-src

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        libc-client2007e-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libkrb5-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
    && docker-php-source extract \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && ac_cv_utf8_mime2text=new ac_cv_u8t_decompose=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j"$(nproc)" \
        gd \
        gettext \
        imap \
        intl \
        mysqli \
        opcache \
        zip \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && docker-php-source delete \
    && a2enmod expires headers rewrite \
    && sed -ri "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" \
        /etc/apache2/apache2.conf \
        /etc/apache2/conf-available/*.conf \
        /etc/apache2/sites-available/*.conf \
    && rm -rf /var/lib/apt/lists/*

COPY . /srv/osticket-src
COPY docker/i18n/ /opt/osticket-i18n/
COPY docker/apache/osticket.conf /etc/apache2/conf-available/osticket.conf
COPY docker/php/osticket.ini /usr/local/etc/php/conf.d/osticket.ini
COPY docker/entrypoint.sh /usr/local/bin/osticket-entrypoint

RUN chmod +x /usr/local/bin/osticket-entrypoint \
    && a2enconf osticket \
    && mkdir -p /var/www/html

WORKDIR /var/www/html

ENTRYPOINT ["osticket-entrypoint"]
CMD ["apache2-foreground"]
