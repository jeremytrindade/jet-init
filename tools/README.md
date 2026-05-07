# startupjet tools

One-off utilities for cleaning up state startupjet itself does not own.

## migrate-ollama-shared

Move every Windows account's Ollama models into one shared location and set `OLLAMA_MODELS` Machine-wide so all current and future accounts share it. Solves the "I have 3 accounts and 3 copies of the same 30 GB of models" problem.

### Run

```
Right-click migrate-ollama-shared.bat -> Run as administrator
```

Or from an elevated PowerShell:

```powershell
pwsh -File D:\aijetlabs\github\startupjet\tools\migrate-ollama-shared.ps1
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
