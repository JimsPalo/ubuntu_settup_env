#!/bin/bash
# Module 01: System update & essential tools
source "$(dirname "$0")/lib.sh"

section "01 — Essentials"

# Remove snap if still present
if command -v snap &>/dev/null; then
    info "Removing snap..."
    for pkg in firefox snap-store gtk-common-themes snapd-desktop-integration \
                gnome-3-38-2004 gnome-42-2204 core20 core22 bare snapd; do
        sudo snap remove --purge "$pkg" 2>/dev/null || true
    done
    sudo apt autoremove --purge -y snapd 2>/dev/null || true
    sudo apt-mark hold snapd 2>/dev/null || true
    sudo rm -rf /var/cache/snapd/ /var/lib/snapd/ /var/snap/ /snap/ 2>/dev/null || true
    rm -rf ~/snap 2>/dev/null || true
fi
if [ ! -f /etc/apt/preferences.d/nosnap.pref ]; then
    sudo sh -c 'printf "Package: snapd\nPin: release a=*\nPin-Priority: -10\n" > /etc/apt/preferences.d/nosnap.pref'
fi

sudo apt update -qq || fail "apt update"
sudo apt upgrade -y  || fail "apt upgrade"
apt_install curl wget git htop btop neofetch micro \
    gnome-tweaks gnome-shell-extensions gnome-themes-extra \
    dconf-editor fuse3 xdotool wmctrl xclip xdg-utils \
    flameshot

mkdir -p ~/.local/bin
grep -q 'HOME/.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# micro — lightweight terminal text editor, set as default for text/plain
# (right-click any text file → Open With → Micro)
if [ ! -f /usr/share/applications/micro.desktop ]; then
    sudo tee /usr/share/applications/micro.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Micro
Comment=Modern and intuitive terminal-based text editor
Exec=micro %F
Terminal=true
Type=Application
Icon=utilities-terminal
Categories=Utility;TextEditor;
MimeType=text/plain;
EOF
    sudo update-desktop-database 2>/dev/null || true
fi
xdg-mime default micro.desktop text/plain

echo ""
echo "  Verification:"
check_cmd curl; check_cmd git; check_cmd wget; check_cmd htop; check_cmd btop
check_cmd xdotool; check_cmd wmctrl; check_cmd flameshot
check_cmd micro
check_file /usr/share/applications/micro.desktop
