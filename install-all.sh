#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# UBUNTU 22.04 — MASTER INSTALLER
# Runs all modules in order. Each module is self-contained and
# idempotent (safe to re-run if something failed).
#
# Prerequisites: run install-packages.sh first (with sudo)
# Usage:         bash install-all.sh
# ═══════════════════════════════════════════════════════════════

MODULES_DIR="$(dirname "$0")/modules"
ERROR_LOG="$HOME/setup-errors.log"
PASS=0
FAIL=0

> "$ERROR_LOG"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║      UBUNTU 22.04 COMPLETE SETUP             ║"
echo "║      $(date '+%Y-%m-%d %H:%M')                        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

run_module() {
    local script="$MODULES_DIR/$1"
    local name="$2"

    if [ ! -f "$script" ]; then
        echo "  [SKIP] $name — file not found"
        return
    fi

    echo ""
    echo "┌─────────────────────────────────────────────"
    echo "│  $name"
    echo "└─────────────────────────────────────────────"

    if bash "$script" 2>&1; then
        PASS=$((PASS + 1))
        echo "  ✓ done"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ errors logged → $ERROR_LOG"
        echo "MODULE FAILED: $name" >> "$ERROR_LOG"
    fi
}

# ── Dependency order ──────────────────────────────────────────────
# 01-03: Core tools and runtimes
run_module "01-essentials.sh"    "01 Essentials (apt tools, flameshot)"
run_module "02-python.sh"        "02 Python 3.12"
run_module "03-vscode.sh"        "03 VS Code & Git config"
# 04-07: Applications
run_module "04-onlyoffice.sh"    "04 ONLYOFFICE (Word / Excel / PowerPoint)"
run_module "05-pdf-editor.sh"    "05 PDF Editor — Sejda (online, real text editing)"
run_module "06-clipboard.sh"     "06 Clipboard — CopyQ (Ctrl+Super+V)"
run_module "07-google-drive.sh"  "07 Google Drive (rclone auto-mount)"
# 08-11: Input and UI
run_module "08-gestures.sh"      "08 3-Finger Gestures (touchegg, X11)"
run_module "09-dock.sh"          "09 Dock (floating, intellihide)"
run_module "10-shortcuts.sh"     "10 Keyboard Shortcuts (Windows-style)"
run_module "11-theme.sh"         "11 Theme, Fonts & Touchpad"
# 12-14: System services
run_module "12-eyecare.sh"       "12 Eye Care (blue light filter)"
run_module "13-battery.sh"       "13 Battery Health (TLP)"
run_module "14-optimise.sh"      "14 System Optimisations (kernel tuning)"
# 15-16: Extra applications
run_module "15-browser.sh"       "15 Microsoft Edge"
run_module "16-pomodoro.sh"      "16 Pomodoro Timer"

# ── Final cleanup ─────────────────────────────────────────────────
echo ""
echo "┌─────────────────────────────────────────────"
echo "│  Final cleanup"
echo "└─────────────────────────────────────────────"
sudo apt autoremove --purge -y 2>/dev/null || true
sudo apt clean 2>/dev/null || true
sudo fstrim -v / 2>/dev/null | head -2 || true
echo "  ✓ done"

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  SETUP COMPLETE                              ║"
printf "║  Modules: %2d passed  %2d failed              ║\n" "$PASS" "$FAIL"
echo "╚══════════════════════════════════════════════╝"
echo ""

echo "━━━ KEYBOARD SHORTCUTS ━━━"
echo "  Alt+F4          → Close window"
echo "  Alt+Tab         → Switch windows (all, Windows-style)"
echo "  Super+Up/Down   → Maximize / Minimize"
echo "  Super+Left/Right→ Snap window to side"
echo "  Super+L         → Lock screen"
echo "  Super+E         → File manager (Nautilus)"
echo "  Super+T         → Terminal"
echo "  Super+I         → Settings"
echo "  Super+A         → Show all apps"
echo "  Super+Tab       → Window overview"
echo "  Ctrl+Super+V    → Clipboard history picker (CopyQ)"
echo "  Print           → Screenshot — Flameshot (annotate, copy, save)"
echo "  Shift+Super+S   → Screenshot region (select area)"
echo "  Ctrl+Shift+S    → Screenshot region (select area)"
echo "  Ctrl+Alt+←/→    → Switch workspace"
echo ""
echo "━━━ TOUCHPAD GESTURES ━━━"
echo "  3-finger TAP    → Show Applications grid"
echo "  3-finger LEFT   → Cycle forward through windows (hold to keep cycling)"
echo "  3-finger RIGHT  → Cycle backward through windows"
echo "  3-finger DOWN   → Minimize ALL windows (show desktop)"
echo "  3-finger UP     → Window overview"
echo "  4-finger L/R    → Switch workspace"
echo "  4-finger UP     → Maximize/restore current window"
echo "  4-finger DOWN   → Minimize current window"
echo "  4-finger PINCH IN  → Show desktop"
echo "  4-finger PINCH OUT → Window overview"
echo "  Fine-tune anytime in the Touché app (flatpak run com.github.joseexposito.touche)"
echo ""
echo "━━━ APPS ━━━"
echo "  desktopeditors       → ONLYOFFICE (Word / Excel / PowerPoint)"
echo "  PDF Editor           → Sejda online (edit text, fill forms, sign, merge)"
echo "  copyq toggle         → Clipboard manager popup"
echo "  eyecare              → Toggle day/night blue light filter"
echo "  gdrive-mount         → Mount Google Drive at ~/GoogleDrive"
echo "  gdrive-status        → Google Drive connection status"
echo "  microsoft-edge-stable → Microsoft Edge browser"
echo "  gnome-pomodoro       → Pomodoro timer (multi-session work/break cycles)"
echo ""
echo "━━━ NEXT STEPS ━━━"
echo "  1. Configure Google Drive (if needed):"
echo "       rclone config   # name it 'gdrive', choose Google Drive"
echo "       systemctl --user enable --now rclone-gdrive.service"
echo ""
echo "  2. Reboot to apply all changes:"
echo "       sudo reboot"
echo ""

if [ -s "$ERROR_LOG" ]; then
    echo "━━━ ERRORS ━━━"
    cat "$ERROR_LOG"
    echo ""
    echo "Full log: $ERROR_LOG"
fi
