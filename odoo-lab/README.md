# odoo-lab — Odoo 17 + PostgreSQL 15 (Docker Compose)

Entorno de laboratorio para el sistema de tickets de mantenimiento correctivo de
`harmak-tickets-lab`. **Solo datos de prueba**: no cargues datos empresariales reales
ni conectes servicios productivos.

## Uso con GitHub Codespaces (automático, sin terminal)

1. En GitHub: **Code → Codespaces → Create codespace on main**.
2. Espera a que termine la preparación (la primera vez, unos 3-5 minutos: instala
   Docker, genera credenciales, descarga imágenes y arranca los servicios).
3. Cuando aparezca el aviso del puerto **8069 «Odoo 17»**, pulsa **Open in Browser**.
   También puedes ir a la pestaña **PORTS** → fila *Odoo 17* → icono del globo.
4. Comprueba en la pestaña **PORTS** que la columna *Visibility* diga **Private**
   (valor por defecto). Si dijera otra cosa: clic derecho → *Port Visibility* → *Private*.

Al abrir una terminal verás un resumen de salud en español. El historial completo
está en `odoo-lab/logs/arranque.log` (puedes abrirlo desde el explorador de archivos).

### Qué se automatiza

| Momento | Script | Qué hace |
|---|---|---|
| Crear el Codespace | `.devcontainer/scripts/post-create.sh` | Genera credenciales (si no existen) y descarga `postgres:15` y `odoo:17.0` |
| Cada inicio/reinicio | `.devcontainer/scripts/post-start.sh` | Arranca PostgreSQL, sincroniza su contraseña con `.env`, arranca Odoo y verifica la salud |
| Abrir terminal/editor | `.devcontainer/scripts/estado.sh --resumen` | Muestra el último resumen de salud |

Garantías (idempotencia):

- **No regenera contraseñas** existentes: `.env` y `config/odoo.conf` solo se crean si faltan.
- **No borra datos**: nunca se ejecuta `docker compose down -v` ni se eliminan volúmenes.
- **No duplica recursos**: Compose reutiliza los mismos contenedores, red y volúmenes.
- Si `.env` se perdiera con datos existentes, se genera uno nuevo y la contraseña de
  PostgreSQL se actualiza (`ALTER ROLE`) sin tocar los datos.
- Las contraseñas **no se imprimen** en registros ni en la terminal.

## Contenido

| Archivo | Propósito | ¿En Git? |
|---|---|---|
| `compose.yaml` | Servicios `db` (postgres:15) y `odoo` (odoo:17.0), volúmenes y healthchecks | Sí |
| `.env.example` | Plantilla de variables (sin secretos) | Sí |
| `scripts/init-secrets.sh` | Genera `.env` y `config/odoo.conf` con contraseñas aleatorias (idempotente) | Sí |
| `scripts/sync-db-password.sh` | Alinea la contraseña de PostgreSQL con `.env` (no destructivo) | Sí |
| `addons/` | Módulos propios (aquí irá el módulo de tickets) | Sí |
| `.env` | Contraseñas reales de PostgreSQL y contraseña maestra de Odoo | **No** |
| `config/odoo.conf` | Configuración de Odoo con `admin_passwd` | **No** |
| `logs/` | Registros del arranque automático (sin secretos) | **No** |

## Crear la base de datos de pruebas

1. La primera vez Odoo abre `/web/database/manager`.
2. **Master Password**: en el explorador de archivos abre `odoo-lab/.env` y copia el
   valor de `ODOO_ADMIN_PASSWD`.
3. Nombre sugerido: `harmak_pruebas`; idioma Español; país el que corresponda.
   Puedes marcar *Demo data* para tener datos ficticios.
4. Define un email/usuario y contraseña de administrador (de prueba).

## Instalar Compras, Inventario y Contactos

En Odoo → **Aplicaciones**, pulsa *Activar* en **Contactos**, **Inventario** y **Compras**.

## Persistencia

| Volumen | Contenido |
|---|---|
| `harmak-odoo-lab_db-data` | Datos de PostgreSQL |
| `harmak-odoo-lab_odoo-data` | Filestore (adjuntos) y sesiones de Odoo |

Se conservan al detener/reiniciar el Codespace y al hacer *Rebuild Container*.
Se pierden si **eliminas el Codespace**.

## Uso manual (fuera de Codespaces, opcional)

```bash
cd odoo-lab && ./scripts/init-secrets.sh && docker compose up -d --wait
```

```bash
bash .devcontainer/scripts/estado.sh
```
