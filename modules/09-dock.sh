#!/bin/bash
# Module 10: Dock & App Launcher (floating, auto-hide, Windows-style)
source "$(dirname "$0")/lib.sh"

section "10 — Dock & App Launcher"

g() { gsettings set "$@" 2>/dev/null || warn "gsettings: $*"; }

# Floating dock — auto-hides only when a window overlaps it
g org.gnome.shell.extensions.dash-to-dock dock-position        'BOTTOM'
g org.gnome.shell.extensions.dash-to-dock dock-fixed           'false'
g org.gnome.shell.extensions.dash-to-dock autohide             'true'
g org.gnome.shell.extensions.dash-to-dock intellihide          'true'
g org.gnome.shell.extensions.dash-to-dock intellihide-mode     'ALL_WINDOWS'
g org.gnome.shell.extensions.dash-to-dock extend-height        'false'
g org.gnome.shell.extensions.dash-to-dock dash-max-icon-size   '40'
g org.gnome.shell.extensions.dash-to-dock click-action         'minimize-or-previews'
g org.gnome.shell.extensions.dash-to-dock show-windows-preview 'true'
g org.gnome.shell.extensions.dash-to-dock animate-show-apps    'true'
g org.gnome.shell.extensions.dash-to-dock show-favorites       'true'
g org.gnome.shell.extensions.dash-to-dock show-running         'true'
g org.gnome.shell.extensions.dash-to-dock isolate-workspaces   'false'
g org.gnome.shell.extensions.dash-to-dock show-trash           'false'
g org.gnome.shell.extensions.dash-to-dock show-mounts          'true'
g org.gnome.shell.extensions.dash-to-dock background-opacity   '0.7'
g org.gnome.shell.extensions.dash-to-dock transparency-mode    'FIXED'
g org.gnome.shell.extensions.dash-to-dock require-pressure-to-show 'false'
g org.gnome.shell.extensions.dash-to-dock show-delay           '0'
g org.gnome.shell.extensions.dash-to-dock hide-delay           '0.2'

# ── App grid: hide system/admin/redundant apps ──────────────────
LOCAL_APPS="$HOME/.local/share/applications"
mkdir -p "$LOCAL_APPS"

hide_app() {
    local name="$1"
    # Only create override if system .desktop exists; skip if already hidden
    if [ -f "/usr/share/applications/${name}.desktop" ]; then
        printf '[Desktop Entry]\nNoDisplay=true\n' > "$LOCAL_APPS/${name}.desktop"
    fi
}

# Redundant terminals
hide_app xterm
hide_app uxterm

# Command-line tools with misleading GUI entries
hide_app display-im6.q16          # ImageMagick
hide_app display-im6.q16hdri

# System admin — rarely needed from app grid
hide_app yelp                     # Help
hide_app gnome-language-selector  # Language Support
hide_app gnome-power-statistics   # Power Statistics
hide_app software-properties-gtk  # Software & Updates
hide_app update-manager           # Software Updater
hide_app gnome-session-properties # Startup Applications

# Obscure/domain-specific tools
hide_app prerex
hide_app vprerex
hide_app micro                    # Terminal text editor

update-desktop-database "$LOCAL_APPS" 2>/dev/null || true
info "App grid: system/admin/redundant entries hidden"

echo ""
echo "  Verification:"
check_gsetting org.gnome.shell.extensions.dash-to-dock autohide
check_gsetting org.gnome.shell.extensions.dash-to-dock intellihide-mode
check_gsetting org.gnome.shell.extensions.dash-to-dock dash-max-icon-size
info "Dock: floating bottom bar, auto-hides when windows overlap"
