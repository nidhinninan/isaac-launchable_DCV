#!/bin/bash
# ==============================================================================
# Automated Amazon DCV Setup for Isaac Sim (Brev/AWS)
# Supports: Ubuntu 22.04 and 24.04
# ==============================================================================

set -e

echo "--- [1/5] Verifying Environment ---"
# Determine target user (default to 'ubuntu' for AWS, fallback to current user)
if id "ubuntu" &>/dev/null; then
    TARGET_USER="ubuntu"
else
    TARGET_USER="$USER"
fi
echo "Target DCV owner: $TARGET_USER"

OS_VER=$(lsb_release -rs | sed 's/\.//')
if [[ "$OS_VER" != "2204" && "$OS_VER" != "2404" ]]; then
    echo "Unsupported OS version: $OS_VER. Only 22.04 and 24.04 are supported."
    exit 1
fi
echo "Detected Ubuntu $OS_VER"

echo "--- [2/5] Installing Desktop Environment ---"
sudo apt update
sudo apt install ubuntu-desktop -y
sudo apt install gdm3 -y

# Disable Wayland (Highly recommended for 3D apps like Isaac Sim)
sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
sudo systemctl restart gdm3

echo "--- [3/5] Downloading Amazon DCV 2025.0 ---"
# Import GPG key
wget -q https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
gpg --import NICE-GPG-KEY

# Download and extract the latest package
TGZ_NAME="nice-dcv-2025.0-20103-ubuntu${OS_VER}-x86_64.tgz"
wget -q "https://d1uj6qtbmh3dt5.cloudfront.net/2025.0/Servers/${TGZ_NAME}"
tar -xvzf "$TGZ_NAME"
cd "nice-dcv-2025.0-20103-ubuntu${OS_VER}-x86_64"

echo "--- [4/5] Installing DCV Server & GPU Components ---"
sudo apt install ./nice-dcv-server_*_amd64.ubuntu${OS_VER}.deb -y
sudo apt install ./nice-dcv-web-viewer_*_amd64.ubuntu${OS_VER}.deb -y
sudo apt install ./nice-xdcv_*_amd64.ubuntu${OS_VER}.deb -y
sudo apt install ./nice-dcv-gl_*_amd64.ubuntu${OS_VER}.deb -y

# Add user to video group
sudo usermod -aG video $TARGET_USER

echo "--- [5/5] Initializing DCV Server & Session ---"
sudo systemctl start dcvserver
sudo systemctl enable dcvserver

# Create console session
# Note: This will use the detected target user
sudo dcv create-session --type console --owner $TARGET_USER mysession

echo "=============================================================================="
echo " SETUP COMPLETE "
echo "=============================================================================="
echo "1. IMPORTANT: You MUST set a password for the DCV user to enable login."
echo "   Access your instance via the Brev terminal (e.g., brev shell <name>) and run:"
echo "   sudo passwd $TARGET_USER"
echo "2. Connection Port: 8443 (Ensure this is open in AWS/Brev)"
echo "3. Connect via: https://<instance-ip>:8443/ (or via DCV Viewer Client)"
echo "4. Port forwarding (optional): brev port-forward <workspace-name> --port 8443:8443"
echo "=============================================================================="
