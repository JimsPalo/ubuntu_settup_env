#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# UBUNTU 22.04 — INSTALLATION VERIFIER
# Checks every package/command/app this project installs and prints
# a pass/fail report. Read-only — no sudo required.
# Usage: bash verify-install.sh
# ═══════════════════════════════════════════════════════════════

PASS=0
FAIL=0
MISSING=()

check_pkg() {
    local pkg="$1"
    if dpkg -s "$pkg" &>/dev/null; then
        printf "  [OK]   %-30s (apt package)\n" "$pkg"
        PASS=$((PASS + 1))
    else
        printf "  [MISS] %-30s (apt package not installed)\n" "$pkg"
        FAIL=$((FAIL + 1))
        MISSING+=("$pkg — apt package")
    fi
}

check_cmd() {
    local cmd="$1" label="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        printf "  [OK]   %-30s -> %s\n" "$label" "$(command -v "$cmd")"
        PASS=$((PASS + 1))
    else
        printf "  [MISS] %-30s (command not found)\n" "$label"
        FAIL=$((FAIL + 1))
        MISSING+=("$label — command")
    fi
}

check_flatpak() {
    local app_id="$1" label="$2"
    if command -v flatpak &>/dev/null && flatpak list --user 2>/dev/null | grep -q "$app_id"; then
        printf "  [OK]   %-30s (flatpak, user)\n" "$label"
        PASS=$((PASS + 1))
    else
        printf "  [MISS] %-30s (flatpak app not installed)\n" "$label"
        FAIL=$((FAIL + 1))
        MISSING+=("$label — flatpak app")
    fi
}

check_file() {
    local path="$1" label="$2"
    if [ -e "$path" ]; then
        printf "  [OK]   %-30s\n" "$label"
        PASS=$((PASS + 1))
    else
        printf "  [MISS] %-30s (%s not found)\n" "$label" "$path"
        FAIL=$((FAIL + 1))
        MISSING+=("$label — file")
    fi
}

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   INSTALLATION VERIFICATION REPORT            ║"
echo "╚══════════════════════════════════════════════╝"

echo ""
echo "── Core tools (01-essentials.sh) ──"
check_cmd curl
check_cmd wget
check_cmd git
check_cmd htop
check_cmd btop
check_cmd neofetch
check_cmd micro
check_cmd xdotool
check_cmd wmctrl
check_cmd xclip
check_cmd xdg-open "xdg-utils"
check_cmd flameshot
check_cmd gnome-tweaks
check_pkg gnome-shell-extensions
check_pkg gnome-themes-extra
check_cmd dconf-editor
check_pkg fuse3

echo ""
echo "── Python (02-python.sh) ──"
check_cmd python3.12

echo ""
echo "── VS Code & Git (03-vscode.sh) ──"
check_cmd code

echo ""
echo "── ONLYOFFICE (04-onlyoffice.sh) ──"
check_cmd desktopeditors
check_pkg onlyoffice-desktopeditors

echo ""
echo "── Clipboard (06-clipboard.sh) ──"
check_cmd copyq

echo ""
echo "── Google Drive (07-google-drive.sh) ──"
check_cmd rclone

echo ""
echo "── Gestures (08-gestures.sh) ──"
check_cmd touchegg
check_cmd flatpak
check_flatpak com.github.joseexposito.touche "Touché"

echo ""
echo "── Battery (13-battery.sh) ──"
check_cmd tlp
check_pkg tlp-rdw

echo ""
echo "── System optimisation (14-optimise.sh) ──"
check_cmd preload

echo ""
echo "── Browser (15-browser.sh) ──"
check_cmd microsoft-edge-stable

echo ""
echo "── Pomodoro timer (16-pomodoro.sh) ──"
check_cmd gnome-pomodoro
check_pkg gnome-shell-pomodoro

echo ""
echo "── Custom helper commands ──"
check_file ~/.local/bin/eyecare              "eyecare"
check_file ~/.local/bin/gdrive-mount         "gdrive-mount"
check_file ~/.local/bin/gdrive-unmount       "gdrive-unmount"
check_file ~/.local/bin/gdrive-status        "gdrive-status"
check_file ~/.local/bin/battery-status       "battery-status"
check_file /usr/local/bin/set-battery-limit  "set-battery-limit"

echo ""
echo "════════════════════════════════════════════════"
printf "  RESULT: %d present, %d missing\n" "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "Missing:"
    for m in "${MISSING[@]}"; do
        echo "  - $m"
    done
    echo ""
    echo "Fix with:"
    echo "  sudo bash install-packages.sh   # apt packages"
    echo "  bash install-all.sh             # user-level config + Touché/helper scripts"
    exit 1
fi

echo ""
echo "Everything is installed."
exit 0
