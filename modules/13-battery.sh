#!/bin/bash
# Module 13: Battery charge management — TLP native thresholds
# TLP reads START_CHARGE_THRESH_BAT0 / STOP_CHARGE_THRESH_BAT0 from /etc/tlp.conf
# and enforces them itself on boot, resume, and AC plug/unplug — no custom
# daemon needed. Requires charge-threshold-capable hardware (TLP detects the
# driver automatically); on unsupported hardware the keys are simply ignored.
source "$(dirname "$0")/lib.sh"

section "13 — Battery Health (TLP)"

STOP=60
START=50

apt_install tlp tlp-rdw

sudo systemctl disable power-profiles-daemon 2>/dev/null || true
sudo systemctl mask    power-profiles-daemon 2>/dev/null || true
sudo systemctl enable tlp || fail "enable tlp"

# Remove any stale custom SoC-manager artifacts from earlier versions of this module
sudo systemctl disable --now battery-soc.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/battery-soc.service /usr/local/bin/battery-soc-manager
sudo systemctl daemon-reload 2>/dev/null || true

set_tlp_conf() {
    local key="$1" val="$2" file="/etc/tlp.conf"
    if grep -q "^${key}=" "$file" 2>/dev/null; then
        sudo sed -i "s/^${key}=.*/${key}=${val}/" "$file"
    elif grep -q "^#${key}=" "$file" 2>/dev/null; then
        sudo sed -i "s/^#${key}=.*/${key}=${val}/" "$file"
    else
        echo "${key}=${val}" | sudo tee -a "$file" > /dev/null
    fi
}
set_tlp_conf START_CHARGE_THRESH_BAT0 "$START"
set_tlp_conf STOP_CHARGE_THRESH_BAT0  "$STOP"

sudo systemctl restart tlp || fail "restart tlp"
sudo tlp setcharge "$START" "$STOP" BAT0 2>/dev/null \
    || warn "tlp setcharge (hardware may not support runtime override — reboot to apply via tlp.conf)"

# set-battery-limit <stop> [start] — persist new thresholds via TLP (needs sudo)
sudo tee /usr/local/bin/set-battery-limit > /dev/null << 'SCRIPT'
#!/bin/bash
STOP="${1:-60}"
START="${2:-$((STOP - 10))}"
FILE="/etc/tlp.conf"
set_key() {
    if grep -q "^${1}=" "$FILE" 2>/dev/null; then
        sed -i "s/^${1}=.*/${1}=${2}/" "$FILE"
    elif grep -q "^#${1}=" "$FILE" 2>/dev/null; then
        sed -i "s/^#${1}=.*/${1}=${2}/" "$FILE"
    else
        echo "${1}=${2}" >> "$FILE"
    fi
}
set_key START_CHARGE_THRESH_BAT0 "$START"
set_key STOP_CHARGE_THRESH_BAT0  "$STOP"
systemctl restart tlp
tlp setcharge "$START" "$STOP" BAT0 2>/dev/null || true
echo "Stop threshold : ${STOP}%  (persisted in /etc/tlp.conf)"
echo "Start threshold: ${START}%"
SCRIPT
sudo chmod +x /usr/local/bin/set-battery-limit

# battery-status — reads sysfs + tlp.conf directly (no sudo needed;
# `tlp-stat -b` requires root, which defeats the point of a quick check)
mkdir -p ~/.local/bin
cat > ~/.local/bin/battery-status << 'SCRIPT'
#!/bin/bash
BAT="/sys/class/power_supply/BAT0"
AC="/sys/class/power_supply/AC0"
SOC=$(cat "$BAT/capacity" 2>/dev/null || echo "?")
STATUS=$(cat "$BAT/status" 2>/dev/null || echo "?")
AC_ON=$(cat "$AC/online" 2>/dev/null || echo "?")
CYCLES=$(cat "$BAT/cycle_count" 2>/dev/null || echo "?")
STOP_LIVE=$(cat "$BAT/charge_control_end_threshold" 2>/dev/null || echo "n/a")
START_CFG=$(grep -oP '^START_CHARGE_THRESH_BAT0=\K.*' /etc/tlp.conf 2>/dev/null || echo "?")
STOP_CFG=$(grep -oP '^STOP_CHARGE_THRESH_BAT0=\K.*' /etc/tlp.conf 2>/dev/null || echo "?")
printf "SoC              : %s%%\n" "$SOC"
printf "Status           : %s\n" "$STATUS"
printf "AC online        : %s\n" "$([ "$AC_ON" = "1" ] && echo yes || echo no)"
printf "Stop threshold   : %s%% (hardware, live)\n" "$STOP_LIVE"
printf "Configured range : %s%% - %s%% (TLP, /etc/tlp.conf)\n" "$START_CFG" "$STOP_CFG"
printf "Cycle count      : %s\n" "$CYCLES"
SCRIPT
chmod +x ~/.local/bin/battery-status

echo ""
echo "  Verification:"
check_service tlp
if [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
    ok "TLP charge threshold active: $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold)%"
else
    warn "charge_control_end_threshold not exposed — hardware may not support it"
fi
info "Commands:  battery-status   |   sudo set-battery-limit 60"
