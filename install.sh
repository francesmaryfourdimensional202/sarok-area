#!/bin/bash

# ============================================================
#  Sarok Area — Bootstrap Installer
#  Usage: curl -fsSL https://raw.githubusercontent.com/sarok-exe/sarok-area/main/install.sh | bash
# ============================================================

set -euo pipefail

REPO_URL="https://github.com/sarok-exe/sarok-area.git"
INSTALL_DIR="$HOME/sarok-area"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Sarok Area — Bootstrapping...${NC}"
echo ""

# Check git
if ! command -v git &>/dev/null; then
    echo -e "${RED}${BOLD}git is required but not found.${NC}"
    echo "Install it first: sudo pacman -S git"
    exit 1
fi

# Clone
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}${BOLD}Directory exists. Pulling latest...${NC}"
    git -C "$INSTALL_DIR" pull --rebase
else
    echo -e "${GREEN}${BOLD}Cloning repository...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Run setup
echo ""
cd "$INSTALL_DIR"
chmod +x setup.sh
exec bash setup.sh
