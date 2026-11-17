# Funciones comunes de los scripts del devcontainer. No imprime secretos.
# shellcheck shell=bash

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LAB_DIR="$REPO_ROOT/odoo-lab"
LOG_DIR="$LAB_DIR/logs"
LOG_FILE="$LOG_DIR/arranque.log"
RESUMEN_FILE="$LOG_DIR/ultimo-estado.txt"
COMPOSE=(docker compose --project-directory "$LAB_DIR" -f "$LAB_DIR/compose.yaml")

mkdir -p "$LOG_DIR"

log() {
  local msg
  msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}
ok()    { log "✅ $*"; }
aviso() { log "⚠️  $*"; }
error() { log "❌ $*"; }

# Espera a que el demonio Docker (docker-in-docker) esté disponible.
esperar_docker() {
  local i
  for i in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then
      ok "Docker está disponible."
      return 0
    fi
    sleep 2
  done
  error "Docker no respondió tras 120 s. Reinicia el Codespace desde github.com/codespaces."
  return 1
}

# Descarga una imagen con reintentos (Docker Hub puede limitar peticiones).
descargar_imagen() {
  local img="$1" i
  if docker image inspect "$img" >/dev/null 2>&1; then
    ok "Imagen $img ya presente."
    return 0
  fi
  for i in 1 2 3 4 5; do
    log "Descargando imagen $img (intento $i)…"
    if docker pull -q "$img" >/dev/null 2>>"$LOG_FILE"; then
      ok "Imagen $img descargada."
      return 0
    fi
    sleep $((i * 15))
  done
  error "No se pudo descargar $img."
  return 1
}
