# NEXT-STEPS.md

> Quick paste-into-PowerShell checklist. **jet-init auto-removes each step from this file when its done condition is met**, and deletes the file entirely when all steps are clear. So you can paste, walk away, and forget; the next `jet-init.bat doctor` (or any verb) cleans up.

<!-- step: cache-tool -->
## 1. Consolidate npm / uv / pip caches across accounts

Recovers ~0.15 GB on this PC, more if you add more accounts later. Sets `NPM_CONFIG_PREFIX`, `UV_CACHE_DIR`, `PIP_CACHE_DIR` Machine-wide.

```powershell
Start-Process pwsh -Verb RunAs -ArgumentList '-NoProfile','-File','D:\aijetlabs\github\jet-init\tools\migrate-shared-caches.ps1'
```

*Done when:* `NPM_CONFIG_PREFIX` is set at Machine scope.

<!-- step: partials-rm -->
## 2. Clean up partial Ollama blob downloads (~9 GB)

Leftover from the TLS-timeouted llama3.1 + qwen2.5 pulls before the consolidation. Safe to delete; the working models from the cross-account migration are intact.

```powershell
Remove-Item D:\ollama\models\blobs\*-partial* -Force
```

*Done when:* no `-partial` files remain under `D:\ollama\models\blobs\`.

<!-- step: archive-rm -->
## 3. Delete duplicate archive folder

A `D:\aijetlabs\github\github-sync-all-archive\` was created during a smoke test; identical content is already at `D:\aijetlabs\github\_archive\github-sync-all-archive\`. Just the duplicate at the top-level needs removing.

```powershell
Remove-Item -Recurse -Force D:\aijetlabs\github\github-sync-all-archive
```

*Done when:* `D:\aijetlabs\github\github-sync-all-archive` no longer exists.

<!-- step: qwen3-pull -->
## 4. Retry the qwen3:30b-a3b model pull (18 GB)

Earlier pull failed with `net/http: TLS handshake timeout`. Resumable; will use `D:\ollama\models` (now Machine-wide).

```powershell
ollama pull qwen3:30b-a3b
```

*Done when:* `ollama list` shows `qwen3:30b-a3b`.

<!-- step: jet-oss-push -->
## 5. Push jet-oss to GitHub as public

`D:\aijetlabs\github\jet-oss\` has one local init commit but no remote yet. Layer 3 of the rules system.

```powershell
cd D:\aijetlabs\github\jet-oss
gh repo create jeremytrindade/jet-oss --public --source . --push --description "Layer 3 rules: 6 things that change when a repo flips from private to public. Sits on jet-rules + your extended rules."
```

*Done when:* `https://github.com/jeremytrindade/jet-oss` resolves.

---

How auto-clear works: each `<!-- step: id -->` marker has a corresponding detection in `jet-init.ps1`'s `Update-NextSteps` function. On every `doctor` / `fix` / `install` / `update` invocation, the script re-evaluates each detection and physically removes the section from this file when its condition is met. When no markers remain, the file deletes itself.
