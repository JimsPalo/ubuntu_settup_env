#!/bin/bash
# Module 13: Blue light filter + eyecare toggle command
source "$(dirname "$0")/lib.sh"

section "13 — Eye Care (Blue Light Filter)"

g() { gsettings set "$@" 2>/dev/null || warn "gsettings: $*"; }

# GNOME night light: warm tone from 18:00 to 08:00
g org.gnome.settings-daemon.plugins.color night-light-enabled            'true'
g org.gnome.settings-daemon.plugins.color night-light-temperature        '3700'
g org.gnome.settings-daemon.plugins.color night-light-schedule-automatic 'false'
g org.gnome.settings-daemon.plugins.color night-light-schedule-from      '18.0'
g org.gnome.settings-daemon.plugins.color night-light-schedule-to        '8.0'

# eyecare toggle: run 'eyecare' to switch day/night
mkdir -p ~/.local/bin
cat > ~/.local/bin/eyecare << 'SCRIPT'
#!/bin/bash
TEMP=$(gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature | tr -d "'")
if [ "$TEMP" -ge 4000 ] 2>/dev/null; then
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature '3000'
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled 'true'
    notify-send "Eye Care" "Night mode — 3000K (warm)" -i weather-clear-night 2>/dev/null || true
    echo "Night mode: 3000K"
else
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature '6500'
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled 'false'
    notify-send "Eye Care" "Day mode — 6500K" -i weather-clear 2>/dev/null || true
    echo "Day mode: 6500K"
fi
SCRIPT
chmod +x ~/.local/bin/eyecare

# Screen power: dim after 10 min idle, sleep after 60 min on AC
g org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout      '3600'
g org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout '900'
g org.gnome.settings-daemon.plugins.power idle-dim                       'true'
g org.gnome.desktop.session                idle-delay                     '600'

echo ""
echo "  Verification:"
check_cmd eyecare
check_gsetting org.gnome.settings-daemon.plugins.color night-light-temperature
info "Run 'eyecare' to toggle day/night mode"
