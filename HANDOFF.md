# HANDOFF.md

> Pick this up when you (or another AI session) come back to this repo. Read this FIRST before doing anything else, then check `PROGRESS.md` for shipped history and `ISSUES.md` for known bugs.

## Last touched

**2026-05-07** by Claude (Claude Code, Opus 4.7 with 1M context). See [`ai-journal/claude/entries/2026/05/2026-05-07-jet-oss-creation-and-github-sync-all-fresh-restart.md`](https://github.com/jeremytrindade/ai-journal/blob/main/claude/entries/2026/05/2026-05-07-jet-oss-creation-and-github-sync-all-fresh-restart.md) and the follow-up entry from the same day covering the rename + cross-account consolidation arc.

## In-progress

- [ ] **`migrate-shared-caches.bat` running** — user pressed (or about to press) Y on the consolidation prompt. When done, npm globals from `jeremy-trinity` (~0.15 GB) merge into `D:\shared\npm-global`, `NPM_CONFIG_PREFIX` set Machine-wide, npm prefix appended to Machine PATH. Verify with `jet-init.bat doctor` after the next login.
- [ ] **`jet-init.bat install -FullDev`** queued for after the cache consolidation finishes. Will retry the previously-failed `qwen3:30b-a3b` (18 GB, TLS-timeouted earlier) and confirm the 4 already-migrated models (`llama3.1`, `qwen2.5`, `mistral`, `phi3.5`) are detected as already-installed.

## Recommended next

- [ ] **Cross-repo brand sweep** for the old names. Repos still mention `startupjet` and `github-sync-all` in: `jet-rules/README.md` (links), `jet-playbook/RULES.md` (Rule references), `ai-journal/claude/entries/*` (recent entries from today). Per playbook Rule 17 a renamed repo doesn't auto-trigger a brand sweep, but consistency across the family is worth a one-shot `findstr /sm "startupjet github-sync-all" D:\aijetlabs\github\*` followed by edits.
- [ ] **Push `jet-oss` to GitHub** as public. Still local-only at `D:\aijetlabs\github\jet-oss\` with one init commit. Layer 3 of the rules system (jet-rules / jet-playbook / jet-oss). Public-from-day-one was the agreed plan; user authorized in the session but the actual `gh repo create --public` was deferred behind the rename work.
- [ ] **Add `jet-oss` link from `jet-rules/README.md`** so the 3-layer system is discoverable starting at layer 1.
- [ ] **Delete `D:\aijetlabs\github\github-sync-all-archive\`** (the duplicate created during a smoke test before the rename). Identical content lives at `_archive/github-sync-all-archive/`. Needs user authorization, harness blocked the recursive delete.
- [ ] **Clean up `~9 GB of `-partial` files** in `D:\ollama\models\blobs\` (from the failed pull attempts before consolidation). Safe to delete: `Remove-Item D:\ollama\models\blobs\*-partial*`. Recovers disk without affecting any installed model.

## Decisions pending

- **`lib/` split refactor of `jet-init.ps1`**: deferred. The script is ~2300 lines in one file. Splitting into `lib/install.ps1`, `lib/audit.ps1`, `lib/storage.ps1`, `lib/auth.ps1` would help readability but risks breaking `$script:` scoping. Decision: do it after the cache tool is verified end-to-end.
- **Spin out `jet-cleanup` as a sibling repo**: explicitly rejected this session. Rationale: cleanup is a verb of `jet-init`, not a separate product. Revisit only if cleanup grows verbs that don't fit the install-tool product (daily-driver disk maintenance for non-developers, etc.).
- **`-Yes` non-interactive coverage**: only wired into the three PHASE 0 prompts (mode, pcType, audit-first). Other `Read-Host` calls deeper in the flow still block. Decision: extend if CI/cron usage actually emerges, leave alone otherwise.

## Recently done (this 2026-05-07 arc)

- Extended `github-clone-all` to also `git pull --ff-only` existing repos (dirty-tree skip), brought `D:\aijetlabs\github\` from 8 to 73 repos.
- Created `jet-oss` (Layer 3 rules for going public) with 6 rules.
- Renamed `github-clone-all` to `github-sync-all` per playbook Rule 30, then archived to `github-sync-all-archive`, then created fresh `github-sync-all` v0.1.0 public.
- Renamed `github-sync-all` to `jet-sync` (v1.0.0) and `startupjet` to `jet-init` (v2.0.0) for jet-* family consistency.
- Built verb-style CLI (`install` / `fix` / `doctor` / `update`) backed by helpers in the same script.
- Cross-account Ollama consolidation: ~16 GB of models from `jeremy-trinity` migrated into `D:\ollama\models`, `OLLAMA_MODELS` set Machine-wide, `BUILTIN\Users` Modify ACL.
- Built `tools/migrate-ollama-shared.bat` and `tools/migrate-shared-caches.bat` (admin one-shots).
- Idempotent auth flow (gh / tailscale / cloudflared all show identity + ask "continue?" instead of re-prompting).
- UTF-8 console encoding fix (Ollama progress bar no longer prints `Ôûò` garbage).
- Cloudflared cert-already-exists detection (no more misleading ERR line).
- Catalog typo: `qwen3:35b-a3b` (404 from registry) -> `qwen3:30b-a3b`.
- `pcType` persisted to `config/user-config.json` and read back on next run.
- `-Yes` flag for non-interactive PHASE 0.
- `Stop-Transcript` double-call error swallowed.

## How to use this file

When you re-enter the repo (after a reboot, account switch, or new AI session), the prompt is just:

```
Read D:\aijetlabs\github\jet-init\HANDOFF.md and tell me what's still open. Don't change anything yet.
```

The new session reads this file, summarizes the open items, and asks which one to start with. No re-derivation of context.

When you finish a chunk of work, append to `## Recently done` and remove from `## In-progress` / `## Recommended next` / `## Decisions pending`. Keep this file under ~2 KB of active items so the LLM context cost stays low.
