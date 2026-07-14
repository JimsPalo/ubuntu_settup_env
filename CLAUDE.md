# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A modular, idempotent Bash-based setup system for Ubuntu 22.04 LTS (X11 session). It configures a Windows-familiar desktop: touchpad gestures, keyboard shortcuts, office suite, browser, clipboard manager, battery management, theming, and more. There is no build step, no test suite, no application code — this repo *is* the installer.

## Commands

```bash
# Full install (in order — packages first, needs sudo; then user-level config)
sudo bash install-packages.sh
bash install-all.sh

# Run one module standalone (safe to re-run anytime)
bash modules/08-gestures.sh

# Verify what's actually installed (read-only, no sudo, exit 0/1)
bash verify-install.sh

# Syntax-check a script before considering an edit done (no interpreter execution)
bash -n modules/08-gestures.sh
```

There's no linter/formatter/CI config in this repo — `bash -n` is the standard check after any edit here.

## Architecture

Two entry points, split by privilege level:

- **`install-packages.sh`** (run once with `sudo`) — apt packages, PPAs, GPG keys, system-level `systemctl enable/start`. Nothing here touches a user's home directory or gsettings.
- **`install-all.sh`** (run as the normal user) — calls every `modules/NN-name.sh` in order via `run_module()`, logs failures to `~/setup-errors.log`, prints a final summary of shortcuts/gestures/apps.
- **`modules/lib.sh`** — sourced by every module. Provides `ok/fail/warn/info`, `check_cmd/check_pkg/check_file/check_service/check_gsetting`, `apt_install` (wraps `sudo apt install -y`), and `section()` for the module's banner header.
- **`modules/NN-name.sh`** — one per feature area, numbered by run order (currently 01–16; see the table in `README.md` for what each does). Each ends with its own `Verification:` block using the `check_*` helpers.
- **`verify-install.sh`** — standalone, read-only audit across every package/command/flatpak-app/helper-script the whole project installs. Not part of the install flow; run it after the fact to confirm state.
- **`dev-setup.sh`** — legacy reference only. It's the original monolithic script this modular system replaced. Nothing calls it, and it should not be used as a pattern (it installs pip packages and touches `/usr/bin/python3`, both of which the current design explicitly avoids — see gotchas below).

### Module conventions (see `CONTRIBUTING.md` for the full list)
- Start with `source "$(dirname "$0")/lib.sh"` and call `section "NN — Name"` — keep the number in that string matching the filename (several older modules drifted from this after past renumbering; don't propagate that drift into new ones).
- No `set -e`. Each risky command is its own `|| fail "message"` so one failure doesn't abort the module.
- Must be idempotent: check before installing/writing (`command -v`, `dpkg -l`, `[ -f ]`).
- Sudo-requiring package installs belong in `install-packages.sh`; gsettings/dotfiles/user-service work belongs in the module (runs unprivileged via `install-all.sh`).
- No Python pip packages anywhere in this repo — Python is installed as a runtime only (`python3.12`, `python3.12-venv`).
- Adding a module: create `modules/NN-name.sh`, wire it into both `install-all.sh` and `install-packages.sh` (if it needs apt packages), and add a row to the module table in `README.md`.

### Gotchas discovered the hard way (don't repeat these)

- **Never run `update-alternatives` on `/usr/bin/python3` itself** — only alias bare `/usr/bin/python`. Ubuntu's own system tools (`gnome-terminal`, `add-apt-repository`, apt's `cnf-update-db` hook, etc.) shebang `#!/usr/bin/python3` and depend on compiled extensions (`apt_pkg`, `gi`'s `_gi`) that only exist for the distro's stock 3.10 build. Repointing `/usr/bin/python3` to 3.12 breaks all of them with cryptic `ModuleNotFoundError` tracebacks, including a broken login-screen terminal.
- **Don't gate a PPA-based install behind `command -v <binary>`.** Ubuntu's universe repo sometimes already ships an old fallback of the same package (e.g. `touchegg 1.1.1` predates the PPA's 2.x client/server architecture and is unreliable on modern GNOME/libinput). That satisfies the `command -v` check and silently skips adding the PPA forever. Always add the PPA and run `apt update` unconditionally; letting apt pick the higher version number is safe and idempotent.
- **Use `hkps://keyserver.ubuntu.com`, not `hkp://keyserver.ubuntu.com:80`**, for any GPG key fetch (see `04-onlyoffice.sh`). The old plain-HKP-on-port-80 protocol has been observed silently producing a corrupt/near-empty keyring file, which then breaks `apt update` for that repo with no obvious error pointing back at the key.
- Touchpad gestures require an **X11** session — Wayland is not supported by touchegg. Check `loginctl show-session $(loginctl list-sessions --no-legend | awk '{print $1}') -p Type` before debugging gesture issues further.
