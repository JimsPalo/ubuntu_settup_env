#!/bin/bash
# Module 15: System optimisations
#   - vm.swappiness=10  (16 GB RAM — avoid unnecessary swapping)
#   - vfs_cache_pressure=50  (keep dentries/inodes longer)
#   - NVMe already on 'none' scheduler (optimal)
#   - Weekly SSD TRIM
#   - preload for faster app launch
source "$(dirname "$0")/lib.sh"

section "15 — System Optimisations"

# Kernel tuning
sudo tee /etc/sysctl.d/99-performance.conf > /dev/null << 'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF
sudo sysctl -p /etc/sysctl.d/99-performance.conf || warn "sysctl apply failed"

# Weekly SSD TRIM
sudo systemctl enable fstrim.timer 2>/dev/null || warn "fstrim.timer not found"

# preload — learns which apps you use and preloads them
if ! command -v preload &>/dev/null; then
    apt_install preload || warn "preload not in repos (optional)"
fi

# Remove persistent bloatware (safe set — no dependencies)
BLOAT="gnome-games aisleriot gnome-mahjongg gnome-mines gnome-sudoku \
       transmission-gtk deja-dup whoopsie apport ubuntu-report"
for pkg in $BLOAT; do
    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" \
        && sudo apt remove --purge -y "$pkg" 2>/dev/null \
        || true
done

sudo apt autoremove -y 2>/dev/null || true
sudo apt clean 2>/dev/null || true

echo ""
echo "  Verification:"
SWAP=$(cat /proc/sys/vm/swappiness)
[ "$SWAP" -le 10 ] && ok "vm.swappiness=$SWAP" || warn "vm.swappiness=$SWAP (expected 10)"
CACHE=$(cat /proc/sys/vm/vfs_cache_pressure)
ok "vfs_cache_pressure=$CACHE"
NVMe=$(cat /sys/block/nvme0n1/queue/scheduler 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' || echo "N/A")
info "NVMe I/O scheduler: $NVMe"
systemctl is-enabled fstrim.timer &>/dev/null && ok "fstrim.timer enabled" || warn "fstrim.timer disabled"
