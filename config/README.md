# config/

This folder is the only thing you need to edit when forking startupjet. The scripts (`startupjet.ps1`, `startupjet.sh`) read everything from here.

## Files

| File | What it does | Required |
|------|-------------|----------|
| `defaults.json` | Your workspace path (Windows + Unix), GitHub username, git email | Yes |
| `repos.json` | Repos to clone during setup. Mark required/optional, shallow/full | Yes |
| `catalog.json` | Tool catalog with install methods per OS (winget/brew/apt/npm/script) | Yes |
| `vscode-extensions.json` | VS Code extensions to auto-install | Optional |
| `dotfiles.json` | Dotfiles repo URL + file-to-path mappings | Optional (set repo to "" to skip) |

## How to customize

1. Fork this repo
2. Edit `defaults.json` with your identity
3. Edit `repos.json` with your repos
4. Optionally edit the other files
5. Run `startupjet.bat` (Windows) or `./startupjet.sh` (macOS/Linux)

## Adding a new tool

Edit `catalog.json`. Each tool needs an `install` block per OS:

```json
{
  "id": 99, "name": "My Tool", "cmd": "mytool", "category": "dev",
  "install": {
    "windows": { "method": "winget", "id": "Publisher.MyTool" },
    "macos":   { "method": "brew",   "package": "mytool" },
    "linux":   { "method": "apt",    "package": "mytool" }
  }
}
```

Install methods: `winget`, `brew`, `cask`, `apt`, `npm`, `script` (arbitrary command), `manual`, `builtin` (skip).

For Windows-only tools (like PowerShell 7), omit the `macos` and `linux` keys. The scripts automatically skip tools that have no install method for the current OS.

Use `"downloadMB"` and `"installMin"` for time estimates (optional, defaults to 50 MB and 1 min).

## Files created at runtime

| File | Purpose |
|------|---------|
| `progress.json` | Tracks completed installs for crash resume. Deleted on success |
| `user-config.json` | Snapshot of choices made during setup |
