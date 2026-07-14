#!/bin/bash
# Module 07: CopyQ clipboard manager — Ctrl+Super+V opens history picker
# Select any previous copied item to paste it
source "$(dirname "$0")/lib.sh"

section "07 — Clipboard Manager (CopyQ)"

if command -v copyq &>/dev/null; then
    ok "CopyQ already installed"
else
    apt_install copyq
fi

# Config: keep 200 items, close on unfocus
mkdir -p ~/.config/copyq
cat > ~/.config/copyq/copyq.conf << 'EOF'
[General]
check_clipboard=true
check_selection=false
close_on_unfocus=true
confirm_exit=false
maxitems=200
move_item_on_paste=true
show_tray=true
transparency=0
EOF

# Autostart
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/copyq.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=CopyQ
Comment=Clipboard Manager
Exec=copyq --start-server
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Remove old GPaste entries (redundant)
rm -f ~/.config/autostart/org.gnome.GPaste.desktop 2>/dev/null || true

# Bind Ctrl+Super+V → copyq toggle (opens clipboard history picker)
# Uses custom0 slot. Reads existing list and inserts custom0 if not present.
SLOT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
EXISTING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

if echo "$EXISTING" | grep -q "custom0"; then
    info "custom0 slot already in keybinding list"
else
    # Build new list: add custom0 to whatever already exists
    if echo "$EXISTING" | grep -q "@as \[\]"; then
        NEW="['${SLOT_PATH}']"
    else
        # Strip trailing ] and append custom0
        NEW=$(echo "$EXISTING" | sed "s|]$|, '${SLOT_PATH}']|")
    fi
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW"
fi

SLOT="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH}"
gsettings set "$SLOT" name    'Clipboard History'
gsettings set "$SLOT" command 'copyq toggle'
gsettings set "$SLOT" binding '<Ctrl><Super>v'

# Start CopyQ now (if installed)
if command -v copyq &>/dev/null; then
    pkill -x copyq 2>/dev/null || true
    sleep 0.3
    copyq --start-server 2>/dev/null &
fi

echo ""
echo "  Verification:"
check_cmd copyq
check_file ~/.config/autostart/copyq.desktop
BINDING=$(gsettings get "$SLOT" binding 2>/dev/null || echo "NOT SET")
[ "$BINDING" = "'<Ctrl><Super>v'" ] \
    && ok "keybinding Ctrl+Super+V → copyq toggle" \
    || warn "keybinding: $BINDING (expected <Ctrl><Super>v)"
info "Press Ctrl+Super+V to open clipboard history picker"
