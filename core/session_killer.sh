#!/bin/bash

# ==============================================================================
# JEHAD BEAST - MASS SESSION KILLER & GLOBAL PURGE (CYBER LOGIC)
# ==============================================================================

# --- [ COLORS ] ---
C_RED=$'\033[38;5;196m'
C_GREEN=$'\033[38;5;46m'
C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'
C_RESET=$'\033[0m'

# --- [ GLOBAL PURGE FUNCTION ] ---
mass_session_kill() {
    echo -e "${C_RED}🔥 Starting Global Purge (Mass Session Killing)...${C_RESET}"
    
    # 1. Kill Tunneling Services
    local services=("dnstt-server" "stunnel4" "haproxy" "badvpn-udpgw" "ssh-tunnel")
    for svc in "${services[@]}"; do
        if pgrep -x "$svc" >/dev/null; then
            echo -e "${C_YELLOW}🛑 Killing $svc sessions...${C_RESET}"
            killall -9 "$svc" 2>/dev/null
            systemctl stop "$svc" 2>/dev/null
        fi
    done

    # 2. Kill Expired or Ghost SSH Sessions
    echo -e "${C_BLUE}👤 Cleaning ghost SSH sessions...${C_RESET}"
    ps aux | grep -i "sshd: [a-z0-9]" | grep -v grep | awk '{print $2}' | xargs -r kill -9 2>/dev/null

    # 3. Port Cleanup (Force Free 53, 444, 7300)
    local ports=(53 444 7300)
    for port in "${ports[@]}"; do
        local pid=$(lsof -t -i:$port)
        if [ -n "$pid" ]; then
            echo -e "${C_RED}⚡ Force freeing port $port (PID: $pid)...${C_RESET}"
            kill -9 $pid 2>/dev/null
        fi
    done

    echo -e "${C_GREEN}✅ System Purged & Sessions Killed. Environment is CLEAN.${C_RESET}"
}

# --- [ AUTO-KILL EXPIRED USERS ] ---
auto_kill_expired() {
    echo -e "${C_BLUE}🕒 Checking for expired user sessions...${C_RESET}"
    local current_ts=$(date +%s)
    if [ -f "/etc/jehad/users.db" ]; then
        while IFS=: read -r user pass expiry limit; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
                local expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
                if [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]]; then
                    echo -e "${C_RED}💀 Killing expired user session: $user${C_RESET}"
                    killall -u "$user" -9 2>/dev/null
                fi
            fi
        done < "/etc/jehad/users.db"
    fi
}
