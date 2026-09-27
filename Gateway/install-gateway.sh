#!/usr/bin/env bash
set -euo pipefail

readonly NAS_TAILSCALE_IP="100.75.3.34"
readonly NAS_API_PORT="8000"
readonly LISTEN_PORT="8080"
readonly SITE_NAME="food-dispenser-gateway"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_CONFIG="${SCRIPT_DIR}/${SITE_NAME}.nginx.conf"
readonly AVAILABLE_CONFIG="/etc/nginx/sites-available/${SITE_NAME}"
readonly ENABLED_CONFIG="/etc/nginx/sites-enabled/${SITE_NAME}"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Ejecuta este script con sudo: sudo ./install-gateway.sh" >&2
    exit 1
fi

if [[ ! -f "${SOURCE_CONFIG}" ]]; then
    echo "No se encontro ${SOURCE_CONFIG}. Copia toda la carpeta raspberry-pi." >&2
    exit 1
fi

if ! command -v tailscale >/dev/null 2>&1; then
    echo "Tailscale no esta instalado." >&2
    echo "Instalalo primero con las instrucciones oficiales y ejecuta sudo tailscale up." >&2
    exit 1
fi

echo "Comprobando que Tailscale este conectado..."
tailscale status >/dev/null
tailscale ping --timeout=5s "${NAS_TAILSCALE_IP}"

echo "Instalando Nginx y curl..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl

echo "Instalando la configuracion del gateway..."
install -o root -g root -m 0644 "${SOURCE_CONFIG}" "${AVAILABLE_CONFIG}"
ln -sfn "${AVAILABLE_CONFIG}" "${ENABLED_CONFIG}"

nginx -t
systemctl enable nginx
systemctl restart nginx

echo
echo "Gateway instalado."
echo "Entrada local:   http://IP_LOCAL_DE_LA_RASPBERRY:${LISTEN_PORT}"
echo "Destino remoto:  http://${NAS_TAILSCALE_IP}:${NAS_API_PORT}"
echo
echo "Prueba local: curl --fail --show-error http://127.0.0.1:${LISTEN_PORT}/health"

