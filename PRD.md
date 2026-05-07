# PRD: startupjet

## What it is

A cross-platform fresh-PC bootstrap tool that installs dev tools, AI models, SSH keys, dotfiles, and clones repos from a single declarative config. Runs on Windows (PowerShell), macOS (bash + Homebrew), and Linux (bash + apt).

## Why it exists

Setting up a new machine takes hours of manual installs, logins, config tweaks, and repo cloning. startupjet collapses that into one command with all questions asked upfront and the rest running unattended. The user can walk away and come back to a ready workspace.

## Who it is for

1. Jeremy (primary user): keeps his own defaults baked in as the standard config. Forks are encouraged.
2. Anyone who wants an opinionated but customizable bootstrap: fork, edit config/, run.

## What it is NOT

- Not a configuration management tool (no Ansible, no Chef). It runs once on a fresh machine.
- Not a dotfiles manager on its own. It integrates with an external dotfiles repo via config/dotfiles.json.
- Not a package manager. It delegates to winget, Homebrew, apt, and npm.

## Core design decisions

1. **Declarative config**: catalog.json is the single source of truth for tools across all platforms. Both scripts read from it.
2. **All questions upfront**: Phase 2 collects every choice. Phases 3-7 run unattended.
3. **Resume on crash**: progress.json tracks completed installs. Re-running picks up where it left off.
4. **Fork-friendly**: only config/ needs editing. Scripts, landing page, and workflow diagram are generic.
5. **No dependencies on fresh machine**: PS1 uses built-in PowerShell. SH requires only python3 (pre-installed on macOS, one apt install on Linux).
