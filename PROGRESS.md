# Progress

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
