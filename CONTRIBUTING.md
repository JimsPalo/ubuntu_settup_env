# Contributing

## Adding a module

1. Create `modules/NN-name.sh` following the existing numbering
2. Start with `source "$(dirname "$0")/lib.sh"` and call `section "NN — Name"`
3. Use `apt_install`, `ok`, `fail`, `warn`, `info`, `check_cmd` from `lib.sh`
4. Make it idempotent — check before installing (`command -v`, `dpkg -l`, `[ -f ]`)
5. Add it to `install-all.sh` and `install-packages.sh` in the correct order
6. Test with `bash modules/NN-name.sh`

## Module rules

- Packages that need `sudo` go in `install-packages.sh`
- gsettings / user config goes in the module (runs as normal user via `install-all.sh`)
- No Python pip packages — runtime only (`python3.12`, `python3.12-venv`)
- No `set -e` — use `|| fail "message"` per command so one failure doesn't abort the run

## Testing

```bash
# Full run
sudo bash install-packages.sh && bash install-all.sh

# Single module
bash modules/08-gestures.sh
```
