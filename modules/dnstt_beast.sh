#!/bin/bash

# ==============================================================================
# 🚀 JEHAD BEAST - SUPERCHARGED DNSTT (SLOWDNS) ULTIMATE MODULE v6.0
# ==============================================================================
# This is a high-performance, autonomous, and hardened implementation of DNSTT.
# Designed for maximum stability, anti-freeze, and extreme user concurrency.
# ==============================================================================

# --- [ GLOBAL CONFIGURATION ] ---
CF_Token="qnN2p02BHhqOulA9xugCaAi33ZQr_GSRAUL0uloS"
CF_ZoneID="7917ca1fa4bf3efa766230e55b820e8a"
CF_API_URL="https://api.cloudflare.com/client/v4"

# --- [ PATHS & DIRECTORIES ] ---
BASE_DIR="/etc/jehad"
DNSTT_DIR="$BASE_DIR/dnstt"
LOG_DIR="$BASE_DIR/logs"
BIN_DIR="/usr/local/bin"
DNSTT_BINARY="$BIN_DIR/dnstt-server"
DNSTT_KEYS_DIR="$DNSTT_DIR/keys"
DNSTT_CONFIG="$DNSTT_DIR/dnstt.conf"
DNSTT_SERVICE="/etc/systemd/system/dnstt.service"
LOG_FILE="$LOG_DIR/dnstt_beast.log"

# --- [ COLORS & UI ] ---
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_RED=$'\033[38;5;196m'
C_GREEN=$'\033[38;5;46m'
C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'
C_PURPLE=$'\033[38;5;135m'
C_CYAN=$'\033[38;5;51m'
C_WHITE=$'\033[38;5;255m'

# --- [ LOGGING SYSTEM ] ---
log_msg() {
    local type=$1
    local msg=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$type] $msg" >> "$LOG_FILE"
}

# --- [ AUTONOMOUS PORT & SERVICE CLEANER ] ---
autonomous_cleanup() {
    log_msg "INFO" "Running autonomous port cleanup for DNSTT..."
    # Silently kill anything on port 53 (UDP)
    local pid_53=$(lsof -t -i:53 -sUDP:LISTEN)
    if [ -n "$pid_53" ]; then
        kill -9 $pid_53 >/dev/null 2>&1
    fi
    # Stop systemd-resolved if active
    systemctl stop systemd-resolved >/dev/null 2>&1
    systemctl disable systemd-resolved >/dev/null 2>&1
}

# --- [ ADVANCED KERNEL TUNING (BEAST LOGIC) ] ---
apply_supercharged_tuning() {
    log_msg "INFO" "Applying Supercharged Kernel Tuning..."
    cat > /etc/sysctl.d/99-supercharged-dnstt.conf <<EOF
# Extreme UDP/TCP Stability for SlowDNS
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.netdev_max_backlog=10000
net.core.somaxconn=4096
net.ipv4.udp_rmem_min=131072
net.ipv4.udp_wmem_min=131072
net.ipv4.ip_forward=1
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_tw_reuse=1
EOF
    sysctl -p /etc/sysctl.d/99-supercharged-dnstt.conf >/dev/null 2>&1
}

# --- [ CLOUDFLARE API CORE FUNCTIONS ] ---
cf_api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    curl -s -X "$method" "$CF_API_URL/zones/$CF_ZoneID/$endpoint" \
         -H "Authorization: Bearer $CF_Token" \
         -H "Content-Type: application/json" \
         ${data:+-d "$data"}
}

upsert_dns_record() {
    local type=$1
    local name=$2
    local content=$3
    local record_id=$(cf_api_call "GET" "dns_records?type=$type&name=$name" "" | jq -r '.result[0].id // empty')
    local payload=$(jq -n --arg t "$type" --arg n "$name" --arg c "$content" '{type: $t, name: $n, content: $c, ttl: 120, proxied: false}')
    if [[ -n "$record_id" ]]; then
        cf_api_call "PUT" "dns_records/$record_id" "$payload" >/dev/null
    else
        cf_api_call "POST" "dns_records" "$payload" >/dev/null
    fi
}

# --- [ MAIN INSTALLATION LOGIC ] ---
install_dnstt_beast() {
    clear
    echo -e "${C_PURPLE}${C_BOLD}===============================================${C_RESET}"
    echo -e "${C_CYAN}   🚀 SUPERCHARGED DNSTT BEAST - v6.0${C_RESET}"
    echo -e "${C_PURPLE}${C_BOLD}===============================================${C_RESET}"

    # Step 1: Autonomous Cleanup
    autonomous_cleanup
    apply_supercharged_tuning

    # Step 2: Binary Prep
    mkdir -p "$DNSTT_DIR" "$LOG_DIR" "$DNSTT_KEYS_DIR"
    local arch=$(uname -m)
    local url="https://dnstt.network/dnstt-server-linux-amd64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && url="https://dnstt.network/dnstt-server-linux-arm64"
    curl -sL "$url" -o "$DNSTT_BINARY" && chmod +x "$DNSTT_BINARY"

    if [[ ! -f "$DNSTT_KEYS_DIR/server.key" ]]; then
        "$DNSTT_BINARY" -gen-key -privkey-file "$DNSTT_KEYS_DIR/server.key" -pubkey-file "$DNSTT_KEYS_DIR/server.pub"
    fi
    local pubkey=$(cat "$DNSTT_KEYS_DIR/server.pub")

    # Step 3: Domain Configuration (Manual/Auto)
    echo -e "\n${C_BLUE}🌐 NS Record (SlowDNS) Configuration:${C_RESET}"
    echo -e "  [1] Auto-generate (Subdomain)"
    echo -e "  [2] Manual Input (Enter your own NS Domain)"
    read -p "👉 Choice [2]: " ns_choice
    ns_choice=${ns_choice:-2}

    local full_ns=""
    if [[ "$ns_choice" == "1" ]]; then
        local domain=$(cf_api_call "GET" "" "" | jq -r '.result.name')
        full_ns="slow-$(head /dev/urandom | tr -dc a-z0-9 | head -c 4).$domain"
        local server_ip=$(curl -s https://ifconfig.me)
        local a_rec="srv-$(head /dev/urandom | tr -dc a-z0-9 | head -c 4).$domain"
        upsert_dns_record "A" "$a_rec" "$server_ip"
        upsert_dns_record "NS" "$full_ns" "$a_rec"
    else
        read -p "👉 Enter your NS Domain: " full_ns
    fi

    # Step 4: MTU & Traffic Shaping
    echo -e "\n${C_BLUE}⚙️ MTU Optimization (Recommended: 512-1100):${C_RESET}"
    read -p "👉 Enter MTU [900]: " mtu
    mtu=${mtu:-900}

    # Step 5: High-Performance Service Deployment
    cat > "$DNSTT_SERVICE" <<EOF
[Unit]
Description=Supercharged DNSTT Beast Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=$DNSTT_BINARY -udp :53 -mtu $mtu -privkey-file $DNSTT_KEYS_DIR/server.key $full_ns 127.0.0.1:22
Restart=always
RestartSec=1
StartLimitInterval=0
LimitNOFILE=1048576
LimitNPROC=16384
CPUAccounting=yes
MemoryAccounting=yes
TasksMax=infinity
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt.service >/dev/null 2>&1
    systemctl start dnstt.service >/dev/null 2>&1

    # Finalize
    cat > "$DNSTT_CONFIG" <<EOF
NS_RECORD="$full_ns"
PUBLIC_KEY="$pubkey"
MTU="$mtu"
EOF

    echo -e "\n${C_GREEN}✅ SUCCESS: SUPERCHARGED DNSTT IS ONLINE!${C_RESET}"
    echo -e "  - NS Domain:  $full_ns"
    echo -e "  - Public Key: $pubkey"
    echo -e "---------------------------------------"
}

uninstall_dnstt_beast() {
    systemctl stop dnstt.service >/dev/null 2>&1
    systemctl disable dnstt.service >/dev/null 2>&1
    rm -f "$DNSTT_SERVICE" "$DNSTT_CONFIG"
    echo -e "${C_GREEN}✅ DNSTT Beast Uninstalled.${C_RESET}"
}

show_dnstt_status() {
    [ ! -f "$DNSTT_CONFIG" ] && { echo -e "${C_RED}❌ Not installed.${C_RESET}"; return; }
    source "$DNSTT_CONFIG"
    echo -e "${C_CYAN}Status: $(systemctl is-active dnstt.service)${C_RESET}"
    echo -e "${C_CYAN}NS: $NS_RECORD${C_RESET}"
    echo -e "${C_CYAN}Key: $PUBLIC_KEY${C_RESET}"
}
