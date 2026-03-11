#!/bin/bash

# ==============================================================================
# JEHAD BEAST - OPTIMIZER & AUTO-HEALING MODULE
# ==============================================================================

# 1. BBR & KERNEL TUNING (Firewoods Standard)
enable_bbr_tuning() {
    echo "Applying Advanced Kernel Tuning & BBR..."
    cat > /etc/sysctl.d/99-beast-opt.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384
net.core.netdev_max_backlog=65536
net.core.somaxconn=16384
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=60
net.ipv4.tcp_keepalive_intvl=10
net.ipv4.tcp_keepalive_probes=6
EOF
    sysctl -p /etc/sysctl.d/99-beast-opt.conf >/dev/null 2>&1
}

# 2. ZRAM CONFIGURATION (Support 200+ Users)
setup_zram() {
    echo "Optimizing Memory with ZRAM..."
    if ! command -v zramctl >/dev/null; then
        apt-get install -y zram-tools -qq
    fi
    modprobe zram
    zramctl --find --size 1G --algorithm zstd
    mkswap /dev/zram0
    swapon /dev/zram0 -p 100
}

# 3. BADVPN-UDPGW INSTALLATION
setup_badvpn() {
    echo "Installing BadVPN-UDPGW for Gaming/VoIP..."
    wget -qO /usr/local/bin/badvpn-udpgw "https://github.com/ambrop72/badvpn/releases/download/1.999.130/badvpn-linux-x86_64" || \
    wget -qO /usr/local/bin/badvpn-udpgw "https://raw.githubusercontent.com/OXY-VPN/OXY-VPN/main/badvpn-udpgw"
    chmod +x /usr/local/bin/badvpn-udpgw
    
    cat > /etc/systemd/system/badvpn.service <<EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable badvpn && systemctl start badvpn
}

# 4. AUTO-HEALING WATCHDOG (Port 53 Monitor)
setup_watchdog() {
    echo "Deploying Auto-Healing Watchdog..."
    cat > /usr/local/bin/beast-watchdog <<EOF
#!/bin/bash
while true; do
    if ! ss -ulpn | grep -q ":53 "; then
        echo "[$(date)] Port 53 down! Restarting DNSTT..." >> /var/log/beast_watchdog.log
        systemctl restart dnstt
    fi
    sleep 10
done
EOF
    chmod +x /usr/local/bin/beast-watchdog
    cat > /etc/systemd/system/beast-watchdog.service <<EOF
[Unit]
Description=Jehad Beast Auto-Healing Watchdog
After=dnstt.service

[Service]
ExecStart=/usr/local/bin/beast-watchdog
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable beast-watchdog && systemctl start beast-watchdog
}

# Run All Optimizations
run_all_optimizations() {
    enable_bbr_tuning
    setup_zram
    setup_badvpn
    setup_watchdog
}
