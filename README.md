
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/shipkit-%E2%9C%A6-violet?style=for-the-badge&logo=github&logoColor=white&labelColor=%23111111">
    <img alt="shipkit" src="https://img.shields.io/badge/shipkit-%E2%9C%A6-violet?style=for-the-badge&logo=github&logoColor=white&labelColor=%23ffffff">
  </picture>
</p>

<p align="center">
  <b>Replace a 6-person engineering team with AI agents + industry-standard CI/CD.</b><br>
  <i>Drop into any project. Works with any AI agent. Any IDE. Any stack. 10 minutes.</i>
</p>

<p align="center">
  <a href="#-quick-start"><img src="https://img.shields.io/badge/Quick_Start-%E2%86%92-blue?style=flat-square" alt="Quick Start"></a>
  <a href="#-the-ai-agent-team"><img src="https://img.shields.io/badge/AI_Agents-%E2%86%92-purple?style=flat-square" alt="AI Agents"></a>
  <a href="#%EF%B8%8F-approaches--methods"><img src="https://img.shields.io/badge/Approaches-%E2%86%92-green?style=flat-square" alt="Approaches"></a>
  <a href="#%EF%B8%8F-license"><img src="https://img.shields.io/badge/License-%E2%86%92-orange?style=flat-square" alt="License"></a>
  <br>
  <img src="https://img.shields.io/github/stars/sagar-grv/shipkit?style=flat-square&color=yellow" alt="Stars">
  <img src="https://img.shields.io/github/license/sagar-grv/shipkit?style=flat-square" alt="License">
  <a href="https://github.com/sagar-grv/shipkit/graphs/contributors"><img src="https://img.shields.io/github/contributors/sagar-grv/shipkit?style=flat-square" alt="Contributors"></a>
</p>

---

## 🚢 What Is ShipKit?

ShipKit is a **production pipeline template** for solo developers and small teams. Drop it into any project and instantly get:

| What you get | Instead of |
|---|---|
| 4 AI agents = your product team | Hiring a PM, Security Engineer, SRE, and QA |
| Industry-standard CI/CD | Writing YAML from scratch |
| Pre-commit quality gates | Fixing bugs after they reach production |
| Automated dependency updates | Weekly manual security audits |
| Security scanning on every PR | Discovering vulnerabilities after deploy |
| Session continuity for AI agents | Starting from scratch every conversation |

**It works with any tech stack** — Next.js, React, Vue, Svelte, Astro, Remix. Any database. Any cloud. Any AI agent (Claude, ChatGPT, Copilot, Cursor, OpenCode, Cline). Any IDE.

### The Problem It Solves

As a solo developer or small team, you're competing against companies with 6+ engineers who have:

- A **PM** who tracks requirements and prevents scope creep
- An **Engineering Lead** who designs architecture and plans sprints
- A **Security Engineer** who reviews every PR for vulnerabilities
- An **SRE** who monitors production and responds to incidents
- A **DevOps Engineer** who maintains CI/CD pipelines
- A **QA Engineer** who catches regressions before they ship

ShipKit gives you **all of them** as AI agents + automation. Not a SaaS subscription. Not another tool to learn. Just files you add to your project.

---

## 🔥 Quick Start

### 1. Install in any project

```bash
# Download ShipKit into your project
curl -fsSL https://github.com/sagar-grv/shipkit/archive/main.tar.gz | tar -xz --strip=1 shipkit-main
# Or: git submodule add https://github.com/sagar-grv/shipkit.git

# Run interactive setup
./setup.ps1        # Windows
# or
./setup.sh         # Linux / macOS
```

### 2. Install dependencies

```bash
npm install --save-dev husky lint-staged prettier
npx husky init
```

### 3. Push to GitHub

```bash
git add .
git commit -m "chore: add ShipKit production pipeline"
git push origin main
```

**That's it.** Your project now has:
- AI agents that act as your team
- CI/CD that runs on every PR
- Security scanning on every commit
- A system that remembers context between sessions

### How It Works With Your AI Agent

ShipKit's agent prompts are **plain markdown files**. Load them into any AI tool:

| AI Tool | How to Use ShipKit Agents |
|---|---|
| **Claude** (you're here) | Reference `agents/*.md` in your CLAUDE.md or project instructions |
| **ChatGPT / Gemini** | Paste the relevant agent prompt before starting a task |
| **GitHub Copilot** | Add to `.github/copilot-instructions.md` |
| **Cursor** | Add to `.cursorrules` or `.cursor/rules/` |
| **Cline** | Add to `.clinerules` |
| **OpenCode** | Place in `.opencode/agents/` (setup does this automatically) |
| **Windsurf** | Add to `.windsurfrules` |
| **Any AI CLI** | Pass the file: `cat agents/planner.md | ...` |

The setup script generates everything. You just run it and tell your AI assistant about the files.

---

## 🧠 The AI Agent Team

ShipKit replaces 6 engineering roles with **AI agent prompts** — plain markdown files you load into your AI coding assistant. Each has a specific role, specific triggers, and specific gates.

### Team Roster

| Role | Agent | How to Invoke | What It Does |
|---|---|---|---|
| **Product Manager + Engineering Lead** | Planner | `plan: <feature>` | Reads project state, writes detailed plans with architecture and rollback strategy |
| **Developer + QA** | Builder | *(default agent)* | Writes code in small increments, runs tests, commits |
| **Security Engineer** | Security Reviewer | `review security` | 10-category security audit of every diff before it ships |
| **SRE + Incident Commander** | Monitor | Session start + `check errors` | Checks production health, tracks DORA metrics, initiates incident response |
| **DevOps Engineer** | GitHub Actions | *(auto on PR)* | CI pipeline, CodeQL security scan, Playwright E2E |
| **Dependency Manager** | Dependabot | *(weekly auto)* | Keeps npm + Actions dependencies updated |

### How They Work Together

```
You say "plan: <feature>"
    │
    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ ① PLANNER AGENT (agents/planner.md)                                     │
│   Reads roadmap → checks for bugs → reviews last session                │
│   → writes plan with tasks, architecture, rollback strategy             │
│   GATE: User approves plan before execution                              │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ ② BUILDER AGENT (agents/co-developer.md)                                │
│   Creates feature branch → implements in small steps (max 3)            │
│   → runs lint → tests → build on each step                              │
│   Pre-commit: Husky catches issues before commit                         │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ ③ SECURITY REVIEWER (agents/security-reviewer.md)                       │
│   Reviews full diff against main branch                                 │
│   Checks: secrets, DB security, XSS, auth, env exposure, upload safety  │
│   GATE: APPROVED or CHANGES REQUIRED verdict                             │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ ④ GITHUB ACTIONS (CI/CD — fully automated)                              │
│   ┌──────────┐ ┌───────────┐ ┌───────┐ ┌────────┐ ┌──────────┐         │
│   │  Lint    │ │ TypeCheck │ │ Tests │ │ CodeQL │ │Playwright│         │
│   │          │ │           │ │       │ │Security│ │   E2E    │         │
│   └──────────┘ └───────────┘ └───────┘ └────────┘ └──────────┘         │
│   ALL must pass before merge                                             │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ ⑤ AUTO-DEPLOY                                                            │
│   Merge PR → main → deploys → monitoring verifies                        │
└──────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ ⑥ MONITOR AGENT (agents/monitor.md)                                     │
│   Every session: checks health, CI status, dependencies, bugs           │
│   If errors: root cause analysis → fix proposal → BUGS.md entry         │
│   Tracks: DORA metrics, deploy frequency, MTTR                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### 6 Gates That Protect Your Production

| # | Gate | Catches | When | Who |
|---|---|---|---|---|
| 1 | **Husky pre-commit** | Secrets in staged files, lint errors, type errors | `git commit` | 💻 Local |
| 2 | **Security Reviewer** | SQL injection, XSS, auth bypass, secret leaks | `review security` | 🤖 AI |
| 3 | **CI (lint → typecheck → test → build)** | Code quality, broken tests, build failures | PR created | ⚙️ Auto |
| 4 | **CodeQL** | 100+ vulnerability classes | PR + main | ⚙️ Auto |
| 5 | **Dependabot** | Vulnerable dependencies | Weekly | ⚙️ Auto |
| 6 | **Monitor Agent** | Error trends, performance regression, bug debt | Every session | 🤖 AI |

---

## 🛠️ Approaches & Methods

### Method 1: Interactive Setup (Recommended)

The guided setup asks about your project and generates everything:

```bash
./setup.ps1        # Windows
./setup.sh         # Linux / macOS
```

**What it asks:**
- Project name and description
- Frontend framework (Next.js, Vite, Nuxt, SvelteKit, Remix, Other)
- Database (Supabase, Firebase, MongoDB, PostgreSQL, SQLite, None)
- Auth (Supabase Auth, Firebase Auth, Clerk, Auth0, NextAuth, Custom)
- AI provider (Gemini, OpenAI, Claude, Hugging Face, or none)
- Deploy platform (Vercel, Netlify, Fly.io, Railway, Cloudflare, Self-hosted)
- E2E framework (Playwright, Cypress, or none)
- Error tracking (Sentry, LogRocket, Datadog, PostHog, or none)
- Node version, package manager, build/test commands
- GitHub username and repo name

**Best for**: First-time setup, new projects, tailored configuration.

### Method 2: Headless / CI Setup

Use a config file for automated setup:

```bash
./setup.ps1 -ConfigFile my-project.json -Force
./setup.sh -c my-project.json
```

**Config file example:**
```json
{
  "project": {
    "name": "MySaaS",
    "description": "A SaaS analytics platform"
  },
  "stack": {
    "frontend": "Next.js 15+",
    "database": "Supabase Postgres",
    "auth": "Clerk",
    "ai": "OpenAI API",
    "deploy": "Vercel",
    "e2e": "Playwright",
    "analytics": "Sentry"
  },
  "ci": {
    "nodeVersion": "20",
    "packageManager": "npm",
    "buildCommand": "npm run build",
    "testCommand": "npm test"
  },
  "github": {
    "owner": "my-org",
    "repo": "my-saas"
  }
}
```

**Best for**: CI pipelines, reproducible builds, team onboarding.

### Method 3: Manual / Selective Integration

Don't want the full pipeline? Pick what you need:

| Component | Files | What You Get |
|---|---|---|
| **AI Agents only** | `agents/*`, `AGENTS.md` | Your AI product team without CI/CD |
| **CI/CD only** | `.github/workflows/*`, `.github/dependabot.yml` | GitHub Actions without agents |
| **Pre-commit only** | `.husky/pre-commit` | Local quality gates only |
| **Session tracking** | `ROADMAP.md`, `BUGS.md`, `LAST_SESSION.md` | Project management docs |
| **Everything** | Run `setup.ps1` / `setup.sh` | Complete production pipeline |

**Best for**: Existing projects with partial tooling, gradual adoption.

### Method 4: Solo Dev Workflow

The daily workflow ShipKit is built for:

```bash
# Morning — start session
# 1. Tell your AI agent: "run monitor check"
# 2. Review BUGS.md for any open issues
# 3. Check ROADMAP.md for today's priorities

# Feature development
# 1. Say "plan: <feature>" → Planner creates a plan
# 2. Approve → Builder implements it
# 3. Say "review security" → Security Reviewer checks
# 4. Push → PR → CI runs → Merge → Deploy

# Evening — end session
# 1. Update LAST_SESSION.md
# 2. Update ROADMAP.md with progress
```

### Method 5: Small Team Workflow

- All PRs require Security Reviewer approval
- All PRs require CI to pass
- Use Planner for sprint planning sessions
- Monitor Agent runs at daily standup

### Method 6: Any AI Agent / Any IDE

ShipKit agents are **plain markdown** — they work everywhere:

```
# Claude Desktop / Web
→ Upload or reference agents/planner.md in your project instructions

# ChatGPT
→ Paste the agent prompt before starting a task

# VS Code + Copilot
→ Include in .github/copilot-instructions.md

# Cursor
→ Add to .cursorrules or reference via @Agent

# OpenCode
→ Setup outputs to .opencode/agents/ automatically

# Cline
→ Add to .clinerules

# JetBrains AI
→ Reference in project settings

# Terminal / Any CLI
→ cat agents/planner.md | your-ai-command
```

---

## 📂 What You Get

```
your-project/
├── pipeline.json                ← Config — all agents read this
├── AGENTS.md                   ← Agent protocol and rules
├── ROADMAP.md                  ← Feature tracker with sprint planning
├── BUGS.md                     ← Bug tracker with severity levels
├── LAST_SESSION.md             ← Session continuity & DORA metrics
│
├── .github/
│   ├── dependabot.yml          ← Weekly dependency updates (grouped)
│   └── workflows/
│       ├── ci.yml              ← Lint → TypeCheck → Test → Build
│       ├── codeql.yml          ← GitHub's security vulnerability scanner
│       └── playwright.yml      ← E2E tests on preview deployments
│
├── agents/                     ← Your AI team (works with any AI agent)
│   ├── planner.md              ← PM + Engineering Lead
│   ├── security-reviewer.md    ← Security Engineer
│   ├── monitor.md              ← SRE + Incident Commander
│   └── co-developer.md         ← Developer + QA
│
└── .husky/pre-commit           ← Lint-staged pre-commit quality gate
```

---

## 🔐 Security (6 Layers)

| Layer | What It Prevents | How |
|---|---|---|
| **Pre-commit** | Secrets committed to Git | `husky` + `lint-staged` scan staged files |
| **AI Security Review** | SQL injection, XSS, auth bypass, secret leaks | 10-category checklist, stack-adaptive |
| **CI Pipeline** | Broken builds reach production | `lint → typecheck → test → build` |
| **CodeQL** | 100+ vulnerability classes | GitHub's CodeQL analysis engine |
| **Dependabot** | Vulnerable dependencies | Weekly automated PRs with grouped updates |
| **Monitor Agent** | Unknown errors in production | Session-start health checks + incident response |

---

## 📊 DORA Metrics (Tracked Automatically)

| Metric | How to Track | Solo Dev Target |
|---|---|---|
| **Deploy Frequency** | Deploy platform logs | Multiple times per week |
| **Lead Time** | Plan → merged PR time | < 1 day |
| **Change Failure Rate** | Errors / deploys | < 15% |
| **MTTR** | Error → fix deployed | < 1 hour |

Tracked by the Monitor Agent at every session start, updated in LAST_SESSION.md.

---

## ⚙️ Required GitHub Secrets

After pushing to GitHub, add these in **Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| Your public URL (e.g. `NEXT_PUBLIC_SUPABASE_URL`) | From your project dashboard |
| Your public key (e.g. `NEXT_PUBLIC_SUPABASE_ANON_KEY`) | From your project dashboard |
| Any custom env vars you specified during setup | As configured |

---

## 🗺️ Roadmap

- [x] AI Agent team (Planner, Builder, Security Reviewer, Monitor)
- [x] GitHub Actions CI/CD (lint, typecheck, test, build)
- [x] CodeQL security scanning
- [x] Playwright E2E test workflow
- [x] Dependabot dependency updates
- [x] Husky pre-commit hooks
- [x] Interactive setup scripts (PowerShell + Bash)
- [x] Stack-agnostic template system
- [x] Session continuity (LAST_SESSION.md)
- [x] DORA metrics tracking
- [x] AI-agent-agnostic (works with Claude, ChatGPT, Copilot, Cursor, OpenCode, Cline, etc.)
- [ ] Docker dev environment template
- [ ] Community agent library (user-contributed agents)
- [ ] IDE extension (one-click setup)
- [ ] Video guide series

---

## 🤝 Contributing

ShipKit is open source and community-driven. We welcome:

- **New agent templates** — adapt ShipKit to more stacks
- **Setup script improvements** — more platforms, better DX
- **Documentation** — translations, guides, tutorials
- **Bug reports** — found something? Open an issue

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

---

## ⚖️ License

**Apache 2.0 with Ethical Use Clause** — Full license in [LICENSE](./LICENSE).

You are free to:
- ✅ Use ShipKit in commercial projects
- ✅ Modify and distribute it
- ✅ Create proprietary forks (with attribution)
- ✅ Use it for any legal purpose

You may NOT:
- ❌ Use it for weapons, surveillance, or human rights violations
- ❌ Claim it as your own work (attribution required)
- ❌ Remove the license or attribution from derivative works

---

<p align="center">
  <b>Built by a solo developer, for solo developers.</b><br>
  <a href="https://github.com/sagar-grv">@sagar-grv</a> ·
  <a href="https://github.com/sagar-grv/shipkit/issues">Issues</a> ·
  <a href="https://github.com/sagar-grv/shipkit/discussions">Discussions</a>
</p>

<p align="center">
  <a href="#-what-is-shipkit">↑ Back to top</a>
</p>
