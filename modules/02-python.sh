#!/bin/bash
# Module 02: Python 3.12 + pip
source "$(dirname "$0")/lib.sh"

section "02 — Python 3.12"

if python3.12 --version &>/dev/null; then
    ok "Python 3.12 already installed: $(python3.12 --version)"
else
    sudo add-apt-repository -y ppa:deadsnakes/ppa || fail "deadsnakes PPA"
    sudo apt update -qq
    apt_install python3.12 python3.12-dev python3.12-venv python3.12-tk
    # Only alias bare "python" — never repoint /usr/bin/python3 itself.
    # Ubuntu's system tools (gnome-terminal, software-properties-gtk, etc.)
    # have #!/usr/bin/python3 shebangs and need the distro's python3 (3.10),
    # whose compiled python3-gi extension doesn't exist for 3.12.
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 2 2>/dev/null || true
fi

echo ""
echo "  Verification:"
check_cmd python3.12
python3.12 --version && ok "python3.12 version" || fail "python3.12"
