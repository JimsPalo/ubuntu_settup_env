# Ubuntu 22.04 Environment Setup

A modular, idempotent setup system for Ubuntu 22.04 LTS that configures a productive, Windows-familiar environment — gestures, shortcuts, office suite, Google Drive, eye care, battery management, and more.

![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?logo=ubuntu&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue)
![X11](https://img.shields.io/badge/Session-X11-informational)

---

## Features

- **Windows-style shortcuts** — Alt+F4, Super+arrows, Alt+Tab, workspace switching
- **3-finger touchpad gestures** — window cycling with Alt+Tab held, show desktop, app grid
- **Flameshot screenshots** — Print / Shift+Super+S / Ctrl+Shift+S
- **Google Drive** auto-mount via rclone FUSE
- **ONLYOFFICE** — full Word / Excel / PowerPoint compatibility
- **CopyQ** clipboard manager — Ctrl+Super+V
- **Battery charge thresholds** — TLP-native start/stop (50% → 60%)
- **Night light / eye care** — warm tone 18:00–08:00, toggle with `eyecare`
- **Floating dock** — intellihide, Windows-style
- **Dark theme** — Adwaita-dark, subpixel font rendering
- **System tuning** — vm.swappiness=10, SSD TRIM, preload
- **btop** — resource monitor (CPU, memory, disks, network, processes)
- **micro** — lightweight terminal text editor, default for any text file (right-click → Open With → Micro)
- **Microsoft Edge** — Chromium-based browser
- **Thunderbird** — email client
- **Pomodoro timer** — GNOME Pomodoro, configurable work/short-break/long-break cycles across multiple sessions
- **Extended touchpad gestures** — 4-finger maximize/minimize + pinch in/out, on top of the 3-finger set

---

## Requirements

See [requirements.txt](requirements.txt) for the full system dependency list.

- Ubuntu 22.04 LTS
- X11 session (not Wayland) — required for touchpad gestures; `install-packages.sh` forces this by setting `WaylandEnable=false` in `/etc/gdm3/custom.conf`
- Internet connection for first-time package installation
- `sudo` access

---

## Installation

### Step 1 — Install packages (sudo required, ~5 min)

```bash
sudo bash install-packages.sh
```

### Step 2 — Configure modules (normal user, ~2 min)

```bash
bash install-all.sh
```

### Step 3 — Google Drive (optional)

```bash
rclone config          # name it 'gdrive', choose Google Drive, follow OAuth
systemctl --user enable --now rclone-gdrive.service
```

### Step 4 — Verify (optional)

```bash
bash verify-install.sh
```

Read-only audit of every package, command, and helper script this project installs — prints what's present vs. missing.

### Step 5 — Reboot

```bash
sudo reboot
```

> Each module is idempotent — safe to re-run individually if something fails.

---

## Modules

| # | Module | What it does |
|---|---|---|
| 01 | `01-essentials.sh` | System update, core tools (incl. btop, micro), flameshot |
| 02 | `02-python.sh` | Python 3.12 runtime (no pip packages) |
| 03 | `03-vscode.sh` | VS Code + Git config |
| 04 | `04-onlyoffice.sh` | ONLYOFFICE (Word / Excel / PowerPoint) |
| 05 | `05-pdf-editor.sh` | Sejda PDF editor shortcut (online) |
| 06 | `06-clipboard.sh` | CopyQ clipboard manager |
| 07 | `07-google-drive.sh` | rclone Google Drive FUSE auto-mount |
| 08 | `08-gestures.sh` | touchegg 3-finger gestures (X11) + Touché settings GUI |
| 09 | `09-dock.sh` | Floating dock + app grid cleanup |
| 10 | `10-shortcuts.sh` | Keyboard shortcuts + screenshot bindings |
| 11 | `11-theme.sh` | Dark theme, fonts, touchpad, 1 workspace |
| 12 | `12-eyecare.sh` | Night light + `eyecare` toggle command |
| 13 | `13-battery.sh` | Battery charge thresholds via TLP (stop 60%, start 50%) |
| 14 | `14-optimise.sh` | Kernel tuning, SSD TRIM, preload |
| 15 | `15-browser.sh` | Microsoft Edge |
| 16 | `16-pomodoro.sh` | Pomodoro timer (GNOME Pomodoro, multi-session cycles) |

Run any module individually:

```bash
bash modules/08-gestures.sh
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Alt+F4` | Close window |
| `Super+Up` | Maximise |
| `Super+Down` | Minimise |
| `Super+Left / Right` | Snap window to side |
| `Alt+Tab` | Switch windows |
| `Super+L` | Lock screen |
| `Super+E` | File manager |
| `Super+T` | Terminal |
| `Super+I` | Settings |
| `Super+A` | Show all apps |
| `Ctrl+Super+V` | Clipboard history (CopyQ) |
| `Print` | Screenshot (Flameshot) |
| `Shift+Super+S` | Screenshot region |
| `Ctrl+Shift+S` | Screenshot region |
| `Ctrl+Alt+← / →` | Switch workspace |

---

## Touchpad Gestures (X11 / touchegg)

| Gesture | Action |
|---|---|
| 3-finger tap | Open app grid |
| 3-finger swipe right | Next window (Alt+Tab — stays open while swiping) |
| 3-finger swipe left | Previous window |
| 3-finger swipe down | Minimise all windows (show desktop) |
| 3-finger swipe up | Window overview |
| 4-finger swipe left / right | Switch workspace |
| 4-finger swipe up | Maximize/restore current window |
| 4-finger swipe down | Minimize current window |
| 4-finger pinch in | Show desktop |
| 4-finger pinch out | Window overview |

---

## Useful Commands

```bash
battery-status              # SoC, charge limit, cycle count
sudo set-battery-limit 60   # change charge stop threshold
eyecare                     # toggle day / night light mode
gdrive-status               # Google Drive mount status
gdrive-mount                # manually mount Google Drive
bash verify-install.sh      # audit everything this project installs
```

---

## Architecture

```
ubuntu_environment/
├── install-packages.sh   # sudo — apt installs, PPAs, system services
├── install-all.sh        # user — runs all modules in order
├── verify-install.sh     # read-only audit — what's installed vs missing
├── modules/
│   ├── lib.sh            # shared helpers (ok/fail/warn/check_cmd …)
│   ├── 01-essentials.sh
│   └── …16 modules
└── dev-setup.sh          # original reference script (not executed)
```

`install-packages.sh` must run first (with sudo) because it installs apt packages, PPAs, and system-level services. `install-all.sh` runs as a normal user and applies all gsettings, config files, and user-level services.

---

## License

[MIT](LICENSE) © 2024
