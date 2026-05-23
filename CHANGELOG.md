# Changelog

## [2.0.1] — 2026-05-23

### 🐛 Pre-Launch Bugfix & Polish

**Audit pass before launch:** fixed 5 critical bugs, 5 quality improvements, and added GitHub Pages infrastructure.

#### Fixed
- **setup.ps1**: Syntax error on line 80 (`$Options[i]` → `$Options[$i]`) — PowerShell string interpolation fix
- **setup.sh**: Render template had shell injection risk — rewrote to safe file-based + `os.environ` approach
- **setup.sh**: `shipkit.json` was missing `stack.storage`, `stack.e2e`, `ci.typecheckCommand`, `ci.packageManager`, `deploy.previewUrls`, `database.rlsEnabled` — now matches JS and PS1 implementations
- **template/codeql.yml**: Upgraded GitHub Actions from `@v3` to `@v4` (deprecated)
- **template/husky/pre-commit**: Restored from git history (was deleted from working tree)

#### Added
- **`.nojekyll`** in `docs/` — required for GitHub Pages to serve files starting with `_`
- **`.npmignore`** — controls npm publish payload (defense-in-depth with `files` whitelist)
- **`.gitattributes`** — ensures consistent LF/CRLF line endings across platforms
- **`.prettierrc` + `.prettierignore`** — root-level formatting consistency
- **Favicon**: Inline SVG anchor emoji in `docs/index.html`
- **validate.yml**: Now checks all 13 template files (was only checking agents and docs)

#### Changed
- **SECURITY.md**: Rewrote with supply-chain notes (zero npm dependencies), proper contact email
- **LICENSE**: Updated copyright to Sagar Giri, clarified ethical use terms
- **CODE_OF_CONDUCT.md**: Added UTF-8 BOM for proper encoding

## [2.0.0] — 2026-05-23

### 🚀 Plug-and-Play Release

**Complete reframe:** ShipKit is now a universal plug-and-play orchestration layer that connects your tools (any AI agent, any IDE, any cloud) and runs a production pipeline automatically.

#### What Changed

- **New vision**: ShipKit is now stack-agnostic and tool-agnostic. Works with Claude Code, Cursor, Copilot, OpenCode, and any AI agent
- **Simplified setup**: ~5 questions instead of 20. Auto-detects your project's tech stack
- **Universal AGENTS.md**: One protocol that any AI coding agent can read
- **Authentication-based**: Setup script focuses on authenticating your tools (GitHub, deploy, database) rather than asking about tech choices
- **New `shipkit.json`**: Simplified config with aiAgent field for tool-specific adaptation
- **Agent-specific configs**: ShipKit generates CLAUDE.md, .cursorrules, .github/copilot-instructions.md depending on your AI agent
- **setup.sh**: Full Linux/macOS support added
- **Removed**: All HealthVault references, stack-specific approaches, 20-question survey

## [1.0.0] — 2026-05-23

### Initial Release

- AI Agent Team (Planner, Builder, Security Reviewer, Monitor)
- GitHub Actions CI/CD pipeline
- CodeQL + Dependabot security
- Husky pre-commit hooks
- Session continuity with LAST_SESSION.md
- DORA metrics tracking
- PowerShell setup script
