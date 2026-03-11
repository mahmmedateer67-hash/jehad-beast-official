#!/bin/bash
set -e

# ==============================================================================
# JEHAD BEAST - THE ULTIMATE VPS MANAGER INSTALLER
# ==============================================================================

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

echo "Installing Jehad Beast v3.0..."

# 1. Install Dependencies
apt-get update -qq
apt-get install -y curl wget jq dnsutils iproute2 psmisc sed grep -qq

# 2. Create Directory Structure
mkdir -p /etc/jehad/{core,modules,utils,config,bin,logs,security,dnstt}

# 3. Copy Files
cp -r core/* /etc/jehad/core/
cp -r modules/* /etc/jehad/modules/
apt-get install -y stunnel4 lsof openssl -qq
cp menu.sh /usr/local/bin/jehad
chmod +x /usr/local/bin/jehad
chmod +x /etc/jehad/core/*.sh
chmod +x /etc/jehad/modules/*.sh

# 4. Advanced Optimizations (Firewoods Beast Logic)
cp core/optimizer.sh /etc/jehad/core/
chmod +x /etc/jehad/core/optimizer.sh
source /etc/jehad/core/optimizer.sh
run_all_optimizations

# 5. Initial Setup
# Load modules to run setup
source /etc/jehad/modules/user_net.sh
setup_limiter

echo "==============================================="
echo "   🚀 JEHAD BEAST - OPTIMIZED & HARDENED"
echo "==============================================="
echo "   - BBR & Kernel Tuning: ENABLED"
echo "   - ZRAM (200+ Users): ENABLED"
echo "   - BadVPN-UDPGW (Gaming): ENABLED"
echo "   - Auto-Healing Watchdog: ENABLED"
echo "==============================================="
echo "Installation complete!"
echo "Type 'jehad' to start the beast."
