#!/bin/bash

# ==============================================================================
# JEHAD BEAST - DNSTT (SLOWDNS) CORE MODULE
# ==============================================================================
# Advanced DNSTT implementation with high-performance tuning, 
# connection stability, and stealth configuration.
# ==============================================================================

# --- [ PATHS & CONFIG ] ---
DNSTT_BINARY="/usr/local/bin/dnstt-server"
DNSTT_KEYS_DIR="/etc/jehad/dnstt"
DNSTT_CONFIG="/etc/jehad/dnstt_info.conf"
DNSTT_SERVICE="/etc/systemd/system/dnstt.service"

# --- [ SYSTEM HARDENING FOR DNSTT ] ---
harden_dns_port() {
    log_info "Hardening DNS port 53..."
    
    # Disable systemd-resolved to free port 53
    if systemctl is-active --quiet systemd-resolved; then
        systemctl stop systemd-resolved >/dev/null 2>&1
        systemctl disable systemd-resolved >/dev/null 2>&1
    fi
    
    # Reconfigure resolv.conf with immutability
    [ -f /etc/resolv.conf ] && chattr -i /etc/resolv.conf 2>/dev/null
    rm -f /etc/resolv.conf
    cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
options edns0 trust-ad timeout:2 attempts:3
EOF
    chattr +i /etc/resolv.conf 2>/dev/null
    
    # Kernel tuning for UDP/TCP stability (Like thefirewoods)
    log_info "Applying kernel network optimizations..."
    sysctl -w net.core.rmem_max=16777216 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=16777216 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=16384 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=16384 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
}

# --- [ DNSTT BINARY & KEYS ] ---
setup_dnstt_assets() {
    log_info "Setting up DNSTT binary and keys..."
    
    local arch=$(uname -m)
    local url=""
    case $arch in
        x86_64) url="https://dnstt.network/dnstt-server-linux-amd64" ;;
        aarch64|arm64) url="https://dnstt.network/dnstt-server-linux-arm64" ;;
        *) log_error "Unsupported architecture: $arch"; return 1 ;;
    esac
    
    curl -sL "$url" -o "$DNSTT_BINARY"
    chmod +x "$DNSTT_BINARY"
    
    mkdir -p "$DNSTT_KEYS_DIR"
    if [[ ! -f "$DNSTT_KEYS_DIR/server.key" ]]; then
        "$DNSTT_BINARY" -gen-key -privkey-file "$DNSTT_KEYS_DIR/server.key" -pubkey-file "$DNSTT_KEYS_DIR/server.pub"
    fi
}

# --- [ DNSTT SERVICE DEPLOYMENT ] ---
deploy_dnstt_service() {
    local ns_domain=$1
    local target_host=${2:-"127.0.0.1:22"}
    local mtu=${3:-512}
    
    log_info "Deploying DNSTT service for $ns_domain..."
    
    cat > "$DNSTT_SERVICE" <<EOF
[Unit]
Description=Jehad Beast DNSTT (SlowDNS) Server
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/jehad
ExecStart=$DNSTT_BINARY -udp :53 -mtu $mtu -privkey-file $DNSTT_KEYS_DIR/server.key $ns_domain $target_host
Restart=always
RestartSec=3
StartLimitInterval=0
LimitNOFILE=1048576
LimitNPROC=512
StandardOutput=append:/var/log/jehad_dnstt.log
StandardError=append:/var/log/jehad_dnstt.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt.service >/dev/null 2>&1
    systemctl start dnstt.service >/dev/null 2>&1
}

# --- [ LOGGING HELPERS ] ---
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "/home/ubuntu/jehad_beast/ov/logs/dnstt.log"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "/home/ubuntu/jehad_beast/ov/logs/dnstt.log"; }
