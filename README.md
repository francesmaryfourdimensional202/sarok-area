# Sarok Area

Personal Arch Linux dotfiles and system setup. One command installs everything.

## What's Included

| Component | App |
|---|---|
| Window Manager | [Niri](https://github.com/YaLTeR/niri) |
| Shell | [Bash](https://www.gnu.org/software/bash/) + [Starship](https://starship.rs/) |
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
1. Clone this repo to `~/.sarok-area`
2. Install all pacman packages
3. Install yay + AUR packages
4. Install Flatpak apps
5. Deploy dotfiles via symlinks
6. Build the Caelestia plugin
7. Set Bash as default shell with Starship prompt and enable services

## Manual Install

```bash
git clone git@github.com:sarok-exe/sarok-area.git ~/.sarok-area
cd ~/.sarok-area
chmod +x setup.sh
./setup.sh
```

## Structure

```
sarok-area/
├── .bashrc             # Shell config
├── .bash_profile       # Login shell config
├── pkg_list.txt        # Reference package list
├── .config/            # All user configs (symlinked to ~/.config/)
│   ├── niri/           # Window manager config
│   ├── kitty/          # Terminal config
│   ├── quickshell/     # Desktop shell + Caelestia plugin
│   ├── btop/           # System monitor
│   ├── cava/           # Audio visualizer
│   ├── mpv/            # Video player
│   ├── yazi/           # File manager
│   ├── fastfetch/      # System info
│   ├── nvim/           # Neovim config
│   ├── micro/          # Micro editor config
│   ├── dunst/          # Notification daemon
│   ├── thefuck/        # Command correction
│   └── starship.toml   # Prompt config
├── etc/                # System-level configs (copied to /etc/)
├── install.sh          # Bootstrap script (curl | bash)
├── setup.sh            # Main installer
├── update_shell.sh     # Update Caelestia shell plugin
├── multipath-wifi.sh   # Combine two WiFi adapters for speed
├── LICENSE
└── README.md
```

## Updating the Shell

To update the Caelestia shell plugin (niri-caelestia-shell):

```bash
cd ~/.sarok-area
chmod +x update_shell.sh
./update_shell.sh
```

This will:
1. Pull the latest changes from the upstream repo
2. Apply patches (removes cava dependency)
3. Rebuild and install the C++ plugin
4. Optionally restart the shell

Logs are saved to `~/caelestia_update.log`.

## Multipath WiFi (Dual Adapters)

If you're using two WiFi adapters (wlan0 + wlan1), use `multipath-wifi.sh` to combine them for increased bandwidth:

```bash
cd ~/.sarok-area
chmod +x multipath-wifi.sh
./multipath-wifi.sh
```

This creates a multipath route that balances traffic across both adapters. Requires `nload` (installed by setup.sh) to monitor network usage.

## Hosts File Blocking

The `etc/hosts` file blocks distracting and harmful websites system-wide. After installation, the hosts file is locked with `chattr +i` to prevent accidental modification.

**Blocked categories:**
- Time wasters (social media, meme sites)
- Gambling & betting sites
- Porn & adult content

**To modify the blocklist:**

```bash
# Unlock the file
sudo chattr -i /etc/hosts

# Edit with your editor
sudo nano /etc/hosts

# Lock it again
sudo chattr +i /etc/hosts
```

**To re-deploy after updating the repo:**

```bash
cd ~/.sarok-area
sudo cp -f etc/hosts /etc/hosts
sudo chattr +i /etc/hosts
```

## Customization

To add or update configs:
1. Edit the file directly in `~/.sarok-area/.config/`
2. Since it's symlinked, changes take effect immediately
3. Commit and push to sync across machines

## License

GPL-3.0 — see [LICENSE](LICENSE).
