#!/bin/bash
# Module 16: Pomodoro timer (GNOME Pomodoro) — configurable work / short-break /
# long-break durations, with a "pomodoros before long break" setting so multiple
# work sessions chain together before the longer rest period.
source "$(dirname "$0")/lib.sh"

section "16 — Pomodoro Timer"

apt_install gnome-shell-pomodoro

echo ""
echo "  Verification:"
check_cmd gnome-pomodoro
check_pkg gnome-shell-pomodoro
info "Launch: gnome-pomodoro (or search 'Pomodoro' in the app grid)"
info "Preferences let you set work/short-break/long-break lengths and pomodoros-per-long-break"
