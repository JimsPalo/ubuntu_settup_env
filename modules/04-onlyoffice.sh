#!/bin/bash
# Module 05: ONLYOFFICE — Word, Excel, PowerPoint replacement
source "$(dirname "$0")/lib.sh"

section "05 — ONLYOFFICE (Office Suite)"

if command -v desktopeditors &>/dev/null; then
    ok "ONLYOFFICE already installed"
else
    sudo mkdir -p /usr/share/keyrings
    sudo gpg --no-default-keyring \
        --keyring /usr/share/keyrings/onlyoffice.gpg \
        --keyserver hkps://keyserver.ubuntu.com \
        --recv-keys CB2DE8E5 2>/dev/null || fail "ONLYOFFICE GPG key"
    echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' \
        | sudo tee /etc/apt/sources.list.d/onlyoffice.list > /dev/null
    sudo apt update -qq || fail "apt update (ONLYOFFICE)"
    apt_install onlyoffice-desktopeditors
fi

echo ""
echo "  Verification:"
check_cmd desktopeditors
check_pkg onlyoffice-desktopeditors
info "Launch: desktopeditors (Word=.docx / Excel=.xlsx / PowerPoint=.pptx)"
