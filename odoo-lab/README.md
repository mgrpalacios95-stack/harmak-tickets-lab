# odoo-lab — Odoo 17 + PostgreSQL 15 (Docker Compose)

Entorno de laboratorio para el sistema de tickets de mantenimiento correctivo de
`harmak-tickets-lab`. **Solo datos de prueba**: no cargues datos empresariales reales.

## Contenido

| Archivo | Propósito | ¿En Git? |
|---|---|---|
| `compose.yaml` | Servicios `db` (postgres:15) y `odoo` (odoo:17.0), volúmenes y healthchecks | Sí |
| `.env.example` | Plantilla de variables (sin secretos) | Sí |
| `scripts/init-secrets.sh` | Genera `.env` y `config/odoo.conf` con contraseñas aleatorias | Sí |
| `addons/` | Módulos propios (aquí irá el módulo de tickets) | Sí |
| `.env` | Contraseñas reales de PostgreSQL y contraseña maestra de Odoo | **No** (`.gitignore`) |
| `config/odoo.conf` | Configuración de Odoo con `admin_passwd` | **No** (`.gitignore`) |

## Puesta en marcha (Codespaces o cualquier host con Docker)

```bash
cd odoo-lab
./scripts/init-secrets.sh
docker compose up -d --wait
docker compose ps
```

`--wait` espera a que ambos contenedores estén `healthy`. Comprobación rápida:

```bash
curl -fsS http://127.0.0.1:8069/web/health
```

Debe responder `{"status": "pass"}`.

## Abrir Odoo en Chrome (Codespaces)

1. En VS Code / navegador del Codespace abre la pestaña **Ports**.
2. Busca el puerto **8069** y pulsa el icono del globo («Open in Browser»).
3. Comprueba que la columna *Visibility* diga **Private** (es el valor por defecto).
   Si no, clic derecho → *Port Visibility* → *Private*. Desde la terminal:
   `gh codespace ports visibility 8069:private -c $CODESPACE_NAME`

El puerto se publica solo en `127.0.0.1` del Codespace y PostgreSQL no se publica
en absoluto (solo es accesible dentro de la red de Compose).

## Crear la base de datos de pruebas

1. Abre `/web/database/manager` (aparece solo la primera vez).
2. **Master Password**: obtenla con `grep ODOO_ADMIN_PASSWD .env`.
3. Nombre sugerido: `harmak_pruebas`; idioma Español; país España (o el que corresponda).
   Puedes marcar *Demo data* si quieres datos ficticios.
4. Define un email/usuario y contraseña de administrador (de prueba).

## Instalar Compras, Inventario y Contactos

En Odoo → **Aplicaciones**, quita el filtro «Aplicaciones» si hace falta y
pulsa *Activar* en:

- **Contactos** (`contacts`)
- **Inventario** (`stock`)
- **Compras** (`purchase`)

## Operación diaria

```bash
docker compose logs -f odoo     # ver logs
docker compose restart odoo     # reiniciar Odoo (p. ej. tras añadir un addon)
docker compose down             # parar (los datos se conservan)
docker compose down -v          # parar y BORRAR todos los datos del laboratorio
```

## Persistencia

| Volumen | Contenido |
|---|---|
| `harmak-odoo-lab_db-data` | Datos de PostgreSQL |
| `harmak-odoo-lab_odoo-data` | Filestore (adjuntos) y sesiones de Odoo |

Sobreviven a `docker compose down` y a reinicios del Codespace. Se pierden con
`docker compose down -v` o si se elimina el Codespace.

## Rotar credenciales

`./scripts/init-secrets.sh --force` regenera `.env` y `odoo.conf`. Si ya existían
datos, PostgreSQL seguirá con la contraseña antigua: en un laboratorio lo más
simple es `docker compose down -v` y volver a arrancar.
