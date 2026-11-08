#!/bin/bash
# Railway entrypoint for Roundcube. Runs as root (upstream does), then hands over to the upstream
# /docker-entrypoint.sh, which writes the config, initialises the SQLite schema and execs Apache.
set -e

PORT="${PORT:-8080}"
DB_DIR="${ROUNDCUBEMAIL_DB_DIR:-/var/roundcube/db}"
CFG_DIR=/var/roundcube/config

# --- Apache follows Railway's PORT ---------------------------------------------------------------------------
sed -i "s/^Listen 80\$/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-enabled/000-default.conf
# The edge terminates TLS: tell PHP the request was https so cookies carry the Secure flag.
cat > /etc/apache2/conf-enabled/railway.conf <<'CONF'
ServerName localhost
SetEnvIf X-Forwarded-Proto "^https$" HTTPS=on
CONF

# --- volume: SQLite database and the session-encryption key live on it ---------------------------------------
mkdir -p "$DB_DIR" "$CFG_DIR"
chown www-data:www-data "$DB_DIR"
if ! su -s /bin/sh www-data -c "touch '$DB_DIR/.write-test' && rm '$DB_DIR/.write-test'"; then
  echo "[railway] ERROR: volume at $DB_DIR is not writable by www-data" >&2
  exit 1
fi
if [ -z "$ROUNDCUBEMAIL_DES_KEY" ]; then
  KEYFILE="$DB_DIR/.des_key"
  if [ ! -s "$KEYFILE" ]; then
    head -c 256 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24 > "$KEYFILE"
    chmod 600 "$KEYFILE"
  fi
  ROUNDCUBEMAIL_DES_KEY="$(cat "$KEYFILE")"
  export ROUNDCUBEMAIL_DES_KEY
fi

# --- mail servers: login page asks for the server unless the deployer pins one -------------------------------
# ROUNDCUBEMAIL_DEFAULT_HOST / _DEFAULT_PORT / _SMTP_SERVER / _SMTP_PORT are optional overrides. With none set,
# the login form shows a Server field and SMTP follows the IMAP host the user signed in to (%h, port 587).
IMAP_HOST="${ROUNDCUBEMAIL_DEFAULT_HOST:-}"
if [ -n "$IMAP_HOST" ]; then IMAP_HOST="${IMAP_HOST}:${ROUNDCUBEMAIL_DEFAULT_PORT:-143}"; fi
if [ -n "$ROUNDCUBEMAIL_SMTP_SERVER" ]; then SMTP_HOST="${ROUNDCUBEMAIL_SMTP_SERVER}:${ROUNDCUBEMAIL_SMTP_PORT:-587}"; else SMTP_HOST="tls://%h:587"; fi
cat > "$CFG_DIR/railway.inc.php" <<PHP
<?php
\$config['imap_host'] = '${IMAP_HOST}';
\$config['smtp_host'] = '${SMTP_HOST}';
\$config['smtp_user'] = '%u';
\$config['smtp_pass'] = '%p';
\$config['ip_check'] = false;
\$config['session_lifetime'] = 60;
\$config['login_autocomplete'] = 0;
PHP

exec /docker-entrypoint.sh "$@"
