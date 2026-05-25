# Changelog

## [3.0.4] — 2026-05-25

### 🔧 CI & Setup Fixes — All 16 Issues Resolved

**Fixed:** CI was failing on every push because validate.yml checked for 8 template files that were removed in v3.

#### Fixed
- **validate.yml**: Updated template file list — removed 8 deleted files, added 3 new ones (health.yml, bitbucket, gitlab)
- **validate.yml**: Upgraded `actions/checkout@v4` → `actions/checkout@v5` (Node.js 20 deprecation warning fixed)
- **setup.sh**: Complete rewrite for v3 — platform detection (GitHub/GitLab/Bitbucket), reads package.json scripts dynamically, uses single AGENTS.md, adds health.yml, supports --dry-run
- **setup.ps1**: Complete rewrite for v3 — same improvements as setup.sh
- **README.md**: Full rewrite — removed all v2 references (npx shipkit setup, 6-agent team, shipkit/ subdir, Husky, Playwright, ROADMAP.md, BUGS.md)
- **ROADMAP.md**: Updated to v3 roadmap
- **BUGS.md**: Updated with v3.0.4 resolved bugs
- **LAST_SESSION.md**: Updated to current state
- **package.json**: test script now runs --help, --version, --dry-run, check
- **.gitattributes**: Removed duplicate `*.json text` entry
- **docs/index.html**: Terminal animation says "Generated files" instead of hardcoded "7"

## [3.0.3] — 2026-05-25

- GitLab CI template (`.gitlab-ci.yml`)
- Bitbucket Pipelines template (`bitbucket-pipelines.yml`)
- `--dry-run` / `--preview` flag
- Git platform auto-detection from remote URL
- Help text updated with all options + offline note
- 'No Node.js?' link to GitHub releases in help

## [3.0.2] — 2026-05-25

- Work in ANY directory — no more rejection for empty dirs
- Monorepo detection (frontend/, backend/, web/, etc.)
- Non-Node project detection (pyproject.toml, go.mod, Cargo.toml, Docker)

## [3.0.1] — 2026-05-25

- Support monorepos and non-Node.js projects
- Detect package.json in subdirectories

## [3.0.0] — 2026-05-25

### 🚀 ShipKit v3 — Smart Detection, Zero Config

**Breaking changes:**
- Only generates CI steps for scripts that exist in package.json
- Reduced from 15 files to 7 essential files
- Removed: multi-agent prompts (planner.md, co-developer.md, etc.), ROADMAP.md, BUGS.md, Husky, Playwright
- Simplified AGENTS.md (124 lines → 39 lines)

**New:**
- Smart CI — only steps for scripts that exist
- Health check workflow (pings every 6h, creates issue if down)
- `npx shipkit-pipe check` command
- Spinner UI with progress feedback
- Deploy URL auto-detection (Vercel, Netlify, Fly.io, Railway, Render)
- Node version from .nvmrc / .node-version / engines
- Bun support

## [2.0.1] — 2026-05-23

### 🐛 Pre-Launch Bugfix & Polish

- Fixed setup.ps1 syntax errors (PowerShell 5.1)
- Fixed setup.sh shell injection risk
- GitHub Actions CodeQL @v3 → @v4
- Landing page, .gitattributes, .npmignore, .prettierrc
- validate.yml checks all template files

## [2.0.0] — 2026-05-23

### 🚀 Plug-and-Play Release

- Stack-agnostic orchestration layer
- Works with any AI agent, any IDE, any cloud
- Universal AGENTS.md protocol

## [1.0.0] — 2026-05-23

### Initial Release
