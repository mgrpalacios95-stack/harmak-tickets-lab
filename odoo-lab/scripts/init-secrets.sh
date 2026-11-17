#!/usr/bin/env bash
# Genera .env y config/odoo.conf con contraseñas aleatorias.
# No sobrescribe archivos existentes salvo que se use --force.
set -euo pipefail

cd "$(dirname "$0")/.."

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

if [[ -f .env && $FORCE -eq 0 ]]; then
  echo ".env ya existe; no se modifica (usa --force para regenerar)."
  echo "AVISO: regenerar con datos existentes rompe el acceso a PostgreSQL;"
  echo "       en ese caso borra también los volúmenes (docker compose down -v)."
  exit 0
fi

gen() { openssl rand -base64 48 | tr -d '/+=\n' | cut -c1-32; }

PG_PASS="$(gen)"
ADMIN_PASS="$(gen)"

umask 077
cat > .env <<EOF
POSTGRES_USER=odoo
POSTGRES_PASSWORD=${PG_PASS}
ODOO_ADMIN_PASSWD=${ADMIN_PASS}
ODOO_PORT=8069
EOF

mkdir -p config
cat > config/odoo.conf <<EOF
[options]
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo
admin_passwd = ${ADMIN_PASS}
list_db = True
proxy_mode = False
EOF
# El contenedor de Odoo corre como el usuario "odoo" (uid 100): debe poder leerlo.
chmod 644 config/odoo.conf

echo "Creados .env y config/odoo.conf (ignorados por Git)."
echo "Contraseña maestra de Odoo:  grep ODOO_ADMIN_PASSWD .env"
