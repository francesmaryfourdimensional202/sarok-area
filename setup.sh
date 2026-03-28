#!/bin/bash

# 🌌 Sarok-Area Ultimate Auto-Installer
# Optimized for: Arch Linux + Niri + iwd/Impala
# Created by Sarok (2026)

set -e

# --- Visual Setup (Colors & Icons) ---
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_header() {
    clear
    echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║                🌌 WELCOME TO SAROK-AREA OS                  ║${NC}"
    echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Targeting: Arch Linux | Window Manager: Niri | Shell: Fish${NC}\n"
}

print_step() { echo -e "${BLUE}${BOLD}==>${NC} ${BOLD}$1${NC}"; }
print_success() { echo -e "${GREEN}${BOLD} [✓]${NC} $1"; }
print_error() { echo -e "${RED}${BOLD} [✗]${NC} $1"; }

# --- Root Check & System Validation ---
print_header
if [ ! -f /etc/arch-release ]; then
    print_error "This script requires Arch Linux. Exiting..."
    exit 1
fi

# --- 1. System Infrastructure (Critical Configs) ---
print_step "Applying System Infrastructure (etc/)..."
if [ -d "etc" ]; then
    sudo cp -rf etc/* /etc/
    print_success "Applied pacman.conf, mirrorlist, and hosts."
else
    print_error "etc/ directory not found in repository. Skipping..."
fi

# --- 2. Tooling: yay & flatpak ---
print_step "Ensuring AUR Helper (yay) and Flatpak are ready..."
sudo pacman -Syu --needed --noconfirm base-devel git flatpak

if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm && cd -
fi
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
print_success "Tools are ready."

# --- 3. Package Lists ---
PACMAN_PKGS=(
    niri fish kitty starship iwd pipewire wireplumber
    btop fastfetch yazi mpd mpv brightnessctl eza
    flameshot dolphin obsidian discord scrcpy duf
    ttf-jetbrains-mono ttf-material-symbols-variable
)

AUR_PKGS=(
    quickshell-git impala-git app2unit-git rmpc
    material-icon-theme-git bibata-modern-ice-cursor-theme
    zen-browser-bin visual-studio-code-bin wallust-git
)

FLATPAK_PKGS=(
    app.drey.Dialect com.brave.Browser com.dec05eba.gpu_screen_recorder
    com.fogpanther.FogPanther com.github.PintaProject.Pinta
    de.schmidhuberj.tubefeeder io.github.alainm23.planify
    io.github.mimbrero.WhatsAppDesktop org.telegram.desktop
)

# --- 4. Main Installation ---
print_step "Installing Pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

print_step "Installing AUR packages (This may take a while)..."
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

print_step "Installing Flatpak applications..."
flatpak install -y flathub "${FLATPAK_PKGS[@]}"

# --- 5. Deploy Dotfiles (Symlinking) ---
print_step "Deploying configurations (Symlinking)..."
DOTFILES_DIR=$(pwd)
mkdir -p ~/.config

for item in "$DOTFILES_DIR/.config"/*; do
    target="$HOME/.config/$(basename "$item")"
    [ -e "$target" ] && [ ! -L "$target" ] && mv "$target" "$target.bak-$(date +%s)"
    ln -sf "$item" "$target"
done
print_success "Configurations linked to ~/.config"

# --- 6. Build Quickshell Caelestia Plugin ---
if [ -d "$HOME/.config/quickshell" ]; then
    print_step "Building Quickshell C++ Plugin..."
    cd "$HOME/.config/quickshell"
    rm -rf build/
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    cmake --build build
    sudo cmake --install build
    print_success "Plugin built and installed."
fi

# --- 7. Networking & Shell ---
print_step "Finalizing environment..."
sudo systemctl enable --now iwd.service
sudo systemctl disable --now NetworkManager.service 2>/dev/null || true
[ "$SHELL" != "$(which fish)" ] && chsh -s "$(which fish)"
print_success "iwd enabled and default shell set to Fish."

echo -e "\n${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║           ✅ SETUP COMPLETE! REBOOT OR RELOGIN              ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
