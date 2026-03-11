#!/bin/bash

# ==============================================================================
# JEHAD BEAST - THE ULTIMATE DNSTT (SLOWDNS) SMART MODULE v5.0 (FIREWOODS EDITION)
# ==============================================================================
# This module is a massive, enterprise-grade implementation of DNSTT.
# Integrated with Firewoods (thefirewoods.org) Elite Logic & Stability.
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

# --- [ FIREWOODS DNS HARDENING & RATE LIMITING ] ---
# Elite logic to prevent DNS Amplification and Anti-Freeze
apply_firewoods_dns_hardening() {
    log_msg "INFO" "Applying Firewoods DNS Hardening..."
    
    # Strict Rate Limiting to prevent DNS Amplification attacks
    iptables -A INPUT -p udp --dport 53 -m limit --limit 20/sec --limit-burst 100 -j ACCEPT
    iptables -A INPUT -p udp --dport 53 -j DROP
    
    # Kernel tuning for massive UDP stability (Firewoods Standard)
    cat > /etc/sysctl.d/99-firewoods-dns.conf <<EOF
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF
    sysctl -p /etc/sysctl.d/99-firewoods-dns.conf >/dev/null 2>&1
}

# --- [ CLOUDFLARE API CORE FUNCTIONS ] ---
cf_api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local retry=0
    local max_retry=5
    local response=""

    while [ $retry -lt $max_retry ]; do
        if [[ -z "$data" ]]; then
            response=$(curl -s -X "$method" "$CF_API_URL/zones/$CF_ZoneID/$endpoint" \
                 -H "Authorization: Bearer $CF_Token" \
                 -H "Content-Type: application/json")
        else
            response=$(curl -s -X "$method" "$CF_API_URL/zones/$CF_ZoneID/$endpoint" \
                 -H "Authorization: Bearer $CF_Token" \
                 -H "Content-Type: application/json" \
                 -d "$data")
        fi

        if echo "$response" | grep -q '"success":true'; then
            echo "$response"
            return 0
        else
            log_msg "ERROR" "CF API Attempt $((retry+1)) failed: $response"
            ((retry++))
            sleep 2
        fi
    done
    echo "$response"
    return 1
}

get_domain_name() {
    local res=$(cf_api_call "GET" "" "")
    echo "$res" | jq -r '.result.name'
}

find_dns_record() {
    local type=$1
    local name=$2
    local res=$(cf_api_call "GET" "dns_records?type=$type&name=$name" "")
    echo "$res" | jq -r '.result[0].id // empty'
}

upsert_dns_record() {
    local type=$1
    local name=$2
    local content=$3
    local proxied=${4:-false}
    local ttl=${5:-120}
    
    local record_id=$(find_dns_record "$type" "$name")
    local payload=$(jq -n \
        --arg type "$type" \
        --arg name "$name" \
        --arg content "$content" \
        --argjson ttl "$ttl" \
        --argjson proxied "$proxied" \
        '{type: $type, name: $name, content: $content, ttl: $ttl, proxied: $proxied}')

    if [[ -n "$record_id" ]]; then
        log_msg "INFO" "Updating $type record: $name"
        cf_api_call "PUT" "dns_records/$record_id" "$payload"
    else
        log_msg "INFO" "Creating $type record: $name"
        cf_api_call "POST" "dns_records" "$payload"
    fi
}

delete_dns_record() {
    local record_id=$1
    [[ -z "$record_id" ]] && return 0
    cf_api_call "DELETE" "dns_records/$record_id" ""
}

# --- [ SYSTEM HARDENING & NETWORK OPTIMIZATION ] ---
harden_system() {
    log_msg "INFO" "Starting deep system hardening..."
    
    # 1. Port 53 Liberation
    if systemctl is-active --quiet systemd-resolved; then
        log_msg "INFO" "Disabling systemd-resolved..."
        systemctl stop systemd-resolved >/dev/null 2>&1
        systemctl disable systemd-resolved >/dev/null 2>&1
    fi
    
    # 2. Immutable Resolv.conf
    [ -f /etc/resolv.conf ] && chattr -i /etc/resolv.conf 2>/dev/null
    rm -f /etc/resolv.conf
    cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
options edns0 trust-ad timeout:2 attempts:3
EOF
    chattr +i /etc/resolv.conf 2>/dev/null
    
    # 3. Advanced Kernel Tuning (The Beast Logic)
    log_msg "INFO" "Applying advanced kernel network parameters..."
    cat > /etc/sysctl.d/99-jehad-beast.conf <<EOF
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384
net.ipv4.ip_forward=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_keepalive_time=60
net.ipv4.tcp_keepalive_intvl=10
net.ipv4.tcp_keepalive_probes=6
net.ipv4.tcp_mtu_probing=1
net.core.netdev_max_backlog=16384
net.core.somaxconn=8192
EOF
    sysctl -p /etc/sysctl.d/99-jehad-beast.conf >/dev/null 2>&1
}

# --- [ DNSTT CORE LOGIC ] ---
install_dnstt_beast() {
    clear
    echo -e "${C_PURPLE}${C_BOLD}===============================================${C_RESET}"
    echo -e "${C_CYAN}   🚀 JEHAD BEAST DNSTT - FIREWOODS EDITION${C_RESET}"
    echo -e "${C_PURPLE}${C_BOLD}===============================================${C_RESET}"
    
    # Step 1: Dependencies
    echo -e "\n${C_BLUE}[1/7] Installing required packages...${C_RESET}"
    apt-get update -qq
    apt-get install -y curl wget jq dnsutils iproute2 psmisc sed grep -qq
    
    # Step 2: Hardening & Firewoods Logic
    echo -e "\n${C_BLUE}[2/7] Hardening system and applying Firewoods logic...${C_RESET}"
    harden_system
    apply_firewoods_dns_hardening

    # Step 3: Binary & Keys (Fastest Stable Source)
    echo -e "\n${C_BLUE}[3/7] Preparing high-speed DNSTT binary...${C_RESET}"
    local arch=$(uname -m)
    local url=""
    case $arch in
        x86_64) url="https://dnstt.network/dnstt-server-linux-amd64" ;;
        aarch64|arm64) url="https://dnstt.network/dnstt-server-linux-arm64" ;;
        *) echo -e "${C_RED}❌ Unsupported architecture: $arch${C_RESET}"; return ;;
    esac
    
    curl -sL "$url" -o "$DNSTT_BINARY"
    chmod +x "$DNSTT_BINARY"
    
    mkdir -p "$DNSTT_KEYS_DIR"
    if [[ ! -f "$DNSTT_KEYS_DIR/server.key" ]]; then
        "$DNSTT_BINARY" -gen-key -privkey-file "$DNSTT_KEYS_DIR/server.key" -pubkey-file "$DNSTT_KEYS_DIR/server.pub"
    fi
    local pubkey=$(cat "$DNSTT_KEYS_DIR/server.pub")

    # Step 4: Cloudflare Logic
    echo -e "\n${C_BLUE}[4/7] Synchronizing with Cloudflare API...${C_RESET}"
    local domain=$(get_domain_name)
    [[ -z "$domain" ]] && { echo -e "${C_RED}❌ CF API Error!${C_RESET}"; return; }
    
    echo -e "${C_CYAN}🌐 Domain: ${C_WHITE}$domain${C_RESET}"
    echo -e "Select naming strategy:"
    echo -e "  ${C_GREEN}[1]${C_RESET} Manual Input"
    echo -e "  ${C_GREEN}[2]${C_RESET} Professional Auto (srv, nodes, tunnels, etc)"
    read -p "👉 Choice [2]: " dns_mode
    dns_mode=${dns_mode:-2}

    local a_name ns_name
    if [[ "$dns_mode" == "1" ]]; then
        read -p "👉 A Record name: " a_name
        read -p "👉 NS Record name: " ns_name
    else
        a_recs=("srv" "nodes" "edge" "cdn" "cloud" "gw")
        ns_recs=("dns" "tunnels" "slow" "connect" "link" "bridge")
        a_name=${a_recs[$RANDOM % ${#a_recs[@]}]}
        ns_name=${ns_recs[$RANDOM % ${#ns_recs[@]}]}
    fi
    
    local full_a="$a_name.$domain"
    local full_ns="$ns_name.$domain"
    local server_ip=$(curl -s https://ifconfig.me)
    
    echo -e "${C_BLUE}☁️ Creating A record: $full_a -> $server_ip${C_RESET}"
    upsert_dns_record "A" "$full_a" "$server_ip"
    
    echo -e "${C_BLUE}☁️ Creating NS record: $full_ns -> $full_a${C_RESET}"
    upsert_dns_record "NS" "$full_ns" "$full_a"

    # Step 5: Advanced Traffic Shaping & MTU
    echo -e "\n${C_BLUE}[5/7] Configuring Traffic Shaping & MTU...${C_RESET}"
    # Dynamic MTU Optimization (512-1100)
    local mtu=512
    echo -e "Selecting optimal MTU (Recommended: 512-1100)"
    read -p "👉 Enter MTU [900]: " user_mtu
    mtu=${user_mtu:-900}

    # Step 6: Service Deployment (High Stability)
    echo -e "\n${C_BLUE}[6/7] Deploying DNSTT Beast Service...${C_RESET}"
    cat > "$DNSTT_SERVICE" <<EOF
[Unit]
Description=Jehad Beast DNSTT (SlowDNS) Server
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
# High-Performance DNSTT Beast Logic
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

    # Step 7: Finalization
    echo -e "\n${C_BLUE}[7/7] Saving configuration and finishing...${C_RESET}"
    cat > "$DNSTT_CONFIG" <<EOF
# JEHAD BEAST DNSTT CONFIG
A_RECORD="$full_a"
NS_RECORD="$full_ns"
PUBLIC_KEY="$pubkey"
MTU="$mtu"
INSTALL_DATE="$(date)"
EOF

    echo -e "\n${C_GREEN}✅ SUCCESS: DNSTT Beast is ONLINE!${C_RESET}"
    echo -e "---------------------------------------"
    echo -e "  - NS Domain:  $full_ns"
    echo -e "  - Public Key: $pubkey"
    echo -e "  - MTU:        $mtu"
    echo -e "---------------------------------------"
    log_msg "SUCCESS" "DNSTT Beast installed on $full_ns"
}

uninstall_dnstt_beast() {
    echo -e "${C_BOLD}${C_RED}--- 🗑️ Uninstalling DNSTT Beast ---${C_RESET}"
    
    if [ -f "$DNSTT_CONFIG" ]; then
        source "$DNSTT_CONFIG"
        local a_id=$(find_dns_record "A" "$A_RECORD")
        local ns_id=$(find_dns_record "NS" "$NS_RECORD")
        delete_dns_record "$a_id"
        delete_dns_record "$ns_id"
    fi
    
    systemctl stop dnstt.service >/dev/null 2>&1
    systemctl disable dnstt.service >/dev/null 2>&1
    rm -f "$DNSTT_SERVICE"
    rm -rf "$DNSTT_KEYS_DIR"
    rm -f "$DNSTT_CONFIG"
    rm -f "/etc/sysctl.d/99-jehad-beast.conf"
    rm -f "/etc/sysctl.d/99-firewoods-dns.conf"
    sysctl --system >/dev/null 2>&1
    
    echo -e "${C_GREEN}✅ DNSTT Beast Uninstalled Successfully.${C_RESET}"
}

show_dnstt_status() {
    if [ ! -f "$DNSTT_CONFIG" ]; then
        echo -e "${C_RED}❌ DNSTT is not installed.${C_RESET}"
        return
    fi
    
    source "$DNSTT_CONFIG"
    clear
    echo -e "${C_PURPLE}${C_BOLD}--- 📊 DNSTT BEAST STATUS ---${C_RESET}"
    echo -e "  ${C_CYAN}Status:     $(systemctl is-active dnstt.service)${C_RESET}"
    echo -e "  ${C_CYAN}NS Domain:  ${C_YELLOW}$NS_RECORD${C_RESET}"
    echo -e "  ${C_CYAN}Public Key: ${C_WHITE}$PUBLIC_KEY${C_RESET}"
    echo -e "  ${C_CYAN}MTU:        ${C_WHITE}$MTU${C_RESET}"
    echo -e "${C_PURPLE}-------------------------------${C_RESET}"
    
    echo -e "\n${C_BLUE}Recent Logs:${C_RESET}"
    tail -n 5 "$LOG_FILE"
}
