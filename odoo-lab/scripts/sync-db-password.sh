#!/usr/bin/env bash
# Asegura que la contraseña del usuario de PostgreSQL coincide con la de .env.
# No destructivo: solo ALTER ROLE. Usa el socket local del contenedor (sin
# contraseña) y pasa el valor por stdin para que no aparezca en procesos ni logs.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a; source ./.env; set +a
PASS_SQL="${POSTGRES_PASSWORD//\'/\'\'}"

docker compose exec -T db psql -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres >/dev/null <<EOF
ALTER ROLE "${POSTGRES_USER}" WITH PASSWORD '${PASS_SQL}';
EOF
