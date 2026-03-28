# 🌌 Sarok-Area

A centralized repository for my personal Arch Linux configurations, focused on a smooth workflow with the **Niri** window manager and **Quickshell**.

## ✨ Overview
This repository contains my personal "Dotfiles" and configurations for:
- **Window Manager:** Niri
- **Shell:** Fish (with Starship prompt)
- **Terminal:** Kitty
- **Desktop Shell:** Custom Niri-Caelestia (Quickshell based)
- **Utilities:** Yazi, Btop, Cava, and more.

---

## 🚀 Installation

Follow these steps to set up the environment on your system:

### 1. Clone the Repository
```bash
cd ~/Documents/Projects
git clone git@github.com:sarok-exe/sarok-area.git
cd sarok-area
```

2. Install Dependencies
Make sure you have the required packages installed (Arch Linux):

```Bash
sudo pacman -S niri fish kitty starship quickshell-git networkmanager pipewire btop yazi
```

3. Deploy Configurations
You can manually copy the configurations to your ~/.config folder or create symbolic links:

```Bash
# Example for Niri
ln -s ~/Documents/Projects/sarok-area/.config/niri ~/.config/niri

# Example for Fish
ln -s ~/Documents/Projects/sarok-area/.config/fish ~/.config/fish
```

4. Build the Shell (Optional)
If you are using the Quickshell-based desktop, build it:

```Bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
```
Maintained with ❤️ by Sarok

