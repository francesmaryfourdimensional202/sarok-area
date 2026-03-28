# Sarok Area

Personal Arch Linux dotfiles and system setup. One command installs everything.

## What's Included

| Component | App |
|---|---|
| Window Manager | [Niri](https://github.com/YaLTeR/niri) |
| Shell | [Fish](https://fishshell.com/) + [Starship](https://starship.rs/) |
| Terminal | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| Desktop Shell | Caelestia (Quickshell-based) |
| File Manager | [Yazi](https://github.com/sxyazi/yazi) |
| Media | mpd, mpv |
| System | btop, fastfetch |
| Apps | Brave, Vesktop, WhatsApp, Telegram, and more |

## One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/sarok-exe/sarok-area/main/install.sh | bash
```

This will:
1. Clone this repo to `~/sarok-area`
2. Install all pacman packages
3. Install yay + AUR packages
4. Install Flatpak apps
5. Deploy dotfiles via symlinks
6. Build the Caelestia plugin
7. Set Fish as default shell and enable services

## Manual Install

```bash
git clone git@github.com:sarok-exe/sarok-area.git ~/sarok-area
cd ~/sarok-area
chmod +x setup.sh
./setup.sh
```

## Structure

```
sarok-area/
├── .config/          # All user configs (symlinked to ~/.config/)
│   ├── niri/         # Window manager config
│   ├── fish/         # Shell config, functions, themes
│   ├── kitty/        # Terminal config
│   ├── quickshell/   # Desktop shell + Caelestia plugin
│   ├── btop/         # System monitor
│   ├── cava/         # Audio visualizer
│   ├── mpd/          # Music daemon
│   ├── mpv/          # Video player
│   ├── yazi/         # File manager
│   ├── fastfetch/    # System info
│   ├── fcitx5/       # Input method
│   └── starship.toml # Prompt config
├── etc/              # System-level configs (copied to /etc/)
├── install.sh        # Bootstrap script (curl | bash)
├── setup.sh          # Main installer
├── LICENSE
└── README.md
```

## Customization

To add or update configs:
1. Edit the file directly in `~/sarok-area/.config/`
2. Since it's symlinked, changes take effect immediately
3. Commit and push to sync across machines

## License

GPL-3.0 — see [LICENSE](LICENSE).
