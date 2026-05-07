# Progress

## 2026-05-07, v2.0.0 brand-aligned to the jet-* family

Renamed from `startupjet` to `jet-init` to fit the [jet-rules](https://github.com/jeremytrindade/jet-rules), [jet-playbook](https://github.com/jeremytrindade/jet-playbook), [jet-oss](https://github.com/jeremytrindade/jet-oss), [jet-sync](https://github.com/jeremytrindade/jet-sync) family naming pattern. Major version bump because the URL and entry-point file names are breaking changes.

What renamed:
- Repo: `jeremytrindade/startupjet` -> `jeremytrindade/jet-init` (GitHub redirects the old URL)
- Entry points: `startupjet.bat` -> `jet-init.bat`, `startupjet.ps1` -> `jet-init.ps1`, `startupjet.sh` -> `jet-init.sh`
- All internal references swept (catalog descriptions, README, PRD, workflow diagram, landing page, defaults.json, tools/ scripts)
- Log file pattern: `startupjet-<ts>.log` -> `jet-init-<ts>.log` (old pattern kept in `.gitignore` for any remaining session logs)

No behavior change. Verb-style CLI (`install` / `fix` / `doctor` / `update`) introduced in v1.3 is preserved.

## 2026-05-06 23:00 - v1.2 complete

Full feature parity between PS1 and SH scripts. All workflow ideas marked Done except three low-priority nice-to-haves (machine profile export, multi-GPU, completion notification).

Features shipped:
- 14 tools + 7 models in declarative catalog.json
- Preset profiles (Minimal dev / Developer / AI workstation / Custom)
- Hardware scan (RAM, GPU/VRAM, disk, speed test)
- Smart model recommendations based on hardware
- Resume on crash via progress.json
- Dry run, update, --version, --help on both scripts
- SSH key management (Bitwarden vault restore, generate, GitHub upload)
- SSH-preferred cloning (detects key + gh auth)
- Dotfiles management (symlink on macOS/Linux, copy on Windows)
- VS Code extensions auto-install
- Post-clone dependency install (npm, pip)
- Functional tests (Python, Node, Ollama inference, git identity)
- Detailed summary with installed/failed/auth/repos breakdown
- user-config.json audit trail
- Landing page + workflow diagram with light/dark toggle
- config/README.md for forkers

## 2026-05-07 00:30 - Playbook + ai-journal integration

Added post-clone integration with playbook rules and ai-journal workflow:
- Scripts copy playbook/RULES.md to workspace root after cloning
- Scripts create .history/ folder for conversation logging
- SH summary includes ai-journal UPDATE.md hint (was PS1-only)
- Added PRD.md, PROGRESS.md, ISSUES.md, debug-testing/ per playbook rule #10
