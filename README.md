
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/shipkit-%E2%9C%A6-violet?style=for-the-badge&logo=github&logoColor=white&labelColor=%23111111">
    <img alt="shipkit" src="https://img.shields.io/badge/shipkit-%E2%9C%A6-violet?style=for-the-badge&logo=github&logoColor=white&labelColor=%23ffffff">
  </picture>
</p>

<p align="center">
  <b>Replace a 6-person engineering team with AI agents + industry-standard CI/CD.</b><br>
  <i>From MVP to production in 10 minutes. Stack-agnostic. Solo-dev-first. Production-grade.</i>
</p>

<p align="center">
  <a href="#-quick-start"><img src="https://img.shields.io/badge/Quick_Start-%E2%86%92-blue?style=flat-square" alt="Quick Start"></a>
  <a href="#-the-ai-agent-team"><img src="https://img.shields.io/badge/AI_Agents-%E2%86%92-purple?style=flat-square" alt="AI Agents"></a>
  <a href="#-approaches--methods"><img src="https://img.shields.io/badge/Approaches-%E2%86%92-green?style=flat-square" alt="Approaches"></a>
  <a href="#%EF%B8%8F-license"><img src="https://img.shields.io/badge/License-%E2%86%92-orange?style=flat-square" alt="License"></a>
  <br>
  <a href="https://github.com/sagar-grv/healthvault" target="_blank"><img src="https://img.shields.io/badge/built_for-HealthVault-00c853?style=flat-square" alt="Built for HealthVault"></a>
  <img src="https://img.shields.io/github/stars/sagar-grv/shipkit?style=flat-square&color=yellow" alt="Stars">
  <img src="https://img.shields.io/github/license/sagar-grv/shipkit?style=flat-square" alt="License">
  <a href="https://github.com/sagar-grv/shipkit/graphs/contributors"><img src="https://img.shields.io/github/contributors/sagar-grv/shipkit?style=flat-square" alt="Contributors"></a>
</p>

---

## 🚢 What Is ShipKit?

ShipKit is a **complete production pipeline** for solo developers and small teams. It gives you:

| What you get | Instead of |
|---|---|
| 4 AI agents = your product team | Hiring a PM, Security Engineer, SRE, and QA |
| Industry-standard CI/CD | Writing YAML from scratch |
| Pre-commit quality gates | Fixing bugs after they reach production |
| Automated dependency updates | Weekly manual npm audit sessions |
| Security scanning on every PR | Discovering vulnerabilities after deploy |
| Session continuity for AI agents | Starting from scratch every conversation |

It's a **template you drop into any project** — Next.js, React, Vue, Svelte, any database, any cloud. One command, 10 minutes, done.

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
# Copy ShipKit into your project
curl -fsSL https://github.com/sagar-grv/shipkit/archive/main.tar.gz | tar -xz --strip=1 shipkit-main
# Or: git submodule add https://github.com/sagar-grv/shipkit.git

# Run interactive setup (asks 15 questions about your stack)
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

### How the AI Agents See Your Project

Every agent reads `pipeline.json` at session start to understand your stack:

```json
{
  "project": {
    "name": "MyApp",
    "description": "A social media dashboard"
  },
  "stack": {
    "frontend": "Next.js 15+",
    "database": "Supabase Postgres",
    "auth": "Supabase Auth",
    "deploy": "Vercel"
  },
  "ci": {
    "buildCommand": "npm run build",
    "testCommand": "npm test"
  }
}
```

This makes ShipKit **fully stack-agnostic**. The same agent files work for Next.js + Supabase, React + Firebase, SvelteKit + MongoDB — any combination.

---

## 🧠 The AI Agent Team

ShipKit replaces 6 engineering roles with **AI agents** — specialized prompts for your AI coding assistant. Each agent has a specific role, specific triggers, and specific gates.

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
┌─────────────────────────────────────────────────────────────────────────┐
│ ① PLANNER AGENT (planner.md)                                            │
│   Reads roadmap → checks for bugs → reviews last session                │
│   → writes plan.md with tasks, architecture, rollback strategy          │
│   GATE: User approves plan before execution                             │
└─────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ② BUILDER AGENT (co-developer.md)                                       │
│   Creates feature branch → implements in small steps (max 3)            │
│   → runs lint → tests → build on each step                              │
│   Pre-commit: Husky catches issues before commit                         │
└─────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ③ SECURITY REVIEWER (security-reviewer.md)                              │
│   Reviews full diff against main branch                                 │
│   Checks: secrets, DB security, XSS, auth, env exposure, upload safety  │
│   GATE: APPROVED or CHANGES REQUIRED verdict                            │
└─────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ④ GITHUB ACTIONS (CI/CD — fully automated)                              │
│   ┌──────────┐ ┌───────────┐ ┌───────┐ ┌────────┐ ┌──────────┐        │
│   │  Lint    │ │ TypeCheck │ │ Tests │ │ CodeQL │ │Playwright│        │
│   │          │ │           │ │       │ │Security│ │   E2E    │        │
│   └──────────┘ └───────────┘ └───────┘ └────────┘ └──────────┘        │
│   ALL must pass before merge                                            │
└─────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ⑤ AUTO-DEPLOY                                                           │
│   Merge PR → main → deploys → monitoring verifies                       │
└─────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ⑥ MONITOR AGENT (monitor.md)                                            │
│   Every session: checks health, CI status, dependencies, bugs           │
│   If errors: root cause analysis → fix proposal → BUGS.md entry         │
│   Tracks: DORA metrics, deploy frequency, MTTR                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6 Gates That Protect Your Production

| # | Gate | Catches | When | Who |
|---|---|---|---|---|
| 1 | **Husky pre-commit** | Secrets in staged files, lint errors, type errors | `git commit` | 💻 Local |
| 2 | **Security Reviewer** | RLS bypass, SQL injection, XSS, auth bugs | `review security` | 🤖 AI |
| 3 | **CI (lint → typecheck → test → build)** | Code quality, broken tests, build failures | PR created | ⚙️ Auto |
| 4 | **CodeQL** | 100+ vulnerability classes | PR + main | ⚙️ Auto |
| 5 | **Dependabot** | Vulnerable npm/GitHub Actions dependencies | Weekly | ⚙️ Auto |
| 6 | **Monitor Agent** | Error trends, performance regression, bug debt | Every session | 🤖 AI |

---

## 🛠️ Approaches & Methods

ShipKit is designed to work the way *you* work. Here are the different approaches:

### Method 1: Interactive Setup (Recommended)

The guided setup asks 15 questions about your project and generates everything:

```powershell
# Windows
.\shipkit\setup.ps1

# Linux / macOS
./shipkit/setup.sh
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
- Database project ID and region
- GitHub username and repo name
- Any custom environment variables

**Best for**: First-time setup, new projects, when you want a tailored configuration.

### Method 2: Headless / CI Setup

Use a config file for reproducible, automated setup:

```powershell
.\shipkit\setup.ps1 -ConfigFile my-project.json -Force
```

**Config file format** (`my-project.json`):
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

**Best for**: CI pipelines, reproducible builds, team onboarding, infrastructure-as-code workflows.

### Method 3: Manual / Selective Integration

Don't want everything? Pick and choose:

| Component | Files | What You Get |
|---|---|---|
| AI Agents only | `template/agents/*`, `template/docs/AGENTS.md` | The AI team without CI/CD |
| CI/CD only | `template/github/workflows/*`, `template/github/dependabot.yml` | GitHub Actions without agents |
| Pre-commit only | `template/husky/pre-commit` | Local quality gates only |
| Session tracking | `template/docs/*` | Project management docs |
| Everything | Run setup.ps1 | Complete pipeline |

**Best for**: Existing projects with partial tooling, gradual adoption, custom toolchains.

### Method 4: Stack-Specific Approaches

#### Next.js + Supabase (The Reference Architecture)
Used by [HealthVault](https://github.com/sagar-grv/healthvault) in production:
- Next.js 15+ App Router with React Server Components
- Supabase Postgres with Row Level Security
- Vercel deployment with preview URLs
- Playwright E2E on preview deployments
- Sentry error tracking
- Result: **49/49 tests passing, 0 lint errors, 0 type errors, 18 routes compiled**

#### React + Vite + Firebase
Quick adaptation:
- Vite for fast dev builds
- Firebase Firestore with security rules
- Firebase Auth for authentication
- Firebase Hosting or Netlify for deploy
- Cypress or Playwright for E2E

#### SvelteKit + MongoDB
Adapting the template:
- SvelteKit for frontend
- MongoDB with Mongoose for data
- Auth0 or NextAuth for auth
- Railway or Fly.io for deploy
- The Security Reviewer adapts to check MongoDB injection instead of SQL

### Method 5: Solo Dev Workflow

The daily workflow ShipKit was built for:

```bash
# Morning — start session
# 1. Run Monitor Agent to check production health
# 2. Check BUGS.md for any open issues
# 3. Review ROADMAP.md for today's priorities

# Feature development
# 1. Say "plan: <feature>" → Planner creates a plan
# 2. Approve the plan → Builder implements it
# 3. Say "review security" → Security Reviewer checks everything
# 4. Push → PR → CI runs → Merge → Deploy

# Evening — end session
# 1. Update LAST_SESSION.md with what was done
# 2. Update ROADMAP.md with progress
# 3. Run "check errors" for overnight monitoring
```

### Method 6: Small Team Workflow

Add a `CONTRIBUTING.md` and enforce:
- All PRs require Security Reviewer approval
- All PRs require CI to pass
- Use Planner for sprint planning sessions
- Monitor Agent runs at daily standup

---

## 📂 What You Get

```
your-project/
├── pipeline.json                ← Source of truth — all agents read this
├── AGENTS.md                   ← The Solo Dev Agent Protocol
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
├── .opencode/agents/
│   ├── planner.md              ← PM + Engineering Lead (plan: <feature>)
│   ├── security-reviewer.md    ← Security Engineer (review security)
│   ├── monitor.md              ← SRE + Incident Commander (check errors)
│   └── co-developer.md         ← Developer + QA (default build agent)
│
└── .husky/pre-commit           ← Lint-staged pre-commit quality gate
```

---

## 🔐 Security Features (6 Layers)

| Layer | What It Prevents | How |
|---|---|---|
| **Pre-commit** | Secrets committed to Git | `husky` + `lint-staged` scan staged files |
| **AI Security Review** | RLS bypass, SQL injection, XSS, auth bugs | 10-category checklist, stack-adaptive |
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

## 🗺️ Roadmap

- [x] AI Agent team (Planner, Builder, Security Reviewer, Monitor)
- [x] GitHub Actions CI/CD (lint, typecheck, test, build)
- [x] CodeQL security scanning
- [x] Playwright E2E test workflow
- [x] Dependabot dependency updates
- [x] Husky pre-commit hooks
- [x] Interactive setup script (PowerShell)
- [x] Stack-agnostic template system
- [x] Session continuity (LAST_SESSION.md)
- [x] DORA metrics tracking
- [ ] Linux/macOS setup script (setup.sh)
- [ ] Docker dev environment template
- [ ] Community agent library (user-contributed agents)
- [ ] VSCode extension (one-click setup)
- [ ] GitHub Action template marketplace listing
- [ ] Video guide: "ShipKit in 10 minutes"

---

## 🧪 Real-World Usage: HealthVault

ShipKit was built for and battle-tested on **[HealthVault](https://github.com/sagar-grv/healthvault)** — a medical report management platform built by a solo developer:

- **Stack**: Next.js 15+ · Supabase Postgres · Gemini AI · Vercel
- **Users**: Patients + Doctors + Admins
- **Features**: Report upload, AI analysis, doctor search, access control
- **Pipeline stats**: 49 tests · 0 lint errors · 0 type errors · 18 routes
- **CI/CD**: Auto-deploy from PR merge · CodeQL on every push · Playwright E2E
- **Dependabot**: 10+ PRs merged, all safe, all automated

> *"ShipKit replaced what would have been a 6-person team. I build HealthVault alone — the Planner designs features, the Security Reviewer catches vulnerabilities, and the Monitor checks production health every session."*
> — [@sagar-grv](https://github.com/sagar-grv), solo developer

---

## 📖 How to Talk to Your AI Agent Team

| You Say | What Happens |
|---|---|
| `plan: add user profile page` | Planner reads state, writes a plan with tasks |
| `plan this: implement dark mode` | Planner designs the approach |
| `review security` | Security Reviewer analyzes current diff |
| `check errors` | Monitor checks all systems |
| `what's the status` | Monitor generates a full health report |
| `start a fix branch for BUG-3` | Builder creates fix branch, implements the fix |

---

## 🔧 Required GitHub Secrets

After pushing to GitHub, add these in **Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| Your public URL (e.g. `NEXT_PUBLIC_SUPABASE_URL`) | From your project dashboard |
| Your public key (e.g. `NEXT_PUBLIC_SUPABASE_ANON_KEY`) | From your project dashboard |
| Any custom env vars you specified during setup | As configured |

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
  <a href="https://github.com/sagar-grv/healthvault">HealthVault</a> ·
  <a href="https://github.com/sagar-grv/shipkit/issues">Issues</a> ·
  <a href="https://github.com/sagar-grv/shipkit/discussions">Discussions</a>
</p>

<p align="center">
  <a href="#-what-is-shipkit">↑ Back to top</a>
</p>
