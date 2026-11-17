#!/usr/bin/env bash
# Se ejecuta en cada inicio del Codespace. Idempotente y no destructivo:
# no borra volúmenes, no regenera contraseñas existentes y reutiliza contenedores.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

log "===== Arranque del laboratorio Odoo 17 (postStart) ====="

esperar_docker || exit 0

# Por si postCreate no llegó a completarse (no sobrescribe nada existente).
bash "$LAB_DIR/scripts/init-secrets.sh" 2>&1 | tee -a "$LOG_FILE"
descargar_imagen postgres:15 || exit 0
descargar_imagen odoo:17.0   || exit 0

# Primero la base de datos; luego se asegura que su contraseña coincida con .env
# (cubre el caso de un .env perdido con datos ya existentes; sin borrar nada).
log "Iniciando PostgreSQL 15…"
if ! "${COMPOSE[@]}" up -d --wait db >>"$LOG_FILE" 2>&1; then
  error "PostgreSQL no arrancó. Detalles en odoo-lab/logs/arranque.log"
  bash "$(dirname "$0")/estado.sh"
  exit 0
fi
bash "$LAB_DIR/scripts/sync-db-password.sh" >>"$LOG_FILE" 2>&1 \
  && ok "Credenciales de PostgreSQL sincronizadas con .env." \
  || aviso "No se pudo sincronizar la contraseña de PostgreSQL (ver log)."

log "Iniciando Odoo 17 (puede tardar hasta 1-2 minutos)…"
if ! "${COMPOSE[@]}" up -d --wait --wait-timeout 300 >>"$LOG_FILE" 2>&1; then
  # Un contenedor que falló antes puede arrastrar el estado "unhealthy".
  # Se recrea SOLO el contenedor de Odoo; los volúmenes y datos se conservan.
  aviso "Odoo no quedó sano al primer intento; se recrea su contenedor (los datos se conservan)…"
  if ! "${COMPOSE[@]}" up -d --wait --wait-timeout 300 --force-recreate odoo >>"$LOG_FILE" 2>&1; then
    error "Odoo no quedó sano a tiempo. Últimas líneas del log de Odoo:"
    "${COMPOSE[@]}" logs --tail 30 odoo 2>&1 | tee -a "$LOG_FILE"
  fi
fi

bash "$(dirname "$0")/estado.sh"
exit 0
