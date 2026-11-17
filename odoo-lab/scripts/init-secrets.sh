#!/usr/bin/env bash
# Genera .env y config/odoo.conf con contraseñas aleatorias.
# Idempotente: si ya existen, NO los modifica. Nunca imprime las contraseñas.
#   --force  regenera .env (solo si de verdad quieres rotar credenciales;
#            el arranque automático sincroniza después la contraseña de PostgreSQL).
set -euo pipefail
cd "$(dirname "$0")/.."

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

gen() { openssl rand -base64 48 | tr -d '/+=\n' | cut -c1-32; }
umask 077

if [[ -f .env && $FORCE -eq 0 ]]; then
  echo "Credenciales: .env ya existe, se conserva sin cambios."
else
  cat > .env <<EOF
POSTGRES_USER=odoo
POSTGRES_PASSWORD=$(gen)
ODOO_ADMIN_PASSWD=$(gen)
ODOO_PORT=8069
EOF
  echo "Credenciales: .env generado con contraseñas aleatorias (no se muestran)."
fi

# odoo.conf se deriva de .env; se (re)crea si falta o si su contraseña maestra no coincide.
ADMIN_PASS="$(grep -E '^ODOO_ADMIN_PASSWD=' .env | cut -d= -f2-)"
mkdir -p config
if [[ -f config/odoo.conf ]] && grep -qxF "admin_passwd = ${ADMIN_PASS}" config/odoo.conf; then
  echo "Configuración: config/odoo.conf ya existe y es coherente con .env."
else
  cat > config/odoo.conf <<EOF
[options]
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo
admin_passwd = ${ADMIN_PASS}
list_db = True
proxy_mode = False
EOF
  echo "Configuración: config/odoo.conf generado a partir de .env."
fi
# El contenedor de Odoo corre como el usuario "odoo" (uid 100): debe poder
# atravesar la carpeta y leer el archivo (umask 077 los habría dejado privados).
chmod 755 config
chmod 644 config/odoo.conf
