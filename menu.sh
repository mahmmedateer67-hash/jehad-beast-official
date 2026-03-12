#!/bin/bash

# ==============================================================================
# JEHAD BEAST - THE ULTIMATE VPS MANAGER v5.5 (CYBER EDITION)
# ==============================================================================
# Integrated with Mass Session Killer, SSL Tunneling, and DNSTT Beast.
# ==============================================================================

# --- [ GLOBAL PATHS ] ---
BASE_DIR="/etc/jehad"
CORE_DIR="$BASE_DIR/core"
MOD_DIR="$BASE_DIR/modules"
LOG_DIR="$BASE_DIR/logs"

# --- [ COLORS ] ---
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_RED=$'\033[38;5;196m'
C_GREEN=$'\033[38;5;46m'
C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'
C_PURPLE=$'\033[38;5;135m'
C_CYAN=$'\033[38;5;51m'
C_WHITE=$'\033[38;5;255m'
C_GRAY=$'\033[38;5;245m'

# --- [ LOAD MODULES ] ---
if [ -d "/etc/jehad/modules" ]; then
    source "/etc/jehad/modules/dnstt_beast.sh"
    source "/etc/jehad/modules/user_net.sh"
    source "/etc/jehad/modules/ssl_tunnel.sh"
    source "/etc/jehad/core/session_killer.sh"
else
    source "./modules/dnstt_beast.sh"
    source "./modules/user_net.sh"
    source "./modules/ssl_tunnel.sh"
    source "./core/session_killer.sh"
fi

# --- [ UI COMPONENTS ] ---
show_banner() {
    clear
    echo -e "${C_PURPLE}${C_BOLD}"
    echo "   ██╗███████╗██╗  ██╗ █████╗ ██████╗ "
    echo "   ██║██╔════╝██║  ██║██╔══██╗██╔══██╗"
    echo "   ██║█████╗  ███████║███████║██║  ██║"
    echo "██   ██║██╔══╝  ██╔══██║██╔══██║██║  ██║"
    echo "╚█████╔╝███████╗██║  ██║██║  ██║██████╔╝"
    echo " ╚════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ "
    echo -e "          JEHAD BEAST v5.5 (CYBER EDITION)${C_RESET}"
    echo -e "${C_GRAY}---------------------------------------${C_RESET}"
}

press_enter() {
    echo -e "\n${C_GRAY}Press [Enter] to return to menu...${C_RESET}"
    read
}

# --- [ MAIN MENU ] ---
while true; do
    show_banner
    echo -e "  ${C_CYAN}[1]${C_RESET} Create SSH User"
    echo -e "  ${C_CYAN}[2]${C_RESET} Delete SSH User"
    echo -e "  ${C_GRAY}---------------------------------------${C_RESET}"
    echo -e "  ${C_CYAN}[3]${C_RESET} Install DNSTT (Beast Edition)"
    echo -e "  ${C_CYAN}[4]${C_RESET} Uninstall DNSTT (Beast Edition)"
    echo -e "  ${C_CYAN}[5]${C_RESET} View DNSTT Status"
    echo -e "  ${C_GRAY}---------------------------------------${C_RESET}"
    echo -e "  ${C_CYAN}[6]${C_RESET} 🔒 Install SSL Tunnel (Port 444)"
    echo -e "  ${C_CYAN}[7]${C_RESET} 🗑️ Uninstall SSL Tunnel"
    echo -e "  ${C_GRAY}---------------------------------------${C_RESET}"
    echo -e "  ${C_RED}${C_BOLD}[8] 🔥 Mass Session Killer (Global Purge)${C_RESET}"
    echo -e "  ${C_CYAN}[9]${C_RESET} 📊 Live Traffic Monitor"
    echo -e "  ${C_CYAN}[0]${C_RESET} Exit"
    echo
    read -p "👉 Choice: " choice
    case $choice in
        1) 
            read -p "User: " u; read -p "Pass: " p; read -p "Days: " d; read -p "Limit: " l
            add_ssh_user "$u" "$p" "$d" "$l"
            press_enter ;;
        2) 
            read -p "User to delete: " u
            remove_ssh_user "$u"
            press_enter ;;
        3) install_dnstt_beast; press_enter ;;
        4) uninstall_dnstt_beast; press_enter ;;
        5) show_dnstt_status; press_enter ;;
        6) install_ssl_tunnel; press_enter ;;
        7) uninstall_ssl_tunnel; press_enter ;;
        8) mass_session_kill; press_enter ;;
        9) monitor_traffic ;;
        0) exit 0 ;;
        *) echo -e "${C_RED}Invalid choice!${C_RESET}"; sleep 1 ;;
    esac
done
