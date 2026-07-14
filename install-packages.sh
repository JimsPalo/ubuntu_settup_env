#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# UBUNTU 22.04 — PACKAGE INSTALLER (requires sudo)
# Run once in a real terminal: sudo bash install-packages.sh
# ═══════════════════════════════════════════════════════════════

if [ "$EUID" -ne 0 ]; then
    echo "Run with: sudo bash install-packages.sh"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   PACKAGE INSTALLER (sudo required)          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

ok()   { echo "  [OK]   $*"; }
fail() { echo "  [FAIL] $*"; }
info() { echo "  [INFO] $*"; }

apt_safe() {
    apt install -y "$@" || fail "apt install: $*"
}

# ── System update ────────────────────────────────────────────────
echo "── System update ──"
apt update -qq || fail "apt update"
# Upgrade only security patches to avoid unexpected breakage
apt upgrade -y --only-upgrade 2>/dev/null || apt upgrade -y || fail "apt upgrade"

# ── Essential tools ──────────────────────────────────────────────
echo "── Essential tools ──"
apt_safe curl wget git htop btop neofetch micro \
    gnome-tweaks gnome-shell-extensions gnome-themes-extra \
    dconf-editor fuse3 xdotool wmctrl xclip xdg-utils \
    flameshot

# ── Python 3.12 ──────────────────────────────────────────────────
echo "── Python 3.12 ──"
if ! command -v python3.12 &>/dev/null; then
    add-apt-repository -y ppa:deadsnakes/ppa || fail "deadsnakes PPA"
    apt update -qq
fi
apt_safe python3.12 python3.12-dev python3.12-venv python3.12-tk
# Only alias bare "python" — never repoint /usr/bin/python3 itself.
# Ubuntu's system tools (gnome-terminal, software-properties-gtk, etc.)
# have #!/usr/bin/python3 shebangs and need the distro's python3 (3.10),
# whose compiled python3-gi extension doesn't exist for 3.12.
update-alternatives --install /usr/bin/python python /usr/bin/python3.12 2 2>/dev/null || true

# ── VS Code ───────────────────────────────────────────────────────
echo "── VS Code ──"
if ! command -v code &>/dev/null; then
    wget -qO /tmp/ms.gpg https://packages.microsoft.com/keys/microsoft.asc
    gpg --dearmor < /tmp/ms.gpg > /etc/apt/trusted.gpg.d/packages.microsoft.gpg
    rm -f /tmp/ms.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        > /etc/apt/sources.list.d/vscode.list
    apt update -qq || fail "apt update (VS Code)"
    apt_safe code
fi

# ── ONLYOFFICE (Word / Excel / PowerPoint) ───────────────────────
echo "── ONLYOFFICE ──"
if ! command -v desktopeditors &>/dev/null; then
    mkdir -p /usr/share/keyrings
    gpg --no-default-keyring \
        --keyring /usr/share/keyrings/onlyoffice.gpg \
        --keyserver hkps://keyserver.ubuntu.com \
        --recv-keys CB2DE8E5 2>/dev/null || fail "ONLYOFFICE GPG key (keyserver may be down)"
    echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' \
        > /etc/apt/sources.list.d/onlyoffice.list
    apt update -qq && apt_safe onlyoffice-desktopeditors || fail "ONLYOFFICE install"
fi

# ── Clipboard — CopyQ ────────────────────────────────────────────
echo "── CopyQ (clipboard) ──"
apt_safe copyq

# ── Touchegg (gestures) ──────────────────────────────────────────
# Always add the PPA and update, even if a touchegg binary already exists —
# Ubuntu's universe repo ships an ancient 1.1.1 build (pre client/server
# architecture) that satisfies `command -v touchegg` but doesn't work
# reliably with modern GNOME/libinput. Skip this and gestures silently
# never fire despite everything looking "installed."
echo "── Touchegg (gestures) ──"
add-apt-repository -y ppa:touchegg/stable 2>/dev/null || fail "touchegg PPA"
apt update -qq || fail "apt update (touchegg)"
apt_safe touchegg

# Touchegg only works on X11, and GDM defaults to Wayland — force X11 at
# the greeter so gestures work out of the box after the reboot below,
# instead of silently never firing until someone picks "Ubuntu on Xorg"
# by hand at login.
GDM_CONF="/etc/gdm3/custom.conf"
if [ -f "$GDM_CONF" ]; then
    if grep -q "^WaylandEnable" "$GDM_CONF"; then
        sed -i 's/^WaylandEnable.*/WaylandEnable=false/' "$GDM_CONF"
    elif grep -q "^#WaylandEnable" "$GDM_CONF"; then
        sed -i 's/^#WaylandEnable.*/WaylandEnable=false/' "$GDM_CONF"
    else
        sed -i '/^\[daemon\]/a WaylandEnable=false' "$GDM_CONF"
    fi
else
    fail "GDM config not found at $GDM_CONF — Wayland/X11 not forced"
fi

# ── Flatpak (for Touché — touchegg settings GUI) ─────────────────
echo "── Flatpak ──"
apt_safe flatpak

# ── Microsoft Edge ────────────────────────────────────────────────
echo "── Microsoft Edge ──"
if ! command -v microsoft-edge-stable &>/dev/null; then
    wget -qO /tmp/ms-edge.gpg https://packages.microsoft.com/keys/microsoft.asc
    gpg --dearmor < /tmp/ms-edge.gpg > /etc/apt/trusted.gpg.d/packages.microsoft.gpg
    rm -f /tmp/ms-edge.gpg
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" \
        > /etc/apt/sources.list.d/microsoft-edge-stable.list
    apt update -qq || fail "apt update (Edge)"
    apt_safe microsoft-edge-stable
fi

# ── Thunderbird (mail) ────────────────────────────────────────────
echo "── Thunderbird (mail) ──"
apt_safe thunderbird

# ── Pomodoro timer ────────────────────────────────────────────────
echo "── Pomodoro (gnome-shell-pomodoro) ──"
apt_safe gnome-shell-pomodoro

# ── Battery — TLP ────────────────────────────────────────────────
echo "── TLP (battery) ──"
apt_safe tlp tlp-rdw
systemctl disable power-profiles-daemon 2>/dev/null || true
systemctl mask    power-profiles-daemon 2>/dev/null || true
systemctl enable  tlp 2>/dev/null || fail "enable tlp"
systemctl start   tlp 2>/dev/null || fail "start tlp"

# ── System tuning ────────────────────────────────────────────────
echo "── System tuning ──"
sysctl -w vm.swappiness=10 vm.vfs_cache_pressure=50
printf "vm.swappiness=10\nvm.vfs_cache_pressure=50\n" > /etc/sysctl.d/99-performance.conf
systemctl enable fstrim.timer 2>/dev/null || true

# ── Cleanup ──────────────────────────────────────────────────────
apt autoremove -y && apt clean
fstrim -v / 2>/dev/null | head -2 || true

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Package installation complete!              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "Next step — run as your user (not sudo):"
echo "  bash /home/jimspal0/python/ubuntu_environment/install-all.sh"
echo ""
echo "Then configure Google Drive (optional):"
echo "  rclone config   (name it 'gdrive', choose Google Drive)"
echo "  systemctl --user enable --now rclone-gdrive.service"
echo ""
echo "Reboot when done: sudo reboot"
