#!/usr/bin/env bash
# Se ejecuta una vez al crear el Codespace. Idempotente: puede repetirse sin efectos.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

log "===== Preparación inicial del laboratorio (postCreate) ====="

# 1) Credenciales: solo se generan si no existen. Nunca se muestran.
bash "$LAB_DIR/scripts/init-secrets.sh" 2>&1 | tee -a "$LOG_FILE"

# 2) Imágenes: se descargan ahora para que el arranque sea rápido.
if esperar_docker; then
  descargar_imagen postgres:15
  descargar_imagen odoo:17.0
fi

log "Preparación inicial terminada. El arranque lo hace postStart."
exit 0
