#!/bin/bash

# ==============================================================================
# JEHAD BEAST - ADVANCED SSL TUNNEL MODULE (PORT 444) - FORCE EDITION
# ==============================================================================

# --- [ CONFIG & PATHS ] ---
BASE_DIR="/etc/jehad"
LOG_DIR="$BASE_DIR/logs"
SSL_CONF="/etc/stunnel/stunnel.conf"
SSL_CERT="/etc/stunnel/stunnel.pem"
SSL_PORT=444
STUNNEL_SERVICE="stunnel4"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# --- [ COLORS ] ---
C_RED=$'\033[38;5;196m'
C_GREEN=$'\033[38;5;46m'
C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'
C_CYAN=$'\033[38;5;51m'
C_RESET=$'\033[0m'

# --- [ FORCE PORT FREE LOGIC ] ---
check_and_free_port() {
    local port=$1
    echo -e "${C_CYAN}🔎 Checking if port $port is available...${C_RESET}"
    
    local pid=$(lsof -t -i:$port)
    if [ -n "$pid" ]; then
        for p in $pid; do
            local process_name=$(ps -p $p -o comm=)
            echo -e "${C_YELLOW}⚠️ Warning: Port $port is in use by '$process_name' (PID: $p).${C_RESET}"
            read -p "👉 Force stop this process and its services? (y/n): " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                echo -e "${C_BLUE}🛑 Attempting to stop services related to $process_name...${C_RESET}"
                systemctl stop "$process_name" >/dev/null 2>&1
                kill -9 "$p" >/dev/null 2>&1
                sleep 2
                
                if ! lsof -i:$port >/dev/null; then
                    echo -e "${C_GREEN}✅ Port $port has been successfully freed.${C_RESET}"
                else
                    echo -e "${C_RED}❌ Failed to free port $port. Manual intervention required.${C_RESET}"
                    return 1
                fi
            else
                echo -e "${C_RED}❌ Port $port is still in use. Installation aborted.${C_RESET}"
                return 1
            fi
        done
    fi
    return 0
}

# --- [ SSL CERTIFICATE GENERATOR ] ---
generate_ssl_cert() {
    if [ -f "$SSL_CERT" ]; then
        read -p "SSL certificate already exists. Overwrite? (y/n): " overwrite
        [[ ! "$overwrite" =~ ^[Yy]$ ]] && return 0
    fi

    echo -e "${C_BLUE}🔐 Generating SSL Certificate...${C_RESET}"
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=US/ST=Cyber/L=Beast/O=Jehad/CN=beast.vpn" \
        -keyout "$SSL_CERT" -out "$SSL_CERT" >/dev/null 2>&1
    echo -e "${C_GREEN}✅ SSL Certificate generated successfully.${C_RESET}"
}

# --- [ CLOUDFLARE DOMAIN INTEGRATION ] ---
setup_ssl_domain() {
    echo -e "\n${C_CYAN}🌐 SSL Domain Configuration:${C_RESET}"
    echo -e "  [1] Auto-generate via Cloudflare API (Subdomain)"
    echo -e "  [2] Manual Input (Enter your own domain)"
    read -p "👉 Choice [1]: " domain_choice
    domain_choice=${domain_choice:-1}

    local ssl_domain=""
    if [[ "$domain_choice" == "1" ]]; then
        if [ -f "$BASE_DIR/modules/dnstt_beast.sh" ]; then
            source "$BASE_DIR/modules/dnstt_beast.sh"
            local root_domain=$(get_domain_name)
            if [[ -n "$root_domain" && "$root_domain" != "null" ]]; then
                ssl_domain="ssl-$(head /dev/urandom | tr -dc a-z0-9 | head -c 4).$root_domain"
                local server_ip=$(curl -s https://ifconfig.me)
                echo -e "${C_BLUE}☁️ Creating A record for SSL: $ssl_domain -> $server_ip${C_RESET}"
                upsert_dns_record "A" "$ssl_domain" "$server_ip"
            else
                echo -e "${C_RED}❌ Cloudflare API Error or Domain not found.${C_RESET}"
                read -p "👉 Enter SSL Domain manually: " ssl_domain
            fi
        else
            read -p "👉 Enter SSL Domain manually: " ssl_domain
        fi
    else
        read -p "👉 Enter your SSL Domain: " ssl_domain
    fi
    echo "$ssl_domain" > "$BASE_DIR/ssl_domain.info"
    echo -e "${C_GREEN}✅ SSL Domain set to: $ssl_domain${C_RESET}"
}

# --- [ INSTALL SSL TUNNEL ] ---
install_ssl_tunnel() {
    clear
    echo -e "${C_CYAN}${C_BOLD}===============================================${C_RESET}"
    echo -e "    🔒 INSTALL SSL TUNNEL (PORT 444) - BEAST EDITION"
    echo -e "${C_CYAN}${C_BOLD}===============================================${C_RESET}"

    # 1. Check Port
    check_and_free_port $SSL_PORT || return 1

    # 2. Install Stunnel
    echo -e "\n${C_BLUE}📦 Installing Stunnel...${C_RESET}"
    apt-get update -qq && apt-get install -y stunnel4 -qq

    # 3. Generate Certificate
    generate_ssl_cert

    # 4. Domain Setup
    setup_ssl_domain

    # 5. Configure Stunnel
    echo -e "\n${C_BLUE}⚙️ Configuring Stunnel for Port 444...${C_RESET}"
    cat > "$SSL_CONF" <<EOF
pid = /var/run/stunnel4.pid
cert = $SSL_CERT
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssl-tunnel]
accept = $SSL_PORT
connect = 127.0.0.1:22
EOF

    # Enable stunnel
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4 2>/dev/null

    # 6. Restart Service
    systemctl restart $STUNNEL_SERVICE
    systemctl enable $STUNNEL_SERVICE

    echo -e "\n${C_GREEN}✅ SSL TUNNEL INSTALLED SUCCESSFULLY!${C_RESET}"
    echo -e "---------------------------------------"
    echo -e "  - Port:       $SSL_PORT"
    echo -e "  - Domain:     $(cat $BASE_DIR/ssl_domain.info 2>/dev/null || echo "N/A")"
    echo -e "  - Protocol:   SSL/TLS (Stunnel)"
    echo -e "---------------------------------------"
}

# --- [ UNINSTALL SSL TUNNEL ] ---
uninstall_ssl_tunnel() {
    echo -e "${C_RED}🗑️ Uninstalling SSL Tunnel...${C_RESET}"
    systemctl stop $STUNNEL_SERVICE >/dev/null 2>&1
    systemctl disable $STUNNEL_SERVICE >/dev/null 2>&1
    apt-get remove --purge -y stunnel4 >/dev/null 2>&1
    rm -f "$SSL_CONF" "$SSL_CERT"
    rm -f "$BASE_DIR/ssl_domain.info"
    echo -e "${C_GREEN}✅ SSL Tunnel uninstalled.${C_RESET}"
}
