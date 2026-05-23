# Changelog

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
