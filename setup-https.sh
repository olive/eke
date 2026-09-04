#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root (sudo bash setup-https.sh <domain>)" >&2
  exit 1
fi

DOMAIN="${1:?Usage: setup-https.sh <domain>  (e.g. fallingsand.duckdns.org)}"

apt update
apt install -y certbot python3-certbot-nginx

certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --redirect --register-unsafely-without-email

systemctl reload nginx

echo ""
echo "HTTPS is live: https://$DOMAIN"
echo "Renewal is automatic (check: systemctl list-timers | grep certbot)"
