#!/bin/bash

# 🌌 Sarok-Area Dotfiles Installer (Niri + Arch Linux)
set -e

# Colors for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}==>${NC} ${YELLOW}$1${NC}"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Sarok-Area Installation      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

# 1. Verification
if [ ! -f /etc/arch-release ]; then
    print_error "This script is for Arch Linux only!"
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
print_step "Working from: $DOTFILES_DIR"

# 2. Update & Core Tools
print_step "Updating system and installing base-devel..."
sudo pacman -Syu --needed --noconfirm git base-devel

# 3. Check for yay
if ! command -v yay &> /dev/null; then
    print_step "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm && cd "$DOTFILES_DIR"
fi

# 4. Install Packages
PACKAGES=(
    fish starship kitty niri yazi btop fastfetch cava mpv
    quickshell-git networkmanager pipewire flatpak
    brightnessctl fcitx5 fcitx5-gtk fcitx5-qt
)

print_step "Installing main packages..."
yay -S --needed --noconfirm "${PACKAGES[@]}"

# 5. Backup existing configs
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
print_step "Backing up old configs to $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

# 6. Linking Configurations (The Pro Way)
# This links everything inside .config/ in the repo to ~/.config/ in the system
print_step "Creating symbolic links for configurations..."

mkdir -p "$HOME/.config"

# Link all contents of .config from repo to ~/.config
for item in "$DOTFILES_DIR/.config"/*; do
    target="$HOME/.config/$(basename "$item")"
    
    if [ -e "$target" ] || [ -L "$target" ]; then
        mv "$target" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    ln -sf "$item" "$target"
    print_success "Linked $(basename "$item")"
done

# 7. Setup Assets (Profile Pic, etc.)
if [ -f "$DOTFILES_DIR/assets/profile.jpeg" ]; then
    print_step "Setting up profile picture..."
    ln -sf "$DOTFILES_DIR/assets/profile.jpeg" "$HOME/.face"
fi

# 8. Environment Setup for Niri & GTK4 Fix
print_step "Configuring environment variables..."
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/99-niri.conf" << 'EOF'
XDG_CURRENT_DESKTOP=niri
QT_QPA_PLATFORM=wayland
ELECTRON_OZONE_PLATFORM_HINT=auto
TERMINAL=kitty
# Ivy Bridge Stability Fixes
GDK_BACKEND=x11
GTK_USE_PORTAL=1
EOF

# 9. Finalizing
print_step "Changing default shell to Fish..."
chsh -s "$(which fish)" "$USER"

echo -e "\n${GREEN}✅ Installation Complete!${NC}"
echo "Please log out and select Niri."
echo "Backup of your old configs: $BACKUP_DIR"