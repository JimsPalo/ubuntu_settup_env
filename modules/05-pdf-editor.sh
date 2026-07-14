#!/bin/bash
# Module 05: PDF Editor — Sejda (online, free, real text editing)
source "$(dirname "$0")/lib.sh"

section "05 — PDF Editor (Sejda online)"

DESKTOP_FILE="$HOME/.local/share/applications/sejda-pdf.desktop"
mkdir -p "$HOME/.local/share/applications"

cat > "$DESKTOP_FILE" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=PDF Editor (Sejda)
Comment=Edit PDF text, fill forms, annotate — opens in browser
Exec=xdg-open https://www.sejda.com/pdf-editor
Icon=application-pdf
Categories=Office;
Keywords=pdf;editor;
EOF

chmod +x "$DESKTOP_FILE"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

info "Sejda shortcut created: Apps → PDF Editor (Sejda)"
info "Features: edit text, fill forms, annotate, merge, sign"
info "Free tier: 3 tasks/hour, up to 200 pages, 50MB per file"
info "Open directly: xdg-open https://www.sejda.com/pdf-editor"
