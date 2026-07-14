#!/bin/bash
# Module 15: Microsoft Edge browser
source "$(dirname "$0")/lib.sh"

section "15 — Microsoft Edge"

if command -v microsoft-edge-stable &>/dev/null; then
    ok "Microsoft Edge already installed: $(microsoft-edge-stable --version 2>/dev/null)"
else
    wget -qO /tmp/ms.gpg https://packages.microsoft.com/keys/microsoft.asc
    sudo install -o root -g root -m 644 /tmp/ms.gpg /etc/apt/trusted.gpg.d/packages.microsoft.gpg
    rm -f /tmp/ms.gpg
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-stable.list'
    sudo apt update -qq || fail "apt update (Edge)"
    apt_install microsoft-edge-stable
fi

echo ""
echo "  Verification:"
check_cmd microsoft-edge-stable
info "Launch: microsoft-edge-stable"
