#!/usr/bin/env bash
# ==============================================================================
# Noctalia WhatsApp Plugin - Dependency & Environment Installer
# Installs missing system packages (wtype, wl-clipboard, python-evdev, libnotify)
# and configures /dev/uinput permissions across various Linux distributions.
# ==============================================================================

set -e

# Terminal colors
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${GREEN}    Noctalia WhatsApp Plugin — Dependency Setup${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}\n"

# 1. Detect Linux distribution
DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_LIKE=${ID_LIKE:-""}
fi

echo -e "${BLUE}[*]${NC} Detected System: ${BOLD}${PRETTY_NAME:-$DISTRO}${NC}"

# 2. Identify and execute package installation
INSTALLED_PKGS=false

if command -v pacman &>/dev/null; then
    echo -e "${BLUE}[*]${NC} Using Arch Linux / Pacman package manager..."
    echo -e "${YELLOW}[!]${NC} Elevating privileges with sudo to install required packages:"
    echo -e "    • wtype (Wayland keystroke typer)"
    echo -e "    • wl-clipboard (Wayland clipboard manager)"
    echo -e "    • python-evdev (Kernel input injection for call redialing)"
    echo -e "    • libnotify (Desktop notifications)\n"
    
    sudo pacman -S --needed --noconfirm wtype wl-clipboard python-evdev libnotify
    INSTALLED_PKGS=true

elif command -v dnf &>/dev/null; then
    echo -e "${BLUE}[*]${NC} Using Fedora / DNF package manager..."
    sudo dnf install -y wtype wl-clipboard python3-evdev libnotify
    INSTALLED_PKGS=true

elif command -v apt-get &>/dev/null; then
    echo -e "${BLUE}[*]${NC} Using Debian / Ubuntu APT package manager..."
    sudo apt-get update
    sudo apt-get install -y wtype wl-clipboard python3-evdev libnotify-bin
    INSTALLED_PKGS=true

elif command -v zypper &>/dev/null; then
    echo -e "${BLUE}[*]${NC} Using openSUSE / Zypper package manager..."
    sudo zypper install -y wtype wl-clipboard python3-evdev libnotify-tools
    INSTALLED_PKGS=true

elif command -v apk &>/dev/null; then
    echo -e "${BLUE}[*]${NC} Using Alpine Linux APK package manager..."
    sudo apk add wtype wl-clipboard py3-evdev libnotify
    INSTALLED_PKGS=true

elif command -v xbps-install &>/dev/null; then
    echo -e "${BLUE}[*]${NC} Using Void Linux XBPS package manager..."
    sudo xbps-install -Sy wtype wl-clipboard python3-evdev libnotify
    INSTALLED_PKGS=true

elif command -v nix-env &>/dev/null; then
    echo -e "${YELLOW}[!]${NC} Nix package manager detected."
    echo -e "    Run in your shell or add to configuration.nix / home-manager:"
    echo -e "    ${BOLD}nix-env -iA nixpkgs.wtype nixpkgs.wl-clipboard nixpkgs.python3Packages.evdev nixpkgs.libnotify${NC}\n"
else
    echo -e "${RED}[X] No supported package manager found.${NC}"
    echo -e "    Please manually install: ${BOLD}wtype, wl-clipboard, python-evdev, libnotify${NC}"
fi

# 3. Configure /dev/uinput permissions for mouse clicking (needed for Auto Call Redial)
echo -e "\n${BOLD}${CYAN}------------------------------------------------------${NC}"
echo -e "${BOLD}[*] Checking /dev/uinput permissions (for Auto Call Redial)...${NC}"

CURRENT_USER=$(id -un)

if [ -w /dev/uinput ]; then
    echo -e "${GREEN}✓ /dev/uinput is writable by ${CURRENT_USER}!${NC}"
else
    echo -e "${YELLOW}[!] Current user does not have write access to /dev/uinput.${NC}"
    echo -e "    Setting up udev rule and adding ${BOLD}${CURRENT_USER}${NC} to the ${BOLD}input${NC} group..."

    # Ensure uinput kernel module is loaded
    sudo modprobe uinput 2>/dev/null || true

    # Create udev rule for persistent uinput group access
    sudo tee /etc/udev/rules.d/99-uinput.rules > /dev/null << 'EOF'
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
EOF

    # Add user to input group
    sudo usermod -aG input "$CURRENT_USER"

    # Reload udev rules
    sudo udevadm control --reload-rules 2>/dev/null || true
    sudo udevadm trigger 2>/dev/null || true

    # Also apply permissions directly for the current session if device exists
    if [ -e /dev/uinput ]; then
        sudo setfacl -m "u:${CURRENT_USER}:rw" /dev/uinput 2>/dev/null || sudo chmod 666 /dev/uinput 2>/dev/null || true
    fi

    echo -e "${GREEN}✓ udev rules installed and user added to 'input' group.${NC}"
    echo -e "${YELLOW}ℹ Note: A full relogin or 'newgrp input' ensures group membership takes full effect.${NC}"
fi

# 4. Final verification
echo -e "\n${BOLD}${CYAN}------------------------------------------------------${NC}"
echo -e "${BOLD}[*] Verification:${NC}"

ALL_OK=true

for cmd in wtype wl-copy hyprctl notify-send; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "  • ${cmd} : ${GREEN}✓ Installed${NC}"
    else
        echo -e "  • ${cmd} : ${RED}❌ Not found${NC}"
        ALL_OK=false
    fi
done

if python3 -c "import evdev" &>/dev/null; then
    echo -e "  • python-evdev : ${GREEN}✓ Installed${NC}"
else
    echo -e "  • python-evdev : ${RED}❌ Not found${NC}"
    ALL_OK=false
fi

if [ -w /dev/uinput ]; then
    echo -e "  • /dev/uinput access : ${GREEN}✓ Writable${NC}"
else
    echo -e "  • /dev/uinput access : ${YELLOW}⚠️ Requires relogin to apply group${NC}"
fi

echo -e "${BOLD}${CYAN}======================================================${NC}"
if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}${BOLD}🎉 Setup complete! All dependencies are installed and ready.${NC}"
else
    echo -e "${YELLOW}${BOLD}⚠️  Some dependencies may still require attention (see above).${NC}"
fi
echo -e "${BOLD}${CYAN}======================================================${NC}\n"

read -rp "Press Enter to close this window..."
