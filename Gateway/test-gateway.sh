#!/usr/bin/env bash
set -euo pipefail

readonly NAS_TAILSCALE_IP="100.75.3.34"
readonly NAS_API_PORT="8000"
readonly LISTEN_PORT="8080"

echo "1. Estado de Tailscale"
tailscale status

echo
echo "2. Ping Tailscale al NAS"
tailscale ping --timeout=5s "${NAS_TAILSCALE_IP}"

echo
echo "3. Endpoint directo del NAS"
curl --fail --show-error --silent \
    "http://${NAS_TAILSCALE_IP}:${NAS_API_PORT}/health"
echo

echo
echo "4. Estado de Nginx"
systemctl is-active nginx
ss -ltn | grep -E ":${LISTEN_PORT}[[:space:]]"

echo
echo "5. Endpoint a traves del gateway local"
curl --fail --show-error --silent \
    "http://127.0.0.1:${LISTEN_PORT}/health"
echo

echo
echo "PRUEBA COMPLETADA: Raspberry Pi -> Tailscale -> NAS"

