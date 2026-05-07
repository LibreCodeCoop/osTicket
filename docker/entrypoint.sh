#!/bin/sh
set -eu

OSTICKET_APP="${OSTICKET_APP:-/var/www/html}"
OSTICKET_SRC="${OSTICKET_SRC:-/srv/osticket-src}"
OSTICKET_DEPLOY_ON_START="${OSTICKET_DEPLOY_ON_START:-1}"
OSTICKET_CONFIG="${OSTICKET_APP}/include/ost-config.php"
OSTICKET_I18N_SRC="${OSTICKET_I18N_SRC:-/opt/osticket-i18n}"
OSTICKET_SAMPLE_CONFIG="${OSTICKET_APP}/include/ost-sampleconfig.php"
OSTICKET_SETUP_DIR="${OSTICKET_APP}/setup"

deploy_osticket() {
    if [ ! -f "${OSTICKET_SRC}/manage.php" ]; then
        echo "osTicket source not found at ${OSTICKET_SRC}" >&2
        exit 1
    fi

    git config --global --add safe.directory "${OSTICKET_SRC}" >/dev/null 2>&1 || true

    mkdir -p "${OSTICKET_APP}"
    (
        cd "${OSTICKET_SRC}"
        php manage.php deploy --setup "${OSTICKET_APP}"
    )
}

prepare_config() {
    if [ ! -f "${OSTICKET_CONFIG}" ] && [ -f "${OSTICKET_SAMPLE_CONFIG}" ]; then
        cp "${OSTICKET_SAMPLE_CONFIG}" "${OSTICKET_CONFIG}"
    fi

    if [ -f "${OSTICKET_CONFIG}" ]; then
        if grep -q "%CONFIG-DBHOST" "${OSTICKET_CONFIG}"; then
            chmod 0666 "${OSTICKET_CONFIG}"
        else
            chmod 0644 "${OSTICKET_CONFIG}"
        fi
    fi
}

prepare_runtime_dirs() {
    mkdir -p \
        "${OSTICKET_APP}/include/i18n" \
        "${OSTICKET_APP}/include/mpdf/tmp" \
        "${OSTICKET_APP}/include/mpdf/ttfontdata"
    chown -R www-data:www-data "${OSTICKET_APP}"
}

install_language_packs() {
    if [ -d "${OSTICKET_I18N_SRC}" ]; then
        find "${OSTICKET_I18N_SRC}" -maxdepth 1 -type f -name '*.phar' -exec cp {} "${OSTICKET_APP}/include/i18n/" \;
    fi
}

installation_complete() {
    [ -f "${OSTICKET_CONFIG}" ] \
        && ! grep -q "define('OSTINSTALLED',FALSE);" "${OSTICKET_CONFIG}" 2>/dev/null
}

finalize_installation() {
    chmod 0644 "${OSTICKET_CONFIG}" 2>/dev/null || true
    rm -rf "${OSTICKET_SETUP_DIR}" 2>/dev/null || true
}

finalize_after_install() {
    (
        while [ ! -f "${OSTICKET_CONFIG}" ]; do
            sleep 2
        done

        while ! installation_complete; do
            sleep 2
        done

        finalize_installation
    ) &
}

if [ ! -f "${OSTICKET_APP}/index.php" ] || [ "${OSTICKET_DEPLOY_ON_START}" = "1" ]; then
    deploy_osticket
fi

prepare_config
prepare_runtime_dirs
install_language_packs

if installation_complete; then
    finalize_installation
else
    finalize_after_install
fi

exec "$@"
