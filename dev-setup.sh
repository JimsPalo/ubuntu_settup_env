#!/bin/bash
set -e

ERROR_LOG="$HOME/setup-errors.log"
> "$ERROR_LOG"

echo "========================================"
echo "UBUNTU 22.04 DEVELOPER SETUP"
echo "Python 3.12 for PyTorch compatibility"
echo "========================================"

echo ""
echo "=== SECTION 1: Remove Firefox & Snap ==="
{
    sudo snap remove --purge firefox || echo "FAIL: snap remove firefox" >> "$ERROR_LOG"
    sudo snap remove --purge snap-store || echo "FAIL: snap remove snap-store" >> "$ERROR_LOG"
    sudo snap remove --purge gtk-common-themes || echo "FAIL: snap remove gtk-common-themes" >> "$ERROR_LOG"
    sudo snap remove --purge snapd-desktop-integration || echo "FAIL: snap remove snapd-desktop-integration" >> "$ERROR_LOG"
    sudo snap remove --purge gnome-3-38-2004 || echo "FAIL: snap remove gnome-3-38-2004" >> "$ERROR_LOG"
    sudo snap remove --purge gnome-42-2204 || echo "FAIL: snap remove gnome-42-2204" >> "$ERROR_LOG"
    sudo snap remove --purge core20 || echo "FAIL: snap remove core20" >> "$ERROR_LOG"
    sudo snap remove --purge core22 || echo "FAIL: snap remove core22" >> "$ERROR_LOG"
    sudo snap remove --purge bare || echo "FAIL: snap remove bare" >> "$ERROR_LOG"
    sudo snap remove --purge snapd || echo "FAIL: snap remove snapd" >> "$ERROR_LOG"
    sudo apt autoremove --purge -y snapd || echo "FAIL: apt remove snapd" >> "$ERROR_LOG"
    sudo apt-mark hold snapd || echo "FAIL: apt-mark hold snapd" >> "$ERROR_LOG"
    sudo rm -rf /var/cache/snapd/ /var/lib/snapd/ /var/snap/ /snap/
    rm -rf ~/snap
    sudo sh -c 'cat > /etc/apt/preferences.d/nosnap.pref << EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF'
} || echo "FAIL: Section 1 - Snap removal" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 2: Update & Essentials ==="
{
    sudo apt update || echo "FAIL: apt update" >> "$ERROR_LOG"
    sudo apt upgrade -y || echo "FAIL: apt upgrade" >> "$ERROR_LOG"
    sudo apt install -y curl wget git software-properties-common || echo "FAIL: apt install basics" >> "$ERROR_LOG"
} || echo "FAIL: Section 2 - Basics" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 3: Install Python 3.12 (Stable for PyTorch) ==="
{
    sudo add-apt-repository -y ppa:deadsnakes/ppa || echo "FAIL: add deadsnakes PPA" >> "$ERROR_LOG"
    sudo apt update || echo "FAIL: apt update (deadsnakes)" >> "$ERROR_LOG"
    sudo apt install -y python3.12 python3.12-dev python3.12-venv python3.12-distutils python3.12-gdbm python3.12-tk python3.12-lib2to3 || echo "FAIL: apt install python3.12" >> "$ERROR_LOG"
    
    # Set python3.12 as default
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 2 || echo "FAIL: update-alternatives python" >> "$ERROR_LOG"
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2 || echo "FAIL: update-alternatives python3" >> "$ERROR_LOG"
    
    # Install pip for Python 3.12
    curl https://bootstrap.pypa.io/get-pip.py | sudo python3.12 || echo "FAIL: install pip for python3.12" >> "$ERROR_LOG"
    
    python3.12 --version || echo "FAIL: python3.12 version check" >> "$ERROR_LOG"
} || echo "FAIL: Section 3 - Python 3.12" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 4: Install PyTorch (Stable) ==="
{
    # Install PyTorch with CPU support (stable, works on all systems)
    # For CUDA support, change to: https://download.pytorch.org/whl/cu126
    python3.12 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu || echo "FAIL: pip install torch" >> "$ERROR_LOG"
    
    # Verify PyTorch
    python3.12 -c "import torch; print('PyTorch OK:', torch.__version__)" || echo "FAIL: PyTorch import test" >> "$ERROR_LOG"
    
    # Install common ML/data science packages
    python3.12 -m pip install numpy scipy pandas matplotlib scikit-learn jupyter || echo "FAIL: pip install data science packages" >> "$ERROR_LOG"
} || echo "FAIL: Section 4 - PyTorch" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 5: Install VS Code ==="
{
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg || echo "FAIL: download VS Code key" >> "$ERROR_LOG"
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ || echo "FAIL: install VS Code key" >> "$ERROR_LOG"
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' || echo "FAIL: add VS Code repo" >> "$ERROR_LOG"
    rm -f packages.microsoft.gpg
    sudo apt update || echo "FAIL: apt update (VS Code)" >> "$ERROR_LOG"
    sudo apt install -y code || echo "FAIL: apt install code" >> "$ERROR_LOG"
} || echo "FAIL: Section 5 - VS Code" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 6: Install ONLYOFFICE ==="
{
    sudo mkdir -p /usr/share/keyrings || echo "FAIL: mkdir keyrings" >> "$ERROR_LOG"
    sudo gpg --no-default-keyring --keyring /usr/share/keyrings/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5 || echo "FAIL: ONLYOFFICE GPG key" >> "$ERROR_LOG"
    echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee /etc/apt/sources.list.d/onlyoffice.list || echo "FAIL: ONLYOFFICE repo" >> "$ERROR_LOG"
    sudo apt update || echo "FAIL: apt update (ONLYOFFICE)" >> "$ERROR_LOG"
    sudo apt install -y onlyoffice-desktopeditors || echo "FAIL: apt install onlyoffice" >> "$ERROR_LOG"
} || echo "FAIL: Section 6 - ONLYOFFICE" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 7: Install Google Drive (Rclone) ==="
{
    sudo -v
    curl https://rclone.org/install.sh | sudo bash || echo "FAIL: rclone install" >> "$ERROR_LOG"
    mkdir -p ~/GoogleDrive || echo "FAIL: mkdir GoogleDrive" >> "$ERROR_LOG"
    sudo sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf || echo "FAIL: fuse.conf edit" >> "$ERROR_LOG"
} || echo "FAIL: Section 7 - Rclone" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 8: Git ==="
{
    git config --global init.defaultBranch main || echo "FAIL: git config defaultBranch" >> "$ERROR_LOG"
    git config --global core.editor "code --wait" || echo "FAIL: git config editor" >> "$ERROR_LOG"
    git config --global merge.tool vscode || echo "FAIL: git config merge.tool" >> "$ERROR_LOG"
    git config --global mergetool.vscode.cmd "code --wait \$MERGED" || echo "FAIL: git config mergetool" >> "$ERROR_LOG"
    git config --global diff.tool vscode || echo "FAIL: git config diff.tool" >> "$ERROR_LOG"
    git config --global difftool.vscode.cmd "code --wait --diff \$LOCAL \$REMOTE" || echo "FAIL: git config difftool" >> "$ERROR_LOG"
    git config --global alias.st status || echo "FAIL: git alias st" >> "$ERROR_LOG"
    git config --global alias.co checkout || echo "FAIL: git alias co" >> "$ERROR_LOG"
    git config --global alias.br branch || echo "FAIL: git alias br" >> "$ERROR_LOG"
    git config --global alias.ci commit || echo "FAIL: git alias ci" >> "$ERROR_LOG"
    git config --global core.pager cat || echo "FAIL: git pager" >> "$ERROR_LOG"
} || echo "FAIL: Section 8 - Git" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 9: Python 3.12 venv Shortcut ==="
{
    mkdir -p ~/.local/bin || echo "FAIL: mkdir ~/.local/bin" >> "$ERROR_LOG"
    cat > ~/.local/bin/mkvenv << 'EOF'
#!/bin/bash
python3.12 -m venv .venv && source .venv/bin/activate && pip install --upgrade pip
EOF
    chmod +x ~/.local/bin/mkvenv || echo "FAIL: chmod mkvenv" >> "$ERROR_LOG"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc || echo "FAIL: add PATH to bashrc" >> "$ERROR_LOG"
} || echo "FAIL: Section 9 - Python venv" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 10-15: Theme & Interface ==="
{
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' || echo "FAIL: gtk-theme" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || echo "FAIL: color-scheme" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark' || echo "FAIL: icon-theme" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.interface cursor-theme 'Yaru' || echo "FAIL: cursor-theme" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.background picture-uri '' || echo "FAIL: background picture" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.background primary-color '#0d0d0d' || echo "FAIL: background primary" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.background secondary-color '#0d0d0d' || echo "FAIL: background secondary" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.background color-shading-type 'solid' || echo "FAIL: background shading" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.user-theme name 'Adwaita-dark' || echo "FAIL: user-theme" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' || echo "FAIL: dock-position" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed 'true' || echo "FAIL: dock-fixed" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height 'false' || echo "FAIL: extend-height" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size '32' || echo "FAIL: dash-max-icon-size" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top 'false' || echo "FAIL: show-apps-at-top" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize-or-previews' || echo "FAIL: click-action" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces 'true' || echo "FAIL: isolate-workspaces" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock show-trash 'false' || echo "FAIL: show-trash" >> "$ERROR_LOG"
    gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts 'false' || echo "FAIL: show-mounts" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']" || echo "FAIL: workspace-1" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']" || echo "FAIL: workspace-2" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']" || echo "FAIL: workspace-3" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']" || echo "FAIL: workspace-4" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>1']" || echo "FAIL: move-workspace-1" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']" || echo "FAIL: move-workspace-2" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']" || echo "FAIL: move-workspace-3" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Super><Shift>4']" || echo "FAIL: move-workspace-4" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>m']" || echo "FAIL: toggle-maximized" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']" || echo "FAIL: close" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>t']" || echo "FAIL: terminal key" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']" || echo "FAIL: home key" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.preferences focus-mode 'sloppy' || echo "FAIL: focus-mode" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.preferences auto-raise 'false' || echo "FAIL: auto-raise" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' || echo "FAIL: button-layout" >> "$ERROR_LOG"
    gsettings set org.gnome.mutter edge-tiling 'true' || echo "FAIL: edge-tiling" >> "$ERROR_LOG"
    gsettings set org.gnome.mutter attach-modal-dialogs 'false' || echo "FAIL: attach-modal-dialogs" >> "$ERROR_LOG"
    gsettings set org.gnome.mutter workspaces-only-on-primary 'true' || echo "FAIL: workspaces-only-on-primary" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.wm.preferences num-workspaces '4' || echo "FAIL: num-workspaces" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click 'true' || echo "FAIL: tap-to-click" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll 'true' || echo "FAIL: touchpad natural-scroll" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.peripherals.touchpad speed '0.4' || echo "FAIL: touchpad speed" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll 'true' || echo "FAIL: mouse natural-scroll" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat' || echo "FAIL: mouse accel-profile" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.interface enable-animations 'false' || echo "FAIL: enable-animations" >> "$ERROR_LOG"
} || echo "FAIL: Section 10-15 - Theme & Interface" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 16: BLUE LIGHT FILTER (Eye Health) ==="
{
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled 'true' || echo "FAIL: night-light-enabled" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature '3000' || echo "FAIL: night-light-temperature" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic 'false' || echo "FAIL: night-light-schedule-automatic" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from '18.0' || echo "FAIL: night-light-schedule-from" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to '08.0' || echo "FAIL: night-light-schedule-to" >> "$ERROR_LOG"
    
    mkdir -p ~/.config/redshift || echo "FAIL: mkdir redshift config" >> "$ERROR_LOG"
    cat > ~/.config/redshift/redshift.conf << 'EOF'
[redshift]
temp-day=4500
temp-night=3000
transition=1
gamma=0.8:0.8:0.8
location-provider=manual
adjustment-method=randr
[manual]
lat=-26.2
lon=28.0
EOF
    
    mkdir -p ~/.local/bin || echo "FAIL: mkdir ~/.local/bin (eyecare)" >> "$ERROR_LOG"
    cat > ~/.local/bin/eyecare << 'EOF'
#!/bin/bash
CURRENT=$(gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature | tr -d "'")
if [ "$CURRENT" = "3000" ]; then
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature '4500'
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled 'false'
    notify-send "Eye Care" "Day mode activated (4500K)" -i weather-clear
else
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature '3000'
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled 'true'
    notify-send "Eye Care" "Night mode activated (3000K) - Blue light reduced" -i weather-clear-night
fi
EOF
    chmod +x ~/.local/bin/eyecare || echo "FAIL: chmod eyecare" >> "$ERROR_LOG"
} || echo "FAIL: Section 16 - Blue Light Filter" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 17: Battery Health (60% Limit) ==="
{
    sudo apt install -y tlp tlp-rdw || echo "FAIL: apt install tlp" >> "$ERROR_LOG"
    sudo systemctl stop power-profiles-daemon || echo "FAIL: stop power-profiles-daemon" >> "$ERROR_LOG"
    sudo systemctl disable power-profiles-daemon || echo "FAIL: disable power-profiles-daemon" >> "$ERROR_LOG"
    sudo systemctl mask power-profiles-daemon || echo "FAIL: mask power-profiles-daemon" >> "$ERROR_LOG"
    sudo systemctl enable tlp || echo "FAIL: enable tlp" >> "$ERROR_LOG"
    sudo systemctl start tlp || echo "FAIL: start tlp" >> "$ERROR_LOG"
    
    sudo sh -c 'cat > /usr/local/bin/set-battery-threshold << EOF
#!/bin/bash
BAT_PATH="/sys/class/power_supply/BAT0"
if [ -f "$BAT_PATH/charge_control_end_threshold" ]; then
    echo 60 > $BAT_PATH/charge_control_end_threshold
    echo 40 > $BAT_PATH/charge_control_start_threshold
    echo "Battery threshold set: 40%-60%"
elif [ -f "$BAT_PATH/charge_stop_threshold" ]; then
    echo 60 > $BAT_PATH/charge_stop_threshold
    echo 40 > $BAT_PATH/charge_start_threshold
    echo "Battery threshold set (legacy): 40%-60%"
else
    echo "Battery threshold control not available on this hardware"
fi
EOF'
    chmod +x /usr/local/bin/set-battery-threshold || echo "FAIL: chmod set-battery-threshold" >> "$ERROR_LOG"
    
    sudo sh -c 'cat > /etc/systemd/system/battery-threshold.service << EOF
[Unit]
Description=Set Battery Charge Thresholds
After=multi-user.target
StartLimitBurst=0
[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-battery-threshold
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF'
    sudo systemctl daemon-reload || echo "FAIL: daemon-reload" >> "$ERROR_LOG"
    sudo systemctl enable battery-threshold.service || echo "FAIL: enable battery-threshold" >> "$ERROR_LOG"
    sudo systemctl start battery-threshold.service || echo "FAIL: start battery-threshold" >> "$ERROR_LOG"
} || echo "FAIL: Section 17 - Battery Health" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 18: Screen Power ==="
{
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout '3600' || echo "FAIL: sleep-inactive-ac-timeout" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout '1800' || echo "FAIL: sleep-inactive-battery-timeout" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.power idle-dim 'true' || echo "FAIL: idle-dim" >> "$ERROR_LOG"
    gsettings set org.gnome.desktop.session idle-delay '600' || echo "FAIL: idle-delay" >> "$ERROR_LOG"
    gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled 'true' || echo "FAIL: ambient-enabled" >> "$ERROR_LOG"
} || echo "FAIL: Section 18 - Screen Power" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 19: Context Menu ==="
{
    mkdir -p ~/Templates || echo "FAIL: mkdir Templates" >> "$ERROR_LOG"
    touch ~/Templates/Text\ Document.txt || echo "FAIL: touch Text Document" >> "$ERROR_LOG"
    xdg-mime default micro.desktop text/plain || echo "FAIL: xdg-mime default" >> "$ERROR_LOG"
    sudo sh -c 'cat > /usr/share/applications/micro.desktop << EOF
[Desktop Entry]
Name=Micro
Comment=Modern and intuitive terminal-based text editor
Exec=micro %F
Terminal=true
Type=Application
Icon=utilities-terminal
Categories=Utility;TextEditor;
MimeType=text/plain;
EOF'
    sudo update-desktop-database || echo "FAIL: update-desktop-database" >> "$ERROR_LOG"
    nautilus -q || echo "FAIL: nautilus restart" >> "$ERROR_LOG"
} || echo "FAIL: Section 19 - Context Menu" >> "$ERROR_LOG"

echo ""
echo "=== SECTION 20: VS Code CLI & Final PATH ==="
{
    echo 'export PATH="/usr/share/code/bin:$PATH"' >> ~/.bashrc || echo "FAIL: add PATH" >> "$ERROR_LOG"
    sudo apt autoremove --purge -y || echo "FAIL: apt autoremove" >> "$ERROR_LOG"
    sudo apt clean || echo "FAIL: apt clean" >> "$ERROR_LOG"
    sudo apt autoclean || echo "FAIL: apt autoclean" >> "$ERROR_LOG"
    sudo fstrim -v / || echo "FAIL: fstrim" >> "$ERROR_LOG"
} || echo "FAIL: Section 20 - Cleanup" >> "$ERROR_LOG"

echo ""
echo "========================================"
echo "SETUP COMPLETE - GENERATING REPORT"
echo "========================================"

# ========================================
# ERROR REPORTING SECTION
# ========================================

echo ""
echo "=== VERIFYING ALL INSTALLATIONS ==="

check_cmd() {
    if command -v "$1" &> /dev/null; then
        echo "  [OK] $1: $(command -v "$1")"
    else
        echo "  [FAIL] $1: NOT FOUND" | tee -a "$ERROR_LOG"
    fi
}

check_pkg() {
    if dpkg -l | grep -q "^ii  $1 "; then
        echo "  [OK] Package $1: INSTALLED"
    else
        echo "  [FAIL] Package $1: NOT INSTALLED" | tee -a "$ERROR_LOG"
    fi
}

check_gsettings() {
    local schema="$1"
    local key="$2"
    local expected="$3"
    local current
    current=$(gsettings get "$schema" "$key" 2>/dev/null || echo "ERROR")
    if [ "$current" = "$expected" ]; then
        echo "  [OK] $schema $key: $current"
    else
        echo "  [FAIL] $schema $key: $current (expected $expected)" | tee -a "$ERROR_LOG"
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo "  [OK] File $1: EXISTS"
    else
        echo "  [FAIL] File $1: NOT FOUND" | tee -a "$ERROR_LOG"
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo "  [OK] Directory $1: EXISTS"
    else
        echo "  [FAIL] Directory $1: NOT FOUND" | tee -a "$ERROR_LOG"
    fi
}

check_service() {
    if systemctl is-enabled "$1" &>/dev/null; then
        echo "  [OK] Service $1: ENABLED"
    else
        echo "  [FAIL] Service $1: NOT ENABLED" | tee -a "$ERROR_LOG"
    fi
}

echo ""
echo "--- Python Versions ---"
check_cmd python3.12
check_cmd python3
python3.12 --version 2>/dev/null || echo "  [FAIL] python3.12 version" | tee -a "$ERROR_LOG"
python3 --version 2>/dev/null || echo "  [FAIL] python3 version" | tee -a "$ERROR_LOG"

echo ""
echo "--- PyTorch Check ---"
python3.12 -c "import torch; print('  [OK] PyTorch:', torch.__version__)" 2>/dev/null || echo "  [FAIL] PyTorch import" | tee -a "$ERROR_LOG"

echo ""
echo "--- Applications ---"
check_cmd code
check_cmd git
check_cmd node
check_cmd npm
check_cmd micro
check_cmd htop
check_cmd neofetch
check_cmd rclone
check_cmd desktopeditors
check_cmd redshift
check_cmd eyecare
check_cmd mkvenv

echo ""
echo "--- Packages ---"
check_pkg code
check_pkg git
check_pkg python3.12
check_pkg python3.12-dev
check_pkg python3.12-venv
check_pkg nodejs
check_pkg npm
check_pkg micro
check_pkg htop
check_pkg neofetch
check_pkg gnome-tweaks
check_pkg gnome-shell-extensions
check_pkg dconf-editor
check_pkg fuse3
check_pkg redshift
check_pkg tlp
check_pkg tlp-rdw
check_pkg onlyoffice-desktopeditors

echo ""
echo "--- Configuration Files ---"
check_file ~/.bashrc
check_file ~/.config/redshift/redshift.conf
check_file ~/.local/bin/mkvenv
check_file ~/.local/bin/eyecare
check_file /usr/local/bin/set-battery-threshold
check_file /etc/systemd/system/battery-threshold.service
check_file /usr/share/applications/micro.desktop
check_file /etc/apt/preferences.d/nosnap.pref
check_file /etc/apt/sources.list.d/vscode.list
check_file /etc/apt/sources.list.d/onlyoffice.list
check_file ~/Templates/Text\ Document.txt

echo ""
echo "--- Directories ---"
check_dir ~/GoogleDrive
check_dir ~/.local/bin
check_dir ~/.config/redshift
check_dir ~/Templates

echo ""
echo "--- GNOME Settings ---"
check_gsettings org.gnome.desktop.interface gtk-theme "'Adwaita-dark'"
check_gsettings org.gnome.desktop.interface color-scheme "'prefer-dark'"
check_gsettings org.gnome.desktop.interface icon-theme "'Yaru-dark'"
check_gsettings org.gnome.desktop.interface enable-animations "false"
check_gsettings org.gnome.settings-daemon.plugins.color night-light-enabled "true"
check_gsettings org.gnome.settings-daemon.plugins.color night-light-temperature "3000"
check_gsettings org.gnome.desktop.wm.preferences num-workspaces "4"
check_gsettings org.gnome.desktop.peripherals.touchpad tap-to-click "true"

echo ""
echo "--- Services ---"
check_service tlp
check_service battery-threshold

echo ""
echo "--- Battery Threshold ---"
if [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
    echo "  [OK] Battery end threshold: $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold)%"
elif [ -f /sys/class/power_supply/BAT0/charge_stop_threshold ]; then
    echo "  [OK] Battery stop threshold (legacy): $(cat /sys/class/power_supply/BAT0/charge_stop_threshold)%"
else
    echo "  [FAIL] Battery threshold: NOT AVAILABLE" | tee -a "$ERROR_LOG"
fi

echo ""
echo "--- Snap Status ---"
if command -v snap &> /dev/null; then
    echo "  [WARN] snap command still exists: $(command -v snap)"
    echo "  [INFO] Installed snaps: $(snap list 2>/dev/null | wc -l) packages"
else
    echo "  [OK] snap: REMOVED"
fi

echo ""
echo "--- Git Config ---"
git config --global --list 2>/dev/null | grep -E "(init.defaultBranch|core.editor|merge.tool|diff.tool|alias)" | while read line; do
    echo "  [OK] $line"
done

echo ""
echo "========================================"
echo "ERROR REPORT"
echo "========================================"

if [ -s "$ERROR_LOG" ]; then
    echo ""
    echo "The following errors were detected:"
    echo "-----------------------------------"
    cat "$ERROR_LOG"
    echo ""
    echo "Total errors: $(wc -l < "$ERROR_LOG")"
    echo ""
    echo "Error log saved to: $ERROR_LOG"
else
    echo ""
    echo "  [SUCCESS] No errors detected!"
    echo "  All components installed and configured successfully."
fi

echo ""
echo "========================================"
echo "PYTORCH USAGE"
echo "========================================"
echo ""
echo "Default Python: python3.12"
echo "Create venv:    mkvenv (uses python3.12)"
echo "Install packages: python3.12 -m pip install <package>"
echo ""
echo "PyTorch test:"
echo "  python3.12 -c \"import torch; print(torch.__version__)\""
echo ""
echo "For CUDA support (if you have NVIDIA GPU):"
echo "  python3.12 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126"

echo ""
echo "========================================"
echo "NEXT STEPS"
echo "========================================"
echo ""
echo "1. Reboot: sudo reboot"
echo ""
echo "2. After reboot, configure Google Drive:"
echo "   rclone config"
echo ""
echo "3. Then create and enable the mount service:"
echo "   sudo systemctl enable --now rclone-gdrive.service"
echo ""
echo "4. Quick commands:"
echo "   python3.12      - Python 3.12 (PyTorch compatible)"
echo "   python3          - Python 3.12 (default)"
echo "   mkvenv           - Create Python 3.12 virtual environment"
echo "   eyecare          - Toggle Day/Night eye care mode"
echo "   code             - Launch VS Code"
echo "   desktopeditors   - Launch ONLYOFFICE"
echo ""
echo "5. Keyboard shortcuts:"
echo "   Super+1/2/3/4     - Switch workspaces"
echo "   Super+Shift+1/2/3/4 - Move window to workspace"
echo "   Super+T           - Terminal"
echo "   Super+M           - Maximize window"
echo "   Super+Q           - Close window"
echo "   Super+E           - File manager"
echo ""
echo "========================================"
