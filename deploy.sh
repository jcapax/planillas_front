#!/usr/bin/env bash
#
# deploy.sh - Compila el frontend y despliega los archivos estáticos en un servidor remoto.
#
# Uso: ./deploy.sh
# El script pedirá la IP, el usuario y la contraseña SSH del servidor.
# La misma contraseña se usa para sudo al reiniciar el servicio.
# Requiere: node/npm (para compilar) y, opcionalmente, sshpass (para enviar la
# contraseña de forma no interactiva). Si no hay sshpass, se usa scp/ssh
# interactivo y la contraseña se pide en el prompt del sistema.
#
set -euo pipefail

# ---------- Configuración (editar si es necesario) ----------
REMOTE_DIR="/var/www/html/personal"   # carpeta destino de los archivos estáticos
BASE_PATH="/personal"                 # ruta base donde se sirve la app (debe coincidir con REMOTE_DIR en la URL)
SERVICE_NAME=""                       # opcional: nombre del servicio systemd a reiniciar (ej: nginx)
CLEAN_REMOTE=1                        # 1 = eliminar archivos anteriores antes de subir, 0 = conservarlos
NGINX_SNIPPET="/etc/nginx/snippets/personal-sids.conf"  # snippet nginx (SPA fallback + proxy /api/personal)
NGINX_API_PATH="/api/personal"        # ruta del backend nuevo que se proxya
NGINX_API_PORT=8086                   # puerto del backend nuevo (proxy_pass)
# ------------------------------------------------------------

ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
SIN_COLOR='\033[0m'

FRONTEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$FRONTEND_DIR/dist"

info()  { echo -e "${VERDE}[INFO]${SIN_COLOR} $*"; }
warn()  { echo -e "${AMARILLO}[WARN]${SIN_COLOR} $*"; }
error() { echo -e "${ROJO}[ERROR]${SIN_COLOR} $*"; }

if ! command -v npm >/dev/null 2>&1; then
    error "Node.js/npm no está instalado (comando 'npm' no encontrado)."
    exit 1
fi

SSHPASS_AVAILABLE=0
if command -v sshpass >/dev/null 2>&1; then
    SSHPASS_AVAILABLE=1
else
    warn "sshpass no está instalado; se usará scp/ssh interactivo."
    warn "En Debian/Ubuntu puedes instalarlo con: sudo apt install sshpass"
fi

# ---------------- Pedir datos del servidor ----------------
echo "=== Deploy Frontend Personal SIDS ==="
echo
read -r -p "IP del servidor: " SERVER_IP
read -r -p "Usuario SSH:      " SSH_USER
read -r -s -p "Contraseña SSH:   " SSH_PASS
echo

if [ -z "$SERVER_IP" ] || [ -z "$SSH_USER" ]; then
    error "La IP y el usuario son obligatorios."
    exit 1
fi

SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new"
DEST="$SSH_USER@$SERVER_IP"

ssh_run() {
    if [ "$SSHPASS_AVAILABLE" -eq 1 ]; then
        sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$@"
    else
        ssh $SSH_OPTS "$@"
    fi
}

# Ejecuta un comando remoto con sudo, usando la misma contraseña SSH.
# El primer argumento es "destino" y el resto es el comando a ejecutar como root.
sudo_run() {
    local dest="$1"
    shift
    local remote_cmd="$*"
    if [ "$SSHPASS_AVAILABLE" -eq 1 ]; then
        # Se envía la contraseña por stdin para que sudo la lea con -S
        printf '%s\n' "$SSH_PASS" | sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$dest" \
            "sudo -S bash -c '$remote_cmd'"
    else
        # Interactivo: se asigna un pty para que sudo pida la contraseña
        ssh $SSH_OPTS -t "$dest" "sudo bash -c '$remote_cmd'"
    fi
}

# ---------------- Compilar ----------------
info "Compilando el frontend (npm run build -- --base=$BASE_PATH/)..."
cd "$FRONTEND_DIR"
npm run build -- --base="$BASE_PATH/"

if [ ! -d "$DIST_DIR" ]; then
    error "No se encontró la carpeta dist/ después de compilar."
    exit 1
fi

# ---------------- Crear carpeta remota ----------------
info "Creando directorio remoto $REMOTE_DIR ..."
ssh_run "$DEST" "mkdir -p '$REMOTE_DIR'"

# ---------------- Limpiar carpeta remota (opcional) ----------------
if [ "$CLEAN_REMOTE" -eq 1 ]; then
    info "Eliminando archivos anteriores en $REMOTE_DIR ..."
    ssh_run "$DEST" "rm -rf '$REMOTE_DIR'/*"
fi

# ---------------- Subir los archivos ----------------
info "Subiendo el contenido de dist/ a $DEST:$REMOTE_DIR/ ..."
if [ "$SSHPASS_AVAILABLE" -eq 1 ]; then
    tar -C "$DIST_DIR" -czf - . | sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$DEST" \
        "tar -xzf - -C '$REMOTE_DIR'"
else
    tar -C "$DIST_DIR" -czf - . | ssh $SSH_OPTS "$DEST" \
        "tar -xzf - -C '$REMOTE_DIR'"
fi

# ---------------- Configurar nginx (SPA fallback + proxy /api) ----------------
info "Configurando nginx (SPA fallback y proxy /api -> backend)..."

NGINX_SETUP="/tmp/personal-sids-nginx.sh"
NGINX_API_PATH="${NGINX_API_PATH:-/api/personal}"
NGINX_API_PORT="${NGINX_API_PORT:-8086}"
cat > "$NGINX_SETUP" <<NGINXEOF
#!/usr/bin/env bash
set -euo pipefail

SNIPPET="/etc/nginx/snippets/personal-sids.conf"
BACKUP_DIR="/tmp/personal-sids-nginx-backup"
API_PATH="${NGINX_API_PATH}"
API_PORT="${NGINX_API_PORT}"

rm -rf "\$BACKUP_DIR"
mkdir -p /etc/nginx/snippets "\$BACKUP_DIR"

# No duplicar si ya existe un location para el API nuevo
API_EXISTS=0
if grep -rqE "location[[:space:]]*(=|~\*?|\^~)?[[:space:]]*/\$API_PATH" /etc/nginx/sites-enabled/ 2>/dev/null; then
    API_EXISTS=1
fi

{
    echo 'location /personal/ {'
    echo '    try_files \$uri \$uri/ /personal/index.html;'
    echo '}'
    echo ''
    if [ "\$API_EXISTS" -eq 0 ]; then
        echo "location \$API_PATH {"
        echo "    proxy_pass http://127.0.0.1:\$API_PORT;"
        echo '    proxy_set_header Host \$host;'
        echo '    proxy_set_header X-Real-IP \$remote_addr;'
        echo '    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;'
        echo '    proxy_set_header X-Forwarded-Proto \$scheme;'
        echo '}'
    fi
} > "\$SNIPPET"

# Incluir el snippet en todos los sitios que tengan server blocks y no lo incluyan aún.
# Los backups se guardan en /tmp (fuera de sites-enabled) para que nginx -t no los vea.
if [ -d /etc/nginx/sites-enabled ]; then
    for f in /etc/nginx/sites-enabled/*; do
        [ -f "\$f" ] || continue
        if ! grep -qF "\$SNIPPET" "\$f"; then
            cp -a "\$f" "\$BACKUP_DIR/\$(basename "\$f")"
            sed -i -E "s|^([[:space:]]*)server[[:space:]]*\{|\1server {\n\1    include \$SNIPPET;|" "\$f"
        fi
    done
fi

if ! nginx -t; then
    echo "ERROR: nginx -t falló; restaurando la configuración anterior." >&2
    for b in "\$BACKUP_DIR"/*; do
        [ -f "\$b" ] || continue
        cp -a "\$b" "/etc/nginx/sites-enabled/\$(basename "\$b")"
    done
    rm -rf "\$BACKUP_DIR"
    exit 1
fi

rm -rf "\$BACKUP_DIR"
systemctl reload nginx
echo "nginx configurado correctamente"
NGINXEOF

scp_run() {
    if [ "$SSHPASS_AVAILABLE" -eq 1 ]; then
        sshpass -p "$SSH_PASS" scp $SSH_OPTS "$@"
    else
        scp $SSH_OPTS "$@"
    fi
}

scp_run "$NGINX_SETUP" "$DEST:/tmp/personal-sids-nginx.sh"

if [ "$SSHPASS_AVAILABLE" -eq 1 ]; then
    printf '%s\n' "$SSH_PASS" | sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$DEST" \
        "sudo -S bash /tmp/personal-sids-nginx.sh"
else
    ssh $SSH_OPTS -t "$DEST" "sudo bash /tmp/personal-sids-nginx.sh"
fi
ssh_run "$DEST" "rm -f /tmp/personal-sids-nginx.sh"

# ---------------- Reiniciar servicio (opcional) ----------------
if [ -n "$SERVICE_NAME" ]; then
    info "Reiniciando el servicio systemd '$SERVICE_NAME' (sudo)..."
    RESTART_CMD="systemctl restart $SERVICE_NAME && systemctl is-active $SERVICE_NAME"
    sudo_run "$DEST" "$RESTART_CMD"
    info "Servicio '$SERVICE_NAME' reiniciado."
else
    warn "SERVICE_NAME no configurado; los archivos se copiaron pero no se reinició ningún servicio."
fi

echo
info "Deploy completado."
