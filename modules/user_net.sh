#!/bin/bash

# ==============================================================================
# JEHAD BEAST - USER & NETWORK MANAGEMENT MODULE
# ==============================================================================
# Advanced user creation, connection limiting, and network monitoring.
# ==============================================================================

BASE_DIR="/etc/jehad"
LOG_DIR="$BASE_DIR/logs"
DB_FILE="$BASE_DIR/users.db"
USER_LOG="$LOG_DIR/user_net.log"
LIMITER_SCRIPT="/usr/local/bin/jehad-limiter.sh"
LIMITER_SERVICE="/etc/systemd/system/jehad-limiter.service"

# Ensure directories exist
mkdir -p "$LOG_DIR"
touch "$USER_LOG"

# --- [ USER MANAGEMENT ] ---
add_ssh_user() {
    local user=$1
    local pass=$2
    local days=$3
    local limit=$4
    
    if id "$user" &>/dev/null; then
        log_error "User $user already exists."
        return 1
    fi
    
    local expire_date=$(date -d "+$days days" +%Y-%m-%d)
    useradd -m -s /usr/sbin/nologin "$user"
    echo "$user:$pass" | chpasswd
    echo "$user:$pass:$expire_date:$limit" >> "$DB_FILE"
    log_info "User $user created. Expires: $expire_date, Limit: $limit"
}

remove_ssh_user() {
    local user=$1
    killall -u "$user" -9 &>/dev/null
    userdel -r "$user" &>/dev/null
    sed -i "/^$user:/d" "$DB_FILE"
    log_info "User $user removed."
}

# --- [ CONNECTION LIMITER ] ---
setup_limiter() {
    log_info "Setting up connection limiter..."
    
    cat > "$LIMITER_SCRIPT" << 'EOF'
#!/bin/bash
BASE_DIR="/etc/jehad"
DB_FILE="$BASE_DIR/users.db"
while true; do
    if [[ ! -f "$DB_FILE" ]]; then sleep 30; continue; fi
    current_ts=$(date +%s)
    while IFS=: read -r user pass expiry limit; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        
        # Expiry Check
        if [[ "$expiry" != "Never" && "$expiry" != "" ]]; then
             expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
             if [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]]; then
                if ! passwd -S "$user" | grep -q " L "; then
                    usermod -L "$user" &>/dev/null
                    killall -u "$user" -9 &>/dev/null
                fi
                continue
             fi
        fi
        
        # Connection Limit Check
        online_count=$(pgrep -c -u "$user" sshd)
        if ! [[ "$limit" =~ ^[0-9]+$ ]]; then limit=1; fi
        if [[ "$online_count" -gt "$limit" ]]; then
            if ! passwd -S "$user" | grep -q " L "; then
                usermod -L "$user" &>/dev/null
                killall -u "$user" -9 &>/dev/null
                (sleep 120; usermod -U "$user" &>/dev/null) & 
            else
                killall -u "$user" -9 &>/dev/null
            fi
        fi
    done < "$DB_FILE"
    sleep 25
done
EOF
    chmod +x "$LIMITER_SCRIPT"
    
    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=Jehad Beast User Limiter
After=network.target

[Service]
Type=simple
ExecStart=$LIMITER_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable jehad-limiter >/dev/null 2>&1
    systemctl start jehad-limiter >/dev/null 2>&1
}

# --- [ NETWORK MONITORING ] ---
get_interface() {
    ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1
}

monitor_traffic() {
    local iface=$(get_interface)
    echo -e "Monitoring $iface... (Ctrl+C to stop)"
    local rx1=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    local tx1=$(cat /sys/class/net/$iface/statistics/tx_bytes)
    while true; do
        sleep 1
        local rx2=$(cat /sys/class/net/$iface/statistics/rx_bytes)
        local tx2=$(cat /sys/class/net/$iface/statistics/tx_bytes)
        local rx_kbs=$(((rx2 - rx1) / 1024))
        local tx_kbs=$(((tx2 - tx1) / 1024))
        printf "\r⬇️ %-10s | ⬆️ %-10s" "${rx_kbs} KB/s" "${tx_kbs} KB/s"
        rx1=$rx2; tx1=$tx2
    done
}

# --- [ LOGGING HELPERS ] ---
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$USER_LOG"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$USER_LOG"; }
