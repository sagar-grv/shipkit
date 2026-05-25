# ShipKit — Your Automated Dev Team

> **One command sets up CI/CD, health monitoring, security, and AI agent config.**
> Reads your project. Generates only what you need. Zero questions. Works everywhere.

[![npm](https://img.shields.io/npm/v/shipkit-pipe)](https://www.npmjs.com/package/shipkit-pipe)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![CI](https://github.com/sagar-grv/shipkit/actions/workflows/validate.yml/badge.svg)](https://github.com/sagar-grv/shipkit/actions)

▶️ **[Watch overview video](https://github.com/sagar-grv/shipkit/releases/download/v3.1.0/shipkit-overview.mp4)** — AI-generated explainer (NotebookLM)

```bash
npx shipkit-pipe              # Auto-detect & generate
npx shipkit-pipe --dry-run    # Preview without writing
npx shipkit-pipe check        # Verify everything works
```

## ✨ What Makes ShipKit Different

| Before ShipKit | After `npx shipkit-pipe` |
|---|---|
| Manually configure CI/CD for every project | CI auto-generated from your scripts |
| CI fails because config doesn't match your package.json | Smart CI — only generates steps for scripts that exist |
| No health monitoring — find out your site is down from users | Health check pings every 6h, auto-creates GitHub Issues |
| Set up CodeQL, Dependabot, security manually | Security + dependency updates generated automatically |
| Write separate prompts for your AI agent | AGENTS.md + shipkit.json — agent knows your stack |
| GitLab / Bitbucket? Must write CI from scratch | Detects your platform, generates the right format |

## 🚀 Quick Start

```bash
# In any project directory:
npx shipkit-pipe

# That's it. Your pipeline is ready.
```

📖 **Detailed usage guide, scenarios, and troubleshooting → [USAGE.md](USAGE.md)**

**What gets generated:**

| File | Purpose |
|---|---|
| `shipkit.json` | Project config — AI agent reads this |
| `AGENTS.md` | Universal AI agent protocol |
| `.github/workflows/ci.yml` | Smart CI — only scripts you have (lint → test → build) |
| `.github/workflows/health.yml` | Pings your site every 6h, creates issue if down |
| `.github/dependabot.yml` | Weekly dependency updates |
| `.github/workflows/codeql.yml` | Security vulnerability scan |
| `.github/workflows/auto-merge.yml` | Auto-merges safe Dependabot PRs |

**For GitLab:** generates `.gitlab-ci.yml` instead of GitHub Actions.
**For Bitbucket:** generates `bitbucket-pipelines.yml`.

## 🧠 How Detection Works

ShipKit reads your existing files — it never asks what it can detect:

| What | Reads from |
|---|---|
| Framework | `package.json` dependencies (next, react, vue, express, etc.) |
| Scripts | `package.json` scripts — only includes what exists |
| Package manager | `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb` |
| Node version | `.nvmrc`, `.node-version`, or `engines.node` |
| Git platform | `git remote origin URL` (GitHub / GitLab / Bitbucket) |
| Deploy URL | `vercel.json`, `fly.toml`, or `package.json` homepage |
| Monorepo | Scans `frontend/`, `backend/`, `web/` subdirectories |
| Non-Node | Detects `pyproject.toml`, `go.mod`, `Cargo.toml`, `docker-compose.yml` |

## 📋 Commands

| Command | Description |
|---|---|
| `npx shipkit-pipe` | Auto-detect & generate (default, no prompts) |
| `npx shipkit-pipe --dry-run` | Preview what would be generated |
| `npx shipkit-pipe check` | Validate CI, ping site, check deps |
| `npx shipkit-pipe check --json` | Machine-readable check output |
| `npx shipkit-pipe upgrade` | Check for newer version |
| `npx shipkit-pipe --force` | Overwrite existing files |
| `npx shipkit-pipe -i` | Interactive mode (ask questions) |
| `npx shipkit-pipe --help` | Show help |
| `npx shipkit-pipe --version` | Show version |

## 🔧 Alternate Install Methods

```bash
# Linux / macOS (no Node.js?):
curl -fsSL https://raw.githubusercontent.com/sagar-grv/shipkit/main/setup.sh | bash

# Windows PowerShell:
irm https://raw.githubusercontent.com/sagar-grv/shipkit/main/setup.ps1 | iex

# Or globally:
npm install -g shipkit-pipe
```

## 🏗️ What You Get

### Smart CI/CD
Generates GitHub Actions (or GitLab CI, or Bitbucket Pipelines) that only include steps for scripts that exist in your `package.json`. Have a `lint` script? You get a lint step. No `test` script? No test step. **Your CI never fails because of bad config.**

### Health Monitoring
A GitHub Action workflow pings your production site every 6 hours. If it's down → auto-creates a GitHub Issue. When it recovers → auto-closes the issue. **You know before your users do.**

### Security Scanning
CodeQL scans every push + PR for vulnerabilities. Dependabot opens auto-PRs when dependencies need updates. **No manual checking.**

### AI Agent Memory
Generates `AGENTS.md` and `shipkit.json` so your AI agent (Claude Code, Cursor, GitHub Copilot, OpenCode) knows your stack, your rules, and what happened last session.

## 🔐 Security Gates

| Gate | What It Catches | When | Who |
|---|---|---|---|
| CI (lint → test → build) | Code quality, broken tests, build failures | Push / PR | Auto |
| CodeQL | 100+ vulnerability classes | Every push | Auto |
| Dependabot | Vulnerable npm/GitHub Actions deps | Weekly | Auto |
| Health check | Site down / unreachable | Every 6h | Auto |

## 🤝 Supported Platforms

| Category | Supported |
|---|---|
| **Git platforms** | GitHub, GitLab, Bitbucket |
| **AI Agents** | Claude Code, Cursor, GitHub Copilot, OpenCode, CodeGPT, any |
| **Frontend** | Next.js, React, Vue, Svelte, Astro, Nuxt, Express, any |
| **Backend** | Node.js, Python, Go, Rust, Docker |
| **Deploy** | Vercel, Netlify, Fly.io, Railway, Render, Docker, any |
| **Package Managers** | npm, pnpm, yarn, bun |
| **Project types** | Single app, monorepo, empty directory, any framework |

## 📄 License

Apache 2.0 — Free to use, modify, and share.

---

**ShipKit** — Because your solo project deserves a production pipeline.
