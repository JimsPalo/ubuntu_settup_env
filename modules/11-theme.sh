#!/bin/bash
# Module 12: Dark theme, fonts, touchpad, window behaviour
source "$(dirname "$0")/lib.sh"

section "12 — Theme, Fonts & Interface"

g() { gsettings set "$@" 2>/dev/null || warn "gsettings: $*"; }

# Dark theme
g org.gnome.desktop.interface gtk-theme       'Adwaita-dark'
g org.gnome.desktop.interface color-scheme    'prefer-dark'
g org.gnome.desktop.interface icon-theme      'Yaru-dark'
g org.gnome.desktop.interface cursor-theme    'Yaru'
g org.gnome.desktop.interface enable-animations 'true'

# Subpixel font rendering (much sharper on LCD screens)
g org.gnome.desktop.interface font-antialiasing 'rgba'
g org.gnome.desktop.interface font-hinting      'slight'

# Solid black background
g org.gnome.desktop.background picture-uri          ''
g org.gnome.desktop.background picture-uri-dark     ''
g org.gnome.desktop.background primary-color        '#0d0d0d'
g org.gnome.desktop.background secondary-color      '#0d0d0d'
g org.gnome.desktop.background color-shading-type   'solid'

# Window buttons (minimize + maximize + close)
g org.gnome.desktop.wm.preferences button-layout    'appmenu:minimize,maximize,close'
g org.gnome.desktop.wm.preferences focus-mode       'click'
g org.gnome.desktop.wm.preferences auto-raise       'false'
g org.gnome.desktop.wm.preferences num-workspaces   '1'

# Mutter
g org.gnome.mutter edge-tiling           'true'
g org.gnome.mutter attach-modal-dialogs  'false'
g org.gnome.mutter dynamic-workspaces    'false'

# Touchpad (Windows-style: no natural scroll, tap-to-click)
g org.gnome.desktop.peripherals.touchpad tap-to-click               'true'
g org.gnome.desktop.peripherals.touchpad click-method               'fingers'
g org.gnome.desktop.peripherals.touchpad natural-scroll             'true'
g org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled 'true'
g org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled     'false'
g org.gnome.desktop.peripherals.touchpad tap-and-drag               'true'
g org.gnome.desktop.peripherals.touchpad tap-and-drag-lock          'false'
g org.gnome.desktop.peripherals.touchpad disable-while-typing       'true'
g org.gnome.desktop.peripherals.touchpad speed                      '0.3'
g org.gnome.desktop.peripherals.mouse    natural-scroll             'false'
g org.gnome.desktop.peripherals.mouse    accel-profile              'flat'
g org.gnome.desktop.peripherals.mouse    speed                      '0.0'

# Fontconfig for system-wide subpixel rendering
mkdir -p ~/.config/fontconfig
cat > ~/.config/fontconfig/fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="antialias"  mode="assign"><bool>true</bool></edit>
    <edit name="hinting"    mode="assign"><bool>true</bool></edit>
    <edit name="hintstyle"  mode="assign"><const>hintslight</const></edit>
    <edit name="rgba"       mode="assign"><const>rgb</const></edit>
    <edit name="lcdfilter"  mode="assign"><const>lcddefault</const></edit>
  </match>
</fontconfig>
EOF

echo ""
echo "  Verification:"
check_gsetting org.gnome.desktop.interface gtk-theme
check_gsetting org.gnome.desktop.interface font-antialiasing
check_gsetting org.gnome.desktop.peripherals.touchpad tap-to-click
check_gsetting org.gnome.desktop.peripherals.touchpad natural-scroll
