#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root (sudo bash setup-server.sh <git-repo-url>)" >&2
  exit 1
fi

REPO_URL="${1:?Usage: setup-server.sh <git-repo-url>}"
SITE_DIR=/opt/site
DEPLOY_USER=deploy

apt update
apt install -y nginx ufw git

ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

if ! id "$DEPLOY_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$DEPLOY_USER"
fi
mkdir -p "/home/$DEPLOY_USER/.ssh"
touch "/home/$DEPLOY_USER/.ssh/authorized_keys"
chmod 700 "/home/$DEPLOY_USER/.ssh"
chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"

if [ ! -d "$SITE_DIR/.git" ]; then
  git clone "$REPO_URL" "$SITE_DIR"
else
  git -C "$SITE_DIR" pull --ff-only
fi
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$SITE_DIR"

cat > /etc/sudoers.d/deploy-nginx <<'EOF'
deploy ALL=(root) NOPASSWD: /usr/sbin/nginx -t, /usr/bin/systemctl reload nginx
EOF
chmod 440 /etc/sudoers.d/deploy-nginx

cat > /etc/nginx/sites-available/site <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root $SITE_DIR/www;
    index index.html;
    server_name _;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
ln -sf /etc/nginx/sites-available/site /etc/nginx/sites-enabled/site
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable --now nginx

echo ""
echo "Server ready."
echo "1. Add the CI deploy public key to: /home/$DEPLOY_USER/.ssh/authorized_keys"
echo "2. Visit: http://$(curl -s -4 ifconfig.me || hostname -I | awk '{print $1}')"
