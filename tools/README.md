# jet-init tools

One-off utilities for cleaning up state jet-init itself does not own.

| Tool | What it consolidates | Run as |
|---|---|---|
| `migrate-ollama-shared.bat` | Ollama models | Administrator |
| `migrate-shared-caches.bat` | npm globals, uv cache, pip wheel cache | Administrator |

Both are idempotent. Both follow the same pattern: discover per-user copies under `C:\Users\*`, set the corresponding Machine-scope env var, set `Modify` ACL for `BUILTIN\Users` on the shared target, robocopy the per-user copies into the target. Re-run any time.

## migrate-ollama-shared

Move every Windows account's Ollama models into one shared location and set `OLLAMA_MODELS` Machine-wide so all current and future accounts share it. Solves the "I have 3 accounts and 3 copies of the same 30 GB of models" problem.

### Run

```
Right-click migrate-ollama-shared.bat -> Run as administrator
```

Or from an elevated PowerShell:

```powershell
pwsh -File D:\aijetlabs\github\jet-init\tools\migrate-ollama-shared.ps1
```

Or with a custom target path:

```powershell
pwsh -File migrate-ollama-shared.ps1 -Target E:\shared\ollama\models
```

### What it does

1. Stops the Ollama daemon.
2. Walks `C:\Users\*\.ollama\models` and reports each one's size.
3. Asks for confirmation.
4. Creates `D:\ollama\models` (or `-Target`) if missing.
5. Grants `BUILTIN\Users` Modify on the target so every account can read and write.
6. `robocopy /MOVE` each per-user models folder into the target. Source folder is removed after a successful move.
7. Sets `OLLAMA_MODELS` at Machine scope so every account on this PC points to the shared location.
8. Restarts the Ollama daemon and prints `ollama list`.

### Idempotent

Safe to re-run. If `OLLAMA_MODELS` is already pointing at the right place and there are no per-user dirs left to consolidate, it just confirms the state.

### Why it needs admin

- Setting a Machine-scope env var writes to `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`.
- Reading other users' `.ollama\models` requires bypassing per-user ACLs.
- Setting `Modify` for `BUILTIN\Users` on the shared folder requires write on the parent.

All three need an elevated process.

### After running

- New shells in the current account already see the env var (the script sets it in the running session).
- Other accounts pick it up on their next login.
- Existing background processes keep their old value until restarted.

---

## migrate-shared-caches

Same pattern as `migrate-ollama-shared`, but for the developer-tool caches that also duplicate per account: npm globals, uv cache, pip wheel cache.

### Run

```
Right-click migrate-shared-caches.bat -> Run as administrator
```

Or with custom targets:

```powershell
pwsh -File migrate-shared-caches.ps1 `
  -NpmPrefix D:\shared\npm-global `
  -UvCache   D:\shared\uv-cache `
  -PipCache  D:\shared\pip-cache
```

### What it does

For each tool (npm / uv / pip):

1. Walks `C:\Users\*\<tool-cache-dir>` and reports each per-user copy with size.
2. Creates the shared target on the largest non-system disk if missing.
3. Grants `BUILTIN\Users` Modify on the shared target.
4. Sets the Machine-scope env var (`NPM_CONFIG_PREFIX`, `UV_CACHE_DIR`, `PIP_CACHE_DIR`) so every account points there.
5. Appends the npm prefix to Machine `PATH` so installed CLIs (Claude Code, Codex, etc.) are runnable from any account.
6. `robocopy /E /XC /XN /XO` each per-user dir into the shared target. Files in the target are never overwritten, so version conflicts are safe.

### Why it merges instead of moving

Different accounts may have different versions of the same package. A `/MOVE` would either fail loudly on conflicts or silently lose the wrong copy. The merge strategy (`/XC /XN /XO`) keeps whatever is in the target, only adds files that don't exist there. After the script runs, per-user directories may still have leftover files (the conflicts) — once you've verified the shared location works, you can delete the per-user dirs manually to free the rest of the space.

### Why it needs admin

- Setting Machine-scope env vars writes to `HKLM`.
- Modifying Machine `PATH` writes to `HKLM`.
- Setting `Modify` for `BUILTIN\Users` on a folder needs write on the parent.
- Reading `C:\Users\<other>\AppData\*` requires bypassing per-user ACLs.

### After running

- New shells in this account already see the env vars and the new PATH.
- Other accounts pick them up on their next login.
- Existing terminals keep their old values until restarted.
- VS Code instances and other editors pick up the new env on their next launch.
