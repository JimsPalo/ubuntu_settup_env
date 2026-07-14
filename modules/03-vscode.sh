#!/bin/bash
# Module 04: VS Code + Git config
source "$(dirname "$0")/lib.sh"

section "04 — VS Code"

if command -v code &>/dev/null; then
    ok "VS Code already installed: $(code --version | head -1)"
else
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor > /tmp/ms.gpg
    sudo install -o root -g root -m 644 /tmp/ms.gpg /etc/apt/trusted.gpg.d/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f /tmp/ms.gpg
    sudo apt update -qq || fail "apt update (VS Code)"
    apt_install code
fi

# Git config
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global core.pager cat

echo ""
echo "  Verification:"
check_cmd code
check_cmd git
ok "git default branch: $(git config --global init.defaultBranch)"
