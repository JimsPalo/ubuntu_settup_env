#!/bin/bash
# Shared library — source this in every module

ERROR_LOG="${ERROR_LOG:-$HOME/setup-errors.log}"

ok()   { echo "  [OK]   $*"; }
fail() { echo "  [FAIL] $*" | tee -a "$ERROR_LOG"; }
info() { echo "  [INFO] $*"; }
warn() { echo "  [WARN] $*"; }

check_cmd() {
    if command -v "$1" &>/dev/null; then
        ok "$1 → $(command -v "$1")"
        return 0
    else
        fail "$1 not found"
        return 1
    fi
}

check_pkg() {
    if dpkg -l "$1" 2>/dev/null | grep -q "^ii"; then
        ok "pkg: $1"
        return 0
    else
        fail "pkg: $1 not installed"
        return 1
    fi
}

check_file() {
    if [ -f "$1" ]; then
        ok "file: $1"
        return 0
    else
        fail "file: $1 missing"
        return 1
    fi
}

check_service() {
    if systemctl is-enabled "$1" &>/dev/null; then
        ok "service: $1 enabled"
        return 0
    else
        warn "service: $1 not enabled"
        return 1
    fi
}

check_gsetting() {
    local val
    val=$(gsettings get "$1" "$2" 2>/dev/null || echo "ERROR")
    info "gsetting $2 = $val"
}

apt_install() {
    sudo apt install -y "$@" || fail "apt install $*"
}

section() {
    echo ""
    echo "━━━ $* ━━━"
}
