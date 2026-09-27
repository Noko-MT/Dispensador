#!/usr/bin/env bash
set -euo pipefail

readonly SITE_NAME="food-dispenser-gateway"
readonly AVAILABLE_CONFIG="/etc/nginx/sites-available/${SITE_NAME}"
readonly ENABLED_CONFIG="/etc/nginx/sites-enabled/${SITE_NAME}"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Ejecuta este script con sudo: sudo ./remove-gateway.sh" >&2
    exit 1
fi

rm -f -- "${ENABLED_CONFIG}" "${AVAILABLE_CONFIG}"
nginx -t
systemctl reload nginx

echo "Se retiro solamente la configuracion del gateway."
echo "Nginx y Tailscale permanecen instalados."

