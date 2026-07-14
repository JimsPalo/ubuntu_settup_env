#!/bin/bash
# Module 11: Windows-style keyboard shortcuts + Flameshot screenshot
source "$(dirname "$0")/lib.sh"

section "11 — Keyboard Shortcuts (Windows-style)"

g() { gsettings set "$@" 2>/dev/null || warn "gsettings: $*"; }

# Window control
g org.gnome.desktop.wm.keybindings close              "['<Alt>F4']"
g org.gnome.desktop.wm.keybindings toggle-maximized   "['<Super>Up']"
g org.gnome.desktop.wm.keybindings minimize           "['<Super>Down']"
g org.gnome.desktop.wm.keybindings begin-move         "['<Alt>F7']"
g org.gnome.desktop.wm.keybindings begin-resize       "['<Alt>F8']"

# Window tiling (snap to sides)
g org.gnome.desktop.wm.keybindings move-to-side-e     "['<Super>Right']"
g org.gnome.desktop.wm.keybindings move-to-side-w     "['<Super>Left']"

# Workspace (Ctrl+Alt+Arrow — Windows-style)
g org.gnome.desktop.wm.keybindings switch-to-workspace-left    "['<Ctrl><Alt>Left']"
g org.gnome.desktop.wm.keybindings switch-to-workspace-right   "['<Ctrl><Alt>Right']"
g org.gnome.desktop.wm.keybindings move-to-workspace-left      "['<Ctrl><Alt><Shift>Left']"
g org.gnome.desktop.wm.keybindings move-to-workspace-right     "['<Ctrl><Alt><Shift>Right']"

# App switching (Alt+Tab — shows individual windows, Windows-style)
g org.gnome.desktop.wm.keybindings switch-applications          "['<Alt>Tab']"
g org.gnome.desktop.wm.keybindings switch-applications-backward "['<Alt><Shift>Tab']"
g org.gnome.desktop.wm.keybindings switch-windows               "['<Alt>Tab']"
g org.gnome.desktop.wm.keybindings switch-windows-backward      "['<Alt><Shift>Tab']"

# System shortcuts
g org.gnome.settings-daemon.plugins.media-keys screensaver     "['<Super>l']"
g org.gnome.settings-daemon.plugins.media-keys home            "['<Super>e']"
g org.gnome.settings-daemon.plugins.media-keys terminal        "['<Super>t']"
g org.gnome.settings-daemon.plugins.media-keys control-center  "['<Super>i']"

# Disable ALL built-in screenshot keys — GNOME Shell intercepts Print before
# custom keybindings reach it unless both layers are cleared.
g org.gnome.settings-daemon.plugins.media-keys screenshot      "@as []"
g org.gnome.settings-daemon.plugins.media-keys screenshot-clip "@as []"
g org.gnome.settings-daemon.plugins.media-keys area-screenshot "@as []"
g org.gnome.shell.keybindings show-screenshot-ui               "@as []"
g org.gnome.shell.keybindings screenshot                       "@as []"

# Overview
g org.gnome.shell.keybindings toggle-overview          "['<Super>Tab']"
g org.gnome.shell.keybindings toggle-application-view  "['<Super>a']"

# Flameshot screenshot — Print Screen → full interactive capture
# Shift+Super+S → region capture (Windows Snipping Tool equivalent)
SLOT_PATH1="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
SLOT_PATH2="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
SLOT_PATH3="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"

add_slot() {
    local path="$1"
    local current
    current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
    if echo "$current" | grep -q "$path"; then
        return 0
    fi
    if echo "$current" | grep -q "@as \[\]"; then
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
    else
        local new
        new=$(echo "$current" | sed "s|]$|, '$path']|")
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new"
    fi
}

add_slot "$SLOT_PATH1"
SLOT1="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH1}"
gsettings set "$SLOT1" name    'Screenshot (Flameshot)'
gsettings set "$SLOT1" command 'flameshot gui'
gsettings set "$SLOT1" binding 'Print'

add_slot "$SLOT_PATH2"
SLOT2="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH2}"
gsettings set "$SLOT2" name    'Screenshot Region (Shift+Super+S)'
gsettings set "$SLOT2" command 'flameshot gui'
gsettings set "$SLOT2" binding '<Shift><Super>s'

add_slot "$SLOT_PATH3"
SLOT3="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH3}"
gsettings set "$SLOT3" name    'Screenshot Region (Ctrl+Shift+S)'
gsettings set "$SLOT3" command 'flameshot gui'
gsettings set "$SLOT3" binding '<Ctrl><Shift>s'

echo ""
echo "  Verification:"
info "Alt+F4=close  Super+Up=max  Super+Down=min  Alt+Tab=switch"
info "Super+L=lock  Super+E=files  Super+T=terminal  Super+I=settings"
info "Print=Flameshot  Shift+Super+S=region  Ctrl+Shift+S=region"
B1=$(gsettings get "$SLOT1" binding 2>/dev/null || echo "NOT SET")
B2=$(gsettings get "$SLOT2" binding 2>/dev/null || echo "NOT SET")
B3=$(gsettings get "$SLOT3" binding 2>/dev/null || echo "NOT SET")
ok "Print → $B1"
ok "Shift+Super+S → $B2"
ok "Ctrl+Shift+S → $B3"
