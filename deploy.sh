#!/usr/bin/env bash
set -euo pipefail

sudo nginx -t
sudo systemctl reload nginx

echo "Deployed $(git rev-parse --short HEAD) at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
