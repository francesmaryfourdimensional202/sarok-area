#!/bin/bash

# ============================================================
#  Sarok Area — Full Arch Linux Setup
#  One command. Everything installed. Everything linked.
# ============================================================

set -uo pipefail

# --- Constants ---
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DOT_SRC="$REPO_DIR/.config"
LOG_FILE="/tmp/sarok-setup-$(date +%Y%m%d-%H%M%S).log"
FAILURES=()

# --- Colors ---
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# --- Helpers ---
log() { echo "$1" >> "$LOG_FILE"; }

step() { echo -e "\n${BLUE}${BOLD}==> ${NC}${BOLD}$1${NC}"; }
ok()   { echo -e "    ${GREEN}[✓]${NC} $1"; }
warn() { echo -e "    ${YELLOW}[!]${NC} $1"; }
fail() { echo -e "    ${RED}[✗]${NC} $1"; FAILURES+=("$1"); }

run() {
    local label="$1"
    shift
    log "[$label] Running: $*"
    if output=$("$@" 2>&1); then
        log "[$label] OK"
        ok "$label"
    else
        log "[$label] FAILED: $output"
        fail "$label"
    fi
}

# --- Preflight ---
step "Preflight checks"

if ! command -v pacman &>/dev/null; then
    echo -e "${RED}${BOLD}This script requires Arch Linux (pacman not found).${NC}"
    exit 1
fi
ok "Arch Linux detected"

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}${BOLD}Do not run this script as root.${NC}"
    echo "The script will use sudo when needed."
    exit 1
fi
ok "Running as non-root user"

# --- Header ---
echo ""
echo -e "${CYAN}${BOLD}┌──────────────────────────────────────┐${NC}"
echo -e "${CYAN}${BOLD}│     SAROK AREA — Full Setup           │${NC}"
echo -e "${CYAN}${BOLD}└──────────────────────────────────────┘${NC}"
echo ""
echo -e "  Log: ${LOG_FILE}"
echo ""

# ============================================================
#  1. System Configs
# ============================================================
step "Applying system configurations"

if [ -d "$REPO_DIR/etc" ]; then
    run "Copy system configs" sudo cp -rf "$REPO_DIR/etc/"* /etc/
else
    warn "No etc/ directory found, skipping."
fi

# ============================================================
#  2. yay (AUR Helper)
# ============================================================
step "AUR helper"

if command -v yay &>/dev/null; then
    ok "yay already installed"
else
    step "Installing yay"
    if git clone https://aur.archlinux.org/yay.git /tmp/yay 2>>"$LOG_FILE"; then
        if (cd /tmp/yay && makepkg -si --noconfirm >>"$LOG_FILE" 2>&1); then
            ok "yay installed"
        else
            fail "yay build failed"
        fi
    else
        fail "yay clone failed"
    fi
    rm -rf /tmp/yay
fi

# ============================================================
#  3. Pacman Packages
# ============================================================
step "Installing pacman packages"

PKGS=(
    # Window manager & shell
    niri fish kitty starship
    # Audio & networking
    iwd pipewire pipewire-pulse pipewire-alsa
    # System utilities
    brightnessctl btop fastfetch duf
    # File manager & media
    yazi mpd mpv
    # Development
    cmake ninja flatpak
    # Applications
    flameshot scrcpy
    # Fonts
    ttf-jetbrains-mono ttf-material-symbols-variable
)

run "Pacman install" sudo pacman -Sy --needed --noconfirm "${PKGS[@]}"

# ============================================================
#  4. AUR Packages
# ============================================================
step "Installing AUR packages"

if command -v yay &>/dev/null; then
    AUR_PKGS=(
        quickshell-git
        impala
        vesktop
        rmpc
    )
    run "AUR install" yay -S --needed --noconfirm "${AUR_PKGS[@]}"
else
    fail "yay not available, skipping AUR packages"
fi

# ============================================================
#  5. Flatpak Applications
# ============================================================
step "Installing Flatpak applications"

run "Add Flathub remote" sudo flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

FLAT_PKGS=(
    app.drey.Dialect
    com.brave.Browser
    com.dec05eba.gpu_screen_recorder
    com.fogpanther.FogPanther
    com.github.PintaProject.Pinta
    de.schmidhuberj.tubefeeder
    io.github.alainm23.planify
    io.github.mimbrero.WhatsAppDesktop
    org.telegram.desktop
)

run "Flatpak install" flatpak install -y flathub "${FLAT_PKGS[@]}"

# ============================================================
#  6. Deploy Dotfiles
# ============================================================
step "Deploying dotfiles"

mkdir -p "$HOME/.config"

if [ -d "$DOT_SRC" ]; then
    for item in "$DOT_SRC"/*; do
        name="$(basename "$item")"
        target="$HOME/.config/$name"

        # Backup existing config if it's not already a symlink
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mv "$target" "$target.bak-$(date +%s)"
            log "[Dotfiles] Backed up: $target"
        fi

        # Remove old symlink and create new one
        [ -L "$target" ] && rm "$target"
        ln -sf "$item" "$target"
    done
    ok "All dotfiles linked"
else
    fail "Source directory not found: $DOT_SRC"
fi

# ============================================================
#  7. Build Caelestia Plugin
# ============================================================
step "Building Caelestia plugin"

PLUGIN_DIR="$HOME/.config/quickshell/plugin"

if [ -d "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR/CMakeLists.txt" ]; then
    rm -rf "$PLUGIN_DIR/build/"
    if cmake -B "$PLUGIN_DIR/build" -G Ninja -DCMAKE_BUILD_TYPE=Release "$PLUGIN_DIR" >>"$LOG_FILE" 2>&1; then
        if cmake --build "$PLUGIN_DIR/build" >>"$LOG_FILE" 2>&1; then
            run "Install plugin" sudo cmake --install "$PLUGIN_DIR/build"
        else
            fail "Plugin build failed"
        fi
    else
        fail "Plugin cmake configure failed"
    fi
else
    warn "Plugin directory not found, skipping."
fi

# ============================================================
#  8. Shell & Services
# ============================================================
step "Setting up shell and services"

FISH_PATH="$(command -v fish 2>/dev/null || true)"

if [ -n "$FISH_PATH" ]; then
    if [ "$SHELL" != "$FISH_PATH" ]; then
        if chsh -s "$FISH_PATH" >>"$LOG_FILE" 2>&1; then
            ok "Fish set as default shell"
        else
            fail "Failed to set Fish as default shell"
        fi
    else
        ok "Fish is already default shell"
    fi
else
    fail "Fish not found"
fi

# Enable services
for svc in iwd.service pipewire.service pipewire-pulse.service; do
    run "Enable $svc" sudo systemctl enable --now "$svc"
done

# ============================================================
#  Summary
# ============================================================
echo ""
echo -e "${CYAN}${BOLD}┌──────────────────────────────────────┐${NC}"
echo -e "${CYAN}${BOLD}│            SETUP COMPLETE             │${NC}"
echo -e "${CYAN}${BOLD}└──────────────────────────────────────┘${NC}"
echo ""

if [ ${#FAILURES[@]} -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}All steps completed successfully.${NC}"
else
    echo -e "  ${YELLOW}${BOLD}Completed with ${#FAILURES[@]} issue(s):${NC}"
    for f in "${FAILURES[@]}"; do
        echo -e "    ${RED}• $f${NC}"
    done
    echo ""
    echo -e "  Check log: ${LOG_FILE}"
fi

echo ""
echo -e "  Restart your session or run: ${BOLD}exec fish${NC}"
echo ""
