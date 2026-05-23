# ShipKit — MVP to Production Pipeline

> **Connect your tools. Ship to production. No team required.**

[![License](https://img.shields.io/badge/License-Apache%202.0%20%2B%20Ethical-blue.svg)](LICENSE)

ShipKit is an open-source orchestration layer that takes any MVP and turns it into a production-grade application — automatically.

**You bring your code and your tools. ShipKit connects everything together.**

Your AI agent learns the stack. CI/CD runs on every push. Security scans every PR. Pre-commit hooks catch issues locally. Session continuity keeps your AI agent context-aware. All from a single command.

---

## ✨ What Makes ShipKit Different

| Without ShipKit | With ShipKit |
|---|---|
| Manually configure CI/CD for every project | One command generates CI/CD, security, hooks |
| Write separate prompts for your AI agent | AI agent auto-reads `shipkit.json` — knows your stack |
| No session memory — AI forgets context every time | AGENTS.md + LAST_SESSION.md = persistent context |
| Set up security scanning manually | CodeQL + Security Reviewer prompt built-in |
| No production monitoring | Monitor Agent checks health every session |
| Solo dev acts as PM + Engineer + QA + Security + DevOps + SRE | 6 AI agent roles replace the team |

---

## 🚀 Quick Start

```bash
# In your project directory:
npx shipkit setup
# or: curl -fsSL https://shipkit.dev/setup.sh | bash
# or: irm https://shipkit.dev/setup.ps1 | powershell

# Answer 5 quick questions about your tools:
# → What AI agent do you use? (Claude Code / Cursor / Copilot / OpenCode / Custom)
# → Authenticate to GitHub
# → Deploy platform? (Vercel / Netlify / Fly.io / Railway / Docker / Custom)
# → Database? (Supabase / Firebase / MongoDB / PostgreSQL / SQLite)
# → Optional: Sentry for error tracking?

# That's it. Your production pipeline is ready.
```

**What happens under the hood:**

| File | Purpose |
|---|---|
| `shipkit.json` | Config — your stack, tools, auth. AI agent reads this at startup |
| `AGENTS.md` | Universal AI agent protocol — works with any AI tool |
| `.github/workflows/ci.yml` | Lint → typecheck → test → build on every PR |
| `.github/workflows/codeql.yml` | Security vulnerability scan |
| `.github/dependabot.yml` | Weekly dependency updates |
| `.husky/pre-commit` | Catch secrets, lint errors before they reach Git |
| `ROADMAP.md` | Feature tracker — AI agent stays aligned |
| `BUGS.md` | Bug tracker — root cause documented |
| `LAST_SESSION.md` | Session continuity — AI never forgets context |

---

## 🔄 How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR PROJECT                              │
│  (any stack — Next.js, React, Vue, Python, Go, anything)    │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                     SHIPKIT LAYER                            │
│                                                              │
│  shipkit.json ──► AI agent learns your stack + tools         │
│  AGENTS.md    ──► Universal behavior protocol                │
│  .github/     ──► CI/CD + Security + Dependencies            │
│  .husky/      ──► Pre-commit quality gates                   │
│  ROADMAP.md   ──► Feature planning                           │
│  BUGS.md      ──► Bug tracking                              │
│  LAST_SESSION.md ──► Session memory                          │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   YOUR TOOLS (anything)                      │
│                                                              │
│  AI Agent: Claude Code / Cursor / Copilot / OpenCode / ...  │
│  Deploy:   Vercel / Netlify / Fly.io / Railway / Docker     │
│  Database: Supabase / Firebase / MongoDB / PostgreSQL        │
│  IDE:      VS Code / JetBrains / Cursor / Vim / ...          │
│  Monitor:  Sentry / Datadog / PostHog / LogRocket            │
└─────────────────────────────────────────────────────────────┘
```

### The Development Pipeline

```
You say "plan: <feature>"
    │
    ▼
┌─────────────────────────────────────┐
│ ① PLANNER (AI Agent)                │
│   Reads state → writes plan         │
│   Gate: You approve                  │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ ② BUILDER (AI Agent)                │
│   Implements in small steps         │
│   Self-checks: lint → test → build  │
│   Pre-commit: catches issues        │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ ③ SECURITY REVIEW (AI Agent)        │
│   Checks: secrets, XSS, auth, DB    │
│   Gate: APPROVED / CHANGES REQUIRED │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ ④ CI/CD (GitHub Actions)            │
│   Lint → Typecheck → Test → Build   │
│   CodeQL security scan              │
│   E2E tests on preview              │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ ⑤ DEPLOY (auto)                     │
│   Merge → Deploy → Live             │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ ⑥ MONITOR (AI Agent)                │
│   Checks health every session       │
│   RCA on errors → BUGS.md → fix PR  │
└─────────────────────────────────────┘
```

---

## 🧠 AI Agent Team

ShipKit gives your AI agent 6 distinct **roles** — each with a dedicated prompt file. Your AI agent reads the right prompt for each stage of development.

| Role | Prompt File | What It Does |
|---|---|---|
| **Planner** (PM + Eng Lead) | `shipkit/planner.md` | Reads state → writes plan with tasks, architecture, rollback |
| **Builder** (Developer) | `shipkit/co-developer.md` | Writes code in small steps, runs tests, commits |
| **QA** (Tester) | (built into Builder) | Ensures test coverage, runs test suite |
| **Security Reviewer** | `shipkit/security-reviewer.md` | 10-category audit → APPROVED or CHANGES REQUIRED |
| **DevOps** | GitHub Actions (auto) | CI pipeline + CodeQL + E2E |
| **Monitor** (SRE) | `shipkit/monitor.md` | Health checks, root cause analysis, DORA metrics |

### Works With Any AI Agent

ShipKit's prompt files are **plain Markdown** — compatible with every AI coding tool:

| AI Tool | How It Reads ShipKit |
|---|---|
| **Claude Code** | Reads `AGENTS.md` + `CLAUDE.md` at session start |
| **Cursor** | Reads `.cursorrules` + `AGENTS.md` |
| **GitHub Copilot** | Reads `.github/copilot-instructions.md` |
| **OpenCode** | Reads `.opencode/agents/*.md` |
| **CodeGPT** | Reads `AGENTS.md` on project open |
| **Continue.dev** | Reads `AGENTS.md` from config |
| **Any AI agent** | Reads `AGENTS.md` + `shipkit.json` — adapts automatically |

> **No lock-in.** Switch AI tools anytime. ShipKit's protocol works with all of them.

---

## 🔧 Setup

ShipKit offers 3 ways to get started:

### 1. Interactive (Recommended)

```bash
npx shipkit setup
```

A guided interview that asks about your tools and generates everything. Takes ~2 minutes.

### 2. One-Line Script

```bash
# Linux / macOS:
curl -fsSL https://shipkit.dev/setup.sh | bash

# Windows PowerShell:
irm https://shipkit.dev/setup.ps1 | powershell
```

### 3. Headless / CI Mode

Create a `shipkit.config.json` file, then:

```bash
npx shipkit setup --config shipkit.config.json
```

---

## 🔐 How the AI Agent Adapts

ShipKit generates a `shipkit.json` file that your AI agent reads at every session start:

```json
{
  "project": {
    "name": "MyApp",
    "description": "A web application"
  },
  "stack": {
    "frontend": "Next.js 15+",
    "database": "Supabase Postgres",
    "auth": "Supabase Auth",
    "ai": "Gemini API",
    "deploy": "Vercel",
    "monitoring": "Sentry"
  },
  "ci": {
    "nodeVersion": "20",
    "buildCommand": "npm run build",
    "testCommand": "npm test"
  },
  "auth": {
    "githubToken": "ghp_***",
    "vercelToken": "***",
    "supabaseKey": "***"
  }
}
```

Your AI agent automatically:
- Uses the right build/test/lint commands
- Checks the correct deploy platform for logs
- Adapts security review to your database type
- Warns before production database changes
- Tracks DORA metrics relevant to your stack

---

## 🛡️ Security Gates (Staged)

| Gate | What It Catches | When | Who |
|---|---|---|---|
| Husky pre-commit | Secrets in staged files, lint errors, type errors | `git commit` | Local |
| Security Reviewer | SQL injection, XSS, RLS bypass, env exposure, auth bugs | Before push | AI Agent |
| CI (lint → typecheck → test → build) | Code quality, broken tests, build failures | PR created | Auto |
| CodeQL | 100+ vulnerability classes | PR + main | Auto |
| Dependabot | Vulnerable npm/GitHub Actions deps | Weekly | Auto |
| Monitor Agent | Error trends, performance regression, bug debt | Every session | AI Agent |

---

## 📊 DORA Metrics

ShipKit tracks the 4 key DevOps metrics that separate high-performing teams from everyone else:

| Metric | How to Track | What Good Looks Like |
|---|---|---|
| **Deploy Frequency** | Deploy platform logs | Multiple / week |
| **Lead Time** | Plan → merged PR time | < 1 day |
| **Change Failure Rate** | Errors / deploys (monitoring) | < 15% |
| **MTTR** | Error → fix deployed | < 1 hour |

The Monitor Agent tracks these at every session start and updates LAST_SESSION.md with trends.

---

## 📁 Project Structure

After running ShipKit setup, your project looks like this:

```
your-project/
├── shipkit.json               ← Config (source of truth)
├── AGENTS.md                  ← Universal AI agent protocol
├── ROADMAP.md                 ← Feature tracker
├── BUGS.md                    ← Bug tracker
├── LAST_SESSION.md            ← Session continuity
├── shipkit/                   ← AI agent prompts
│   ├── planner.md
│   ├── co-developer.md
│   ├── security-reviewer.md
│   └── monitor.md
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       ├── ci.yml
│       ├── codeql.yml
│       └── playwright.yml
├── .husky/pre-commit
└── .github/copilot-instructions.md   (if Copilot)
    .cursorrules                       (if Cursor)
    CLAUDE.md                          (if Claude Code)
    .opencode/agents/                  (if OpenCode)
```

---

## 🤝 Supported Platforms

ShipKit works with any combination of tools. Here are the most common:

| Category | Supported |
|---|---|
| **AI Agents** | Claude Code, Cursor, GitHub Copilot, OpenCode, CodeGPT, Continue.dev, Cline, Aider |
| **IDEs** | VS Code, JetBrains, Cursor, Windsurf, Vim/Neovim, Emacs |
| **Frontend** | Next.js, React, Vue, Svelte, Angular, Solid, Qwik, Remix, Nuxt, Astro, plain HTML/CSS/JS |
| **Backend** | Node.js, Python, Go, Rust, Ruby, PHP, Java, .NET, Deno, Bun |
| **Database** | Supabase, Firebase, MongoDB, PostgreSQL, MySQL, SQLite, Prisma, Drizzle |
| **Auth** | Supabase Auth, Firebase Auth, Clerk, Auth0, NextAuth, Lucia |
| **Deploy** | Vercel, Netlify, Fly.io, Railway, Render, Cloudflare, Docker, AWS, GCP |
| **Monitoring** | Sentry, Datadog, LogRocket, PostHog, Grafana, OpenTelemetry |
| **Package Managers** | npm, pnpm, yarn, bun, pip, cargo, go mod, gem, composer |

---

## 🗺️ Roadmap

- [ ] **ShipKit CLI** — `npx shipkit` with commands: `setup`, `check`, `update`, `doctor`
- [ ] **Auto-detect** — ShipKit reads your project and detects framework, database, deploy config automatically
- [ ] **One-click deploy** — `shipkit deploy` that handles the full deploy flow
- [ ] **Dashboard** — Web UI to see pipeline status, DORA metrics, security alerts
- [ ] **Multi-service** — Support for monorepos and microservices
- [ ] **GitLab / Bitbucket** — Support for alternative Git providers
- [ ] **VS Code extension** — One-click ShipKit install from VS Code

---

## 📄 License

Apache 2.0 + Additional Ethical Use Terms — see [LICENSE](LICENSE).

Free to use, modify, and share. Built for the solo developer community.

---

## 💬 Why ShipKit?

> *"I spent more time setting up CI/CD, writing AI prompts, and managing context than actually coding. ShipKit does all of that in one command."*

> *"My AI agent used to forget the stack after every session. Now it reads shipkit.json and knows everything."*

> *"I'm one person competing against teams of six. ShipKit gives me the same pipeline."*

---

**ShipKit** — Because your MVP deserves a production pipeline.
