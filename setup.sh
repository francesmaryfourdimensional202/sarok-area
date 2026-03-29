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
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
DIM='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# --- Progress Bar ---
TOTAL_STEPS=9
CURRENT_STEP=0

draw_progress() {
    local width=40
    local step="$1"
    local label="$2"
    local pct=$(( step * 100 / TOTAL_STEPS ))
    local filled=$(( step * width / TOTAL_STEPS ))
    local empty=$(( width - filled ))

    printf "\r  ${DIM}[${NC}"
    printf "%0.s█" $(seq 1 "$filled" 2>/dev/null) || true
    printf "%0.s░" $(seq 1 "$empty" 2>/dev/null) || true
    printf "${DIM}]${NC} ${CYAN}%3d%%${NC} ${DIM}(%d/%d)${NC}  ${BOLD}%s${NC}" "$pct" "$step" "$TOTAL_STEPS" "$label"
    echo ""
}

# --- Helpers ---
log() { echo "$1" >> "$LOG_FILE"; }

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    draw_progress "$CURRENT_STEP" "$1"
}

ok()   { echo -e "      ${GREEN}[✓]${NC} $1"; }
warn() { echo -e "      ${YELLOW}[!]${NC} $1"; }
fail() { echo -e "      ${RED}[✗]${NC} $1"; FAILURES+=("$1"); }

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

# --- Clear Screen ---
clear

# --- Logo ---
echo ""
echo -e "  ${MAGENTA}  .dBBBBP dBBBBBb${NC}"
echo -e "  ${MAGENTA}    BP           BB  dP dP${NC}"
echo -e "  ${MAGENTA}    \`BBBBb   dBP BB dP dP${NC}"
echo -e "  ${MAGENTA}       dBP  dBP  BB${NC}"
echo -e "  ${MAGENTA}  dBBBBP'  dBBBBBBB${NC}"
echo ""
echo -e "  ${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}${BOLD}║     SAROK AREA — Full Arch Setup         ║${NC}"
echo -e "  ${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${DIM}Log: ${LOG_FILE}${NC}"
echo ""

# --- Preflight ---
if ! command -v pacman &>/dev/null; then
    echo -e "  ${RED}${BOLD}This script requires Arch Linux (pacman not found).${NC}"
    exit 1
fi

if [ "$EUID" -eq 0 ]; then
    echo -e "  ${RED}${BOLD}Do not run this script as root.${NC}"
    echo -e "  ${DIM}The script will use sudo when needed.${NC}"
    exit 1
fi

# ============================================================
#  1. Base Build Tools
# ============================================================
step "Base build tools"
run "Install base-devel git" sudo pacman -S --needed --noconfirm base-devel git

# ============================================================
#  2. yay (AUR Helper)
# ============================================================
step "AUR helper (yay)"

if command -v yay &>/dev/null; then
    ok "yay already installed"
else
    if git clone https://aur.archlinux.org/yay.git /tmp/yay >>"$LOG_FILE" 2>&1; then
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
#  3. Full System Update
# ============================================================
step "System update"
run "pacman -Syu" sudo pacman -Syu --noconfirm

# ============================================================
#  4. Pacman Packages
# ============================================================
step "Pacman packages"

PKGS=(
    niri fish kitty starship
    iwd pipewire wireplumber
    btop fastfetch
    yazi mpd mpv
    brightnessctl
    flameshot obsidian scrcpy
    duf cmake ninja aubio
    ttf-jetbrains-mono ttf-material-symbols-variable
)

run "Pacman install" sudo pacman -S --needed --noconfirm "${PKGS[@]}"

# ============================================================
#  5. AUR Packages
# ============================================================
step "AUR packages"

if command -v yay &>/dev/null; then
    AUR_PKGS=(quickshell-git impala rmpc vesktop)
    run "AUR install" yay -S --needed --noconfirm "${AUR_PKGS[@]}"
else
    fail "yay not available, skipping AUR packages"
fi

# ============================================================
#  6. Flatpak
# ============================================================
step "Flatpak setup"

run "Install flatpak" sudo pacman -S --needed --noconfirm flatpak
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
#  7. System Configs
# ============================================================
step "System configs (etc/)"

if [ -d "$REPO_DIR/etc" ]; then
    run "Copy system configs" sudo cp -rf "$REPO_DIR/etc/"* /etc/
else
    warn "No etc/ directory found, skipping."
fi

# ============================================================
#  8. Deploy Dotfiles
# ============================================================
step "Deploy dotfiles"

mkdir -p "$HOME/.config"

if [ -d "$DOT_SRC" ]; then
    for item in "$DOT_SRC"/*; do
        name="$(basename "$item")"
        target="$HOME/.config/$name"

        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mv "$target" "$target.bak-$(date +%s)"
            log "[Dotfiles] Backed up: $target"
        fi

        [ -L "$target" ] && rm "$target"
        ln -sf "$item" "$target"
    done
    ok "All dotfiles linked"
else
    fail "Source directory not found: $DOT_SRC"
fi

# ============================================================
#  9. Build Plugin + Shell + Services
# ============================================================
step "Plugin, shell & services"

# Caelestia plugin
PLUGIN_DIR="$HOME/.config/quickshell/plugin"
if [ -d "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR/CMakeLists.txt" ]; then
    rm -rf "$PLUGIN_DIR/build/"
    if cmake -B "$PLUGIN_DIR/build" -G Ninja -DCMAKE_BUILD_TYPE=Release "$PLUGIN_DIR" >>"$LOG_FILE" 2>&1; then
        if cmake --build "$PLUGIN_DIR/build" >>"$LOG_FILE" 2>&1; then
            run "Install Caelestia plugin" sudo cmake --install "$PLUGIN_DIR/build"
        else
            fail "Plugin build failed"
        fi
    else
        fail "Plugin cmake configure failed"
    fi
else
    warn "Plugin not found, skipping."
fi

# Set Fish as default
FISH_PATH="$(command -v fish 2>/dev/null || true)"
if [ -n "$FISH_PATH" ]; then
    if [ "$SHELL" != "$FISH_PATH" ]; then
        if chsh -s "$FISH_PATH" >>"$LOG_FILE" 2>&1; then
            ok "Fish set as default shell"
        else
            fail "Failed to set Fish as default shell"
        fi
    else
        ok "Fish already default shell"
    fi
else
    fail "Fish not found"
fi

# Enable services
for svc in iwd.service pipewire.service pipewire-pulse.service; do
    run "Enable $svc" sudo systemctl enable --now "$svc" 2>/dev/null || true
done

# ============================================================
#  Summary
# ============================================================
echo ""

draw_progress "$TOTAL_STEPS" "Done"

echo ""
echo -e "  ${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}${BOLD}║              SETUP COMPLETE               ║${NC}"
echo -e "  ${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

if [ ${#FAILURES[@]} -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}  All steps completed successfully.${NC}"
else
    echo -e "  ${YELLOW}${BOLD}  Completed with ${#FAILURES[@]} issue(s):${NC}"
    echo ""
    for f in "${FAILURES[@]}"; do
        echo -e "    ${RED}  • $f${NC}"
    done
    echo ""
    echo -e "  ${DIM}Check log: ${LOG_FILE}${NC}"
fi

echo ""
echo -e "  ${DIM}Restart your session or run:${NC} ${BOLD}exec fish${NC}"
echo ""
