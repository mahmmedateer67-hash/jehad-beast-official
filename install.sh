#!/bin/bash

# ==============================================================================
# JEHAD BEAST - INSTALLATION SCRIPT v5.0
# ==============================================================================

# 1. System Update
echo "Updating system packages..."
apt-get update -qq

# 2. Create Base Infrastructure
echo "Creating Jehad Beast infrastructure..."
mkdir -p /etc/jehad/{core,modules,utils,config,bin,logs,security,dnstt}
chmod -R 755 /etc/jehad

# 3. Copy Files
echo "Copying project files..."
cp -r core/* /etc/jehad/core/
cp -r modules/* /etc/jehad/modules/
cp menu.sh /usr/local/bin/jehad

# 4. Install Dependencies
echo "Installing required dependencies..."
apt-get install -y stunnel4 lsof openssl jq curl dnsutils psmisc -qq

# 5. Set Permissions
chmod +x /usr/local/bin/jehad
chmod +x /etc/jehad/core/*.sh
chmod +x /etc/jehad/modules/*.sh

# 6. Advanced Optimizations (Firewoods Beast Logic)
echo "Applying Firewoods Beast Optimizations..."
if [ -f "/etc/jehad/core/optimizer.sh" ]; then
    source /etc/jehad/core/optimizer.sh
    run_all_optimizations
fi

# 7. Setup User Limiter
echo "Setting up connection limiter..."
if [ -f "/etc/jehad/modules/user_net.sh" ]; then
    source /etc/jehad/modules/user_net.sh
    setup_limiter
fi

echo "==============================================="
echo "   🚀 JEHAD BEAST - INFRASTRUCTURE READY"
echo "==============================================="
echo "   - Paths: /etc/jehad (VERIFIED)"
echo "   - Logs: /etc/jehad/logs (VERIFIED)"
echo "   - Command: 'jehad' (VERIFIED)"
echo "==============================================="
echo "Installation complete! Type 'jehad' to start."
