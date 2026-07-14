#!/bin/bash
# Module 08: Google Drive via rclone (auto-mount on login)
source "$(dirname "$0")/lib.sh"

section "08 — Google Drive (rclone)"

# Install rclone
if command -v rclone &>/dev/null; then
    ok "rclone already installed: $(rclone --version | head -1)"
else
    curl https://rclone.org/install.sh | sudo bash || fail "rclone install"
fi

# fuse3 is installed by 01-essentials; just ensure user_allow_other is set
if grep -q "^#user_allow_other" /etc/fuse.conf 2>/dev/null; then
    sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
elif ! grep -q "^user_allow_other" /etc/fuse.conf 2>/dev/null; then
    echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
fi

# Mount point
mkdir -p ~/GoogleDrive

# Systemd user service
mkdir -p ~/.config/systemd/user ~/.local/log
cat > ~/.config/systemd/user/rclone-gdrive.service << 'EOF'
[Unit]
Description=Google Drive (rclone)
After=network-online.target graphical-session.target
Wants=network-online.target

[Service]
Type=notify
ExecStartPre=/bin/sleep 5
ExecStart=rclone mount gdrive: %h/GoogleDrive \
    --vfs-cache-mode full \
    --vfs-cache-max-size 20G \
    --vfs-cache-max-age 168h \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 256M \
    --buffer-size 64M \
    --dir-cache-time 1h \
    --poll-interval 30s \
    --allow-other \
    --log-level INFO \
    --log-file=%h/.local/log/rclone-gdrive.log
ExecStop=/bin/fusermount3 -u %h/GoogleDrive
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload 2>/dev/null || true
loginctl enable-linger "$USER" 2>/dev/null || true

# Nautilus sidebar bookmark
BOOKMARKS="$HOME/.config/gtk-3.0/bookmarks"
mkdir -p "$(dirname "$BOOKMARKS")"
grep -q "GoogleDrive" "$BOOKMARKS" 2>/dev/null \
    || echo "file://$HOME/GoogleDrive Google Drive" >> "$BOOKMARKS"

# Desktop launcher
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/google-drive.desktop << EOF
[Desktop Entry]
Name=Google Drive
Comment=Browse your Google Drive
Exec=nautilus $HOME/GoogleDrive
Icon=folder-remote
Type=Application
Categories=Network;FileManager;
Keywords=google;drive;cloud;
EOF
update-desktop-database ~/.local/share/applications 2>/dev/null || true

# Helper commands
mkdir -p ~/.local/bin

cat > ~/.local/bin/gdrive-mount << 'SCRIPT'
#!/bin/bash
echo "Mounting Google Drive..."
systemctl --user start rclone-gdrive.service
sleep 3
if mountpoint -q ~/GoogleDrive; then
    echo "  Mounted at ~/GoogleDrive"
    notify-send "Google Drive" "Mounted at ~/GoogleDrive" -i folder-remote 2>/dev/null || true
else
    echo "  Mount in progress — check: gdrive-status"
fi
SCRIPT
chmod +x ~/.local/bin/gdrive-mount

cat > ~/.local/bin/gdrive-unmount << 'SCRIPT'
#!/bin/bash
echo "Unmounting Google Drive..."
systemctl --user stop rclone-gdrive.service
sleep 1
if ! mountpoint -q ~/GoogleDrive; then
    echo "  Unmounted successfully"
    notify-send "Google Drive" "Unmounted" -i folder-remote 2>/dev/null || true
else
    echo "  Forcing unmount..."
    fusermount3 -u ~/GoogleDrive 2>/dev/null || fusermount -u ~/GoogleDrive 2>/dev/null || true
fi
SCRIPT
chmod +x ~/.local/bin/gdrive-unmount

cat > ~/.local/bin/gdrive-status << 'SCRIPT'
#!/bin/bash
echo "════════════════════════════════════"
echo "  GOOGLE DRIVE STATUS"
echo "════════════════════════════════════"
if mountpoint -q ~/GoogleDrive; then
    ITEMS=$(ls ~/GoogleDrive 2>/dev/null | wc -l)
    echo "  Status : MOUNTED"
    echo "  Path   : ~/GoogleDrive  ($ITEMS items)"
else
    echo "  Status : NOT MOUNTED"
    echo "  Run    : gdrive-mount"
fi
echo ""
echo "Service:"
systemctl --user status rclone-gdrive.service --no-pager 2>/dev/null \
    | grep -E "(Active|since|Failed)" || echo "  Service not found"
echo ""
echo "Log (last 5 lines):"
tail -5 ~/.local/log/rclone-gdrive.log 2>/dev/null || echo "  No log yet"
SCRIPT
chmod +x ~/.local/bin/gdrive-status

echo ""
echo "  Verification:"
check_cmd rclone
check_cmd gdrive-mount
check_file ~/.config/systemd/user/rclone-gdrive.service
[ -d ~/GoogleDrive ] && ok "mount point ~/GoogleDrive" || fail "mount point missing"

if rclone listremotes 2>/dev/null | grep -q "^gdrive:"; then
    ok "gdrive: remote configured"
    systemctl --user enable --now rclone-gdrive.service 2>/dev/null || warn "service start failed"
else
    warn "gdrive remote NOT configured yet"
    info "Run in a terminal: rclone config"
    info "Name it 'gdrive', choose Google Drive, follow OAuth steps"
    info "Then: systemctl --user enable --now rclone-gdrive.service"
fi
