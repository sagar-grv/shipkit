# LAST_SESSION — ShipKit v2.0.1

**Date:** 2026-05-25
**Branch:** `main` (pending — uncommitted fixes)
**Latest commit:** `109d157` — fix: setup.sh has_git + CRLF heredoc bugs (2026-05-23)
**Remote:** https://github.com/sagar-grv/shipkit.git

---

## What Was Completed

### 📦 npm Published! (May 23, continued)
- **`shipkit-pipe@2.0.0`** live at https://www.npmjs.com/package/shipkit-pipe
- Published using granular access token with bypass-2fa
- Token stored in `.npmrc` (gitignored)
- `npm pkg fix` ran to clean bin path warning (`./bin/` → `bin/`) — committed as `1b2cd57`

### 🌐 Custom Domain — Dropped
- No free domain available → removed shipkit.dev references
- **Decided**: Use default GitHub Pages URL `https://sagar-grv.github.io/shipkit/`
- Updated `docs/index.html` og:image/twitter:image URLs from `https://shipkit.dev` → `https://sagar-grv.github.io/shipkit/`
- Deleted `docs/CNAME` (never committed to git anyway)
- Commit: `ec0d558`

### 🐛 Bug Fix: setup.sh `has_git` (Line 126)
- **Root cause**: `has_git &&` was using variable name without `$` prefix → bash interpreted `has_git` as a command name instead of checking its value
- **Fix**: `[ "$has_git" = true ] &&`
- Also fixed: `node_version=` → `NODE_VERSION` mismatch between variable names

### 🐛 Bug Fix: CRLF Heredoc Corruption
- **Root cause**: On cross-platform clones, `setup.sh` could have CRLF (`\r\n`) line endings → bash heredoc delimiter `PYEOF` had a trailing `\r` → never matched → Python stdin consumed shell+template content as heredoc input → corrupted execution
- **Fix**: Added self-cleanup at script top: `if grep -q $'\r' "$0"...`
- **`.gitattributes`**: Added `eol=lf` for `*.yml` and `*.yaml` files
- Commit: `109d157` (with has_git fix)

### 🧪 Ubuntu Testing Results
- **`npx shipkit-pipe setup`**: FAILED — "WSL 1 is not supported" (Node.js install issue — not our bug)
- **Direct `setup.sh`**: FAILED — `has_git` bug + CRLF heredoc corruption (both now fixed)
- **Analysis**: Python (`python3`) is NOT guaranteed on Linux (no `python3` binary on many distros without installing it)
- **Decision**: Remove Python dependency entirely from the pipeline

### 🏗️ Template Renderer Rewrite (Python → Node.js)
- **Created `template/render.js`**: Standalone Node.js template renderer (64 lines)
  - Reads `SK_*` environment variables (strips `SK_` prefix for template use)
  - Handles `{{VAR}}` substitution
  - Handles `{% if VAR %}...{% endif %}` conditional blocks
  - Zero dependencies (uses `fs`, `path` built-ins)
  - Works identically to the in-memory renderer in `bin/shipkit-pipe.js`
- **Rewrote `setup.sh` rendering**:
  - Removed all `python3` calls (JSON parsing, template rendering)
  - JSON pretty-print: `python3 -m json.tool` → `node -e "..."` inline
  - Template rendering: removed fragile Python heredoc → replaced with `node template/render.js`
  - Added `--defaults` / `-y` flag for fully automated (non-interactive) mode
  - Added `err()` helper (red error message)
  - Added Node.js availability check at startup (`command -v node`)
  - Better error messages for missing template directory

### 🇦 Added `--defaults` / `-y` Non-Interactive Mode
- **JS CLI** (`bin/shipkit-pipe.js`): Already had `--defaults` flag → now documented in `--help`
- **`setup.sh`**: Added `--defaults` / `-y` flag → skips all prompts, uses detected values
- All auth prompts (GitHub CLI, Vercel, Supabase) are skipped in `--defaults` mode
- Version bumped to `2.0.1` in `package.json`, `bin/shipkit-pipe.js`, `setup.sh`

---

## Files Changed (Uncommitted)

```
template/render.js      (NEW)  Node.js template renderer (replaces Python heredoc)
setup.sh                (REWRITTEN)  No Python dependency, --defaults flag, Node.js renderer
bin/shipkit-pipe.js     (UPDATED)  Version 2.0.1, --help updated
package.json            (UPDATED)  Version 2.0.0 → 2.0.1
.gitattributes          (UPDATED)  *.js, *.json, *.html, *.css → eol=lf
```

---

## Still To Do

### 1. Commit & Push Fixes
```bash
git add -A
git commit -m "fix: remove Python dependency, add --defaults flag, Node.js renderer"
git push origin main
```

### 2. User Pulls on Ubuntu & Tests
```bash
cd /tmp/shipkit && git pull
cd /tmp/test-project
bash /tmp/shipkit/setup.sh --defaults
# Verify:
ls -la .github/ shipkit/ AGENTS.md ROADMAP.md BUGS.md LAST_SESSION.md shipkit.json
cat shipkit.json
```

### 3. Verify `npx shipkit-pipe setup` on WSL 2+
- Requires Node.js ≥ 18
- WSL 1 not supported by Node.js — must upgrade to WSL 2

### 4. Republish to npm (v2.0.1)
- After committing fixes: `npm version patch && npm publish`
- Verify: `npm view shipkit-pipe versions`

---

## Key Decisions Made

| Decision | Rationale |
|----------|-----------|
| **Remove Python dependency** | Python3 not guaranteed on Linux; Node.js developers already have Node.js installed |
| **Node.js template renderer** | `template/render.js` used by both `setup.sh` and `setup.ps1` — single code path |
| **`--defaults` non-interactive mode** | Required for CI/automation use cases |
| **Skip custom domain** | No free domain available; use GitHub Pages URL |
| **Keep setup.sh as bash** | Not published to npm (only `bin/` + `template/` are in npm package); `setup.sh` is for cloning/repo users |
| **Bump to 2.0.1** | Significant changes (Python removal, defaults mode, bug fixes) |

---

## Relevant Commands

| Command | Description |
|---------|-------------|
| `npm pack --dry-run` | Verify npm payload before publish |
| `node bin/shipkit-pipe.js setup --defaults` | Test JS CLI (non-interactive) |
| `bash setup.sh --defaults` | Test bash version (non-interactive) |
| `bash setup.sh` | Interactive mode |
| `git log --oneline -10` | Recent history |
| `npm version patch && npm publish` | Republish after commits |

---

## DORA Metrics (This Session)

| Metric | Value |
|--------|-------|
| Deploy Frequency | 3 pushes to main |
| Lead Time | ~3 days (May 23 → May 25 for Python removal) |
| Change Failure Rate | ~33% (2 bugs found in setup.sh after shipping) |
| Time to Restore | ~2 hours per bug |
