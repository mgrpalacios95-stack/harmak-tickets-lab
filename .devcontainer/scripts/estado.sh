#!/usr/bin/env bash
# Verificación de salud del laboratorio con resumen en español.
#   estado.sh            -> ejecuta las comprobaciones y guarda el resumen
#   estado.sh --resumen  -> muestra el último resumen guardado (rápido)
set -uo pipefail
source "$(dirname "$0")/lib.sh"

if [[ "${1:-}" == "--resumen" ]]; then
  if [[ -f "$RESUMEN_FILE" ]]; then
    cat "$RESUMEN_FILE"
  else
    echo "El laboratorio Odoo aún se está preparando. Progreso: odoo-lab/logs/arranque.log"
  fi
  exit 0
fi

FALLOS=0
LINEAS=()
add()   { LINEAS+=("$1"); }
check() { if [[ "$1" == 0 ]]; then add "  ✅ $2"; else add "  ❌ $3"; FALLOS=$((FALLOS+1)); fi; }

estado_contenedor() {
  docker inspect -f '{{.State.Health.Status}}' "harmak-odoo-lab-$1-1" 2>/dev/null || echo "inexistente"
}

[[ -f "$LAB_DIR/.env" && -f "$LAB_DIR/config/odoo.conf" ]]
check $? "Credenciales generadas (odoo-lab/.env y config/odoo.conf, fuera de Git)" \
         "Faltan credenciales: odoo-lab/.env o config/odoo.conf"

docker info >/dev/null 2>&1
check $? "Docker en ejecución" "Docker no responde"

S_DB="$(estado_contenedor db)"
[[ "$S_DB" == healthy ]]
check $? "PostgreSQL 15 sano" "PostgreSQL 15 no está sano (estado: $S_DB)"

S_ODOO="$(estado_contenedor odoo)"
[[ "$S_ODOO" == healthy ]]
check $? "Contenedor Odoo 17 sano" "Contenedor Odoo 17 no está sano (estado: $S_ODOO)"

HEALTH="$(curl -fsS --max-time 10 http://127.0.0.1:8069/web/health 2>/dev/null)"
[[ "$HEALTH" == *pass* ]]
check $? "Odoo responde en http://127.0.0.1:8069 (/web/health = pass)" \
         "Odoo no responde en el puerto 8069"

VERSION="$(curl -fsS --max-time 10 -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","params":{}}' http://127.0.0.1:8069/web/webclient/version_info 2>/dev/null \
  | grep -o '"server_serie": *"[^"]*"' | cut -d'"' -f4)"
[[ "$VERSION" == 17.0 ]]
check $? "Versión de Odoo: $VERSION" "No se pudo confirmar la versión 17.0 de Odoo"

for v in harmak-odoo-lab_db-data harmak-odoo-lab_odoo-data; do
  docker volume inspect "$v" >/dev/null 2>&1
  check $? "Volumen persistente $v" "Falta el volumen $v"
done

# Visibilidad del puerto en Codespaces (privado por defecto). Solo informativo.
if [[ -n "${CODESPACE_NAME:-}" ]]; then
  URL="https://${CODESPACE_NAME}-8069.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  VIS="$(gh codespace ports -c "$CODESPACE_NAME" --json sourcePort,visibility \
         -q '.[] | select(.sourcePort==8069) | .visibility' 2>/dev/null)"
  case "$VIS" in
    private) add "  ✅ Puerto 8069 privado (solo accesible con tu sesión de GitHub)";;
    "")      add "  ℹ️  Puerto 8069: privado por defecto; compruébalo en la pestaña PORTS (columna Visibility)";;
    *)       add "  ⚠️  Puerto 8069 con visibilidad '$VIS'. Cámbialo a Private en la pestaña PORTS"; FALLOS=$((FALLOS+1));;
  esac
else
  URL="http://localhost:8069"
fi

{
  echo "──────────────── Laboratorio Odoo 17 · $(date '+%Y-%m-%d %H:%M:%S') ────────────────"
  printf '%s\n' "${LINEAS[@]}"
  if [[ $FALLOS -eq 0 ]]; then
    echo "  RESULTADO: todo correcto. Abre Odoo en: $URL"
    echo "  (o pestaña PORTS → 8069 'Odoo 17' → icono del globo)"
  else
    echo "  RESULTADO: $FALLOS comprobación(es) fallida(s). Detalle: odoo-lab/logs/arranque.log"
  fi
  echo "  Contraseña maestra: abre el archivo odoo-lab/.env (línea ODOO_ADMIN_PASSWD)."
  echo "─────────────────────────────────────────────────────────────────────────────"
} > "$RESUMEN_FILE"

cat "$RESUMEN_FILE"
cat "$RESUMEN_FILE" >> "$LOG_FILE"
[[ $FALLOS -eq 0 ]]
