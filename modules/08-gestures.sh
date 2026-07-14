#!/bin/bash
# Module 09: 3-finger touchpad gestures (Windows-style, X11 via touchegg)
#   LEFT  → next window (Alt+Tab)
#   RIGHT → previous window (Alt+Shift+Tab)
#   DOWN  → minimize current window
#   UP    → GNOME overview
source "$(dirname "$0")/lib.sh"

section "08 — 3-Finger Gestures (touchegg + Touché)"

# Touchegg requires X11 — warn if on Wayland
if [ "${XDG_SESSION_TYPE}" = "wayland" ]; then
    warn "Wayland detected — touchegg gestures need X11."
    warn "At login screen: click gear icon → 'Ubuntu on Xorg'"
fi

# Always add the PPA and update, even if a touchegg binary already exists —
# Ubuntu's universe repo ships an ancient 1.1.1 build (pre client/server
# architecture) that satisfies `command -v touchegg` but doesn't work
# reliably with modern GNOME/libinput. Skip this and gestures silently
# never fire despite everything looking "installed."
sudo add-apt-repository -y ppa:touchegg/stable 2>/dev/null || warn "touchegg PPA"
sudo apt update -qq || fail "apt update (touchegg)"
apt_install touchegg
# Remove fusuma — redundant on X11 (touchegg handles gestures)
rm -f ~/.config/autostart/fusuma.desktop 2>/dev/null || true

# Install gesture-alttab helper: holds Alt between swipe steps
mkdir -p ~/.local/bin
cat > ~/.local/bin/gesture-alttab << 'SCRIPT'
#!/bin/bash
# Holds Alt+Tab switcher open while fingers stay on touchpad.
# Each call cycles one window; Alt releases after 1s of inactivity.
DIR="${1:-fwd}"
TOUCH="/tmp/.gesture_alttab"
KILLER="${TOUCH}.killer"

if [ ! -f "$TOUCH" ]; then
    touch "$TOUCH"
    xdotool keydown alt
fi

[ "$DIR" = "fwd" ] && xdotool key Tab || xdotool key shift+Tab

kill "$(cat "$KILLER" 2>/dev/null)" 2>/dev/null || true
( sleep 1.0 && xdotool keyup alt && rm -f "$TOUCH" "$KILLER" ) &
echo $! > "$KILLER"
SCRIPT
chmod +x ~/.local/bin/gesture-alttab

# Write clean touchegg config
mkdir -p ~/.config/touchegg
cat > ~/.config/touchegg/touchegg.conf << 'EOF'
<touchégg>
  <settings>
    <property name="animation_delay">150</property>
    <property name="action_execute_threshold">20</property>
    <property name="color">auto</property>
    <property name="borderColor">auto</property>
  </settings>
  <application name="All">

    <!-- 3-finger TAP: open Show Applications grid -->
    <gesture type="TAP" fingers="3" direction="UNKNOWN">
      <action type="SEND_KEYS">
        <modifiers>Super_L</modifiers>
        <keys>a</keys>
        <repeat>false</repeat>
        <animation>NONE</animation>
        <on>begin</on>
      </action>
    </gesture>

    <!-- 3-finger RIGHT: next window | reverse mid-swipe → previous -->
    <gesture type="SWIPE" fingers="3" direction="RIGHT">
      <action type="RUN_COMMAND">
        <command>~/.local/bin/gesture-alttab fwd</command>
        <repeat>true</repeat>
        <animation>NONE</animation>
        <decrease_command>~/.local/bin/gesture-alttab bwd</decrease_command>
      </action>
    </gesture>

    <!-- 3-finger LEFT: previous window | reverse mid-swipe → next -->
    <gesture type="SWIPE" fingers="3" direction="LEFT">
      <action type="RUN_COMMAND">
        <command>~/.local/bin/gesture-alttab bwd</command>
        <repeat>true</repeat>
        <animation>NONE</animation>
        <decrease_command>~/.local/bin/gesture-alttab fwd</decrease_command>
      </action>
    </gesture>

    <!-- 3-finger DOWN: minimize ALL windows (show desktop) -->
    <gesture type="SWIPE" fingers="3" direction="DOWN">
      <action type="RUN_COMMAND">
        <command>wmctrl -k on</command>
        <repeat>false</repeat>
        <animation>NONE</animation>
        <decrease_command></decrease_command>
      </action>
    </gesture>

    <!-- 3-finger UP: GNOME overview -->
    <gesture type="SWIPE" fingers="3" direction="UP">
      <action type="SEND_KEYS">
        <modifiers>Super_L</modifiers>
        <keys>Tab</keys>
        <repeat>false</repeat>
        <animation>NONE</animation>
        <on>begin</on>
      </action>
    </gesture>

    <!-- 4-finger LEFT/RIGHT: switch workspaces -->
    <gesture type="SWIPE" fingers="4" direction="LEFT">
      <action type="CHANGE_DESKTOP">
        <direction>next</direction>
        <repeat>false</repeat>
        <animation>SLIDE</animation>
        <animationPosition>auto</animationPosition>
        <color>9C27B0</color>
        <borderColor>9C27B0</borderColor>
      </action>
    </gesture>
    <gesture type="SWIPE" fingers="4" direction="RIGHT">
      <action type="CHANGE_DESKTOP">
        <direction>previous</direction>
        <repeat>false</repeat>
        <animation>SLIDE</animation>
        <animationPosition>auto</animationPosition>
        <color>9C27B0</color>
        <borderColor>9C27B0</borderColor>
      </action>
    </gesture>

    <!-- 4-finger UP: maximize/restore current window -->
    <gesture type="SWIPE" fingers="4" direction="UP">
      <action type="MAXIMIZE_RESTORE_WINDOW">
        <animation>NONE</animation>
      </action>
    </gesture>

    <!-- 4-finger DOWN: minimize current window -->
    <gesture type="SWIPE" fingers="4" direction="DOWN">
      <action type="MINIMIZE_WINDOW">
        <animation>NONE</animation>
      </action>
    </gesture>

    <!-- 4-finger PINCH IN: show desktop -->
    <gesture type="PINCH" fingers="4" direction="IN">
      <action type="SHOW_DESKTOP">
        <animation>NONE</animation>
      </action>
    </gesture>

    <!-- 4-finger PINCH OUT: overview -->
    <gesture type="PINCH" fingers="4" direction="OUT">
      <action type="SEND_KEYS">
        <modifiers>Super_L</modifiers>
        <keys>Tab</keys>
        <repeat>false</repeat>
        <animation>NONE</animation>
        <on>begin</on>
      </action>
    </gesture>

  </application>
</touchégg>
EOF

# Autostart entry
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/touchegg.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Touchegg
Exec=touchegg
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Restart with new config
pkill -x touchegg 2>/dev/null || true; sleep 1
nohup touchegg > /dev/null 2>&1 &

# Touché — GUI to inspect/tweak touchegg gestures instead of hand-editing XML.
# No native .deb anymore; upstream ships it as a Flatpak only. flatpak itself
# is installed system-wide by install-packages.sh; the remote+app are per-user
# here so this module needs no sudo.
if command -v flatpak &>/dev/null; then
    flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null \
        || warn "flathub remote add"
    flatpak install --user -y flathub com.github.joseexposito.touche 2>/dev/null \
        || warn "Touché install (flatpak)"
else
    warn "flatpak not found — run install-packages.sh first to get the Touché GUI"
fi

echo ""
echo "  Verification:"
check_cmd touchegg
check_file ~/.config/touchegg/touchegg.conf
check_file ~/.config/autostart/touchegg.desktop
[ ! -f ~/.config/autostart/fusuma.desktop ] && ok "fusuma autostart removed" || warn "fusuma still present"
if command -v flatpak &>/dev/null && flatpak list --user 2>/dev/null | grep -q joseexposito.touche; then
    ok "Touché installed — launch from app grid or: flatpak run com.github.joseexposito.touche"
else
    warn "Touché not installed"
fi
info "3-finger TAP=apps  LEFT/RIGHT=cycle windows (Alt held)  DOWN=show desktop  UP=overview"
info "4-finger LEFT/RIGHT=switch workspace  UP=maximize  DOWN=minimize  PINCH IN=desktop  PINCH OUT=overview"
info "Fine-tune gestures anytime in the Touché app instead of editing touchegg.conf by hand"
