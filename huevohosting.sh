#!/bin/bash

# =============================
#  HUEVO-HOSTING v1.0
#  Hosting Profesional Gratis
#  Powered by Cloudflare Tunnel
#  Creado por: HUEVOMAN77
# =============================

CF_DIR="$HOME/.cloudflared"
SERVICE_FILE="$CF_DIR/huevohosting.service"
LOG_FILE="$HOME/huevo_hosting.log"

RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

banner() {
    echo -e "${CYAN}"
    echo "   _   _                        _   _           _   "
    echo "  | | | |_   _  ___  ___ ___  | | | | ___  ___| |_ "
    echo "  | |_| | | | |/ _ \/ __/ __| | |_| |/ _ \/ __| __|"
    echo "  |  _  | |_| |  __/\__ \__ \ |  _  |  __/\__ \ |_ "
    echo "  |_| |_|\__,_|\___||___/___/ |_| |_|\___||___/\__|"
    echo -e "${YELLOW}     Hosting Profesional Gratis • Cloudflare Tunnel${RESET}"
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') — $1" >> "$LOG_FILE"
}

install_cloudflared() {
    pkg update -y
    pkg install cloudflared -y
}

setup_domain() {
    clear
    banner
    echo -e "${GREEN}Ingresa tu dominio (ejemplo: miweb.com):${RESET}"
    read DOMAIN

    mkdir -p "$CF_DIR"

    cloudflared tunnel login
    TUNNEL_ID=$(cloudflared tunnel create huevohosting | grep -oE "[a-f0-9-]{36}")

    echo -e "${YELLOW}Configurar DNS CNAME para tu dominio en Cloudflare...${RESET}"
    cloudflared tunnel route dns "$TUNNEL_ID" "$DOMAIN"

    cat <<EOF > "$CF_DIR/config.yml"
tunnel: $TUNNEL_ID
credentials-file: $CF_DIR/$TUNNEL_ID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:8080
  - service: http_status:404
EOF

    echo -e "${GREEN}Configuración terminada.${RESET}"
    log "Dominio configurado: $DOMAIN"

    sleep 2
}

start_hosting() {
    clear
    banner

    echo -e "${GREEN}Ingresa la carpeta del servidor (ej: /sdcard/miweb):${RESET}"
    read FOLDER

    echo -e "${GREEN}Ingresa el puerto local (ej: 8080):${RESET}"
    read PORT

    echo -e "${CYAN}Iniciando servidor local en puerto $PORT...${RESET}"
    cd "$FOLDER"
    python3 -m http.server "$PORT" &

    log "Servidor iniciado en carpeta $FOLDER puerto $PORT"

    echo -e "${GREEN}Iniciando túnel Cloudflare...${RESET}"
    cloudflared tunnel run huevohosting &

    log "Túnel iniciado"

    echo -e "${YELLOW}=============================="
    echo -e "   Hosting activo en:"
    echo -e "   https://$DOMAIN"
    echo -e "==============================${RESET}"

    echo -e "${GREEN}Presiona CTRL+C para detener...${RESET}"
    wait
}

enable_autostart() {
    mkdir -p "$CF_DIR"

    cat <<EOF > "$SERVICE_FILE"
#!/data/data/com.termux/files/usr/bin/sh
cloudflared tunnel run huevohosting
EOF

    chmod +x "$SERVICE_FILE"
    termux-services enable huevohosting.service

    log "Servicio habilitado"
    echo -e "${GREEN}Autostart habilitado.${RESET}"
}

disable_autostart() {
    termux-services disable huevohosting.service
    log "Servicio deshabilitado"
    echo -e "${RED}Autostart desactivado.${RESET}"
}

menu() {
    while true; do
        clear
        banner
        echo -e "${CYAN}"
        echo "1) Instalar Cloudflared"
        echo "2) Configurar dominio"
        echo "3) Iniciar hosting"
        echo "4) Habilitar auto-inicio"
        echo "5) Deshabilitar auto-inicio"
        echo "6) Ver logs"
        echo "0) Salir"
        echo -e "${RESET}"

        read -p "Elige opción: " OPTION

        case $OPTION in
            1) install_cloudflared ;;
            2) setup_domain ;;
            3) start_hosting ;;
            4) enable_autostart ;;
            5) disable_autostart ;;
            6) cat "$LOG_FILE" ;;
            0) exit;;
            *) echo -e "${RED}Opción inválida${RESET}"; sleep 1;;
        esac
    done
}

menu
