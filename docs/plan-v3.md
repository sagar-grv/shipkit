# ShipKit v3 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild ShipKit as a smart, zero-dependency CLI that only generates what your project actually needs, includes a health-check system, and a `check` command that verifies everything works — making it an automated team for solo devs.

**Architecture:** Single JS file CLI (`bin/shipkit-pipe.js`) with modern interactive UX (spinners, colors, progress indicators — all zero-dep). Smart detection reads `package.json` scripts to decide what CI steps to include. Health check is a GitHub Action cron workflow. `check` command pings deploy URL + validates config.

**Tech Stack:** Node.js 18+, zero npm dependencies, GitHub Actions YAML templates, Markdown templates for AI agent protocol.

---

## Design Principles

1. **Only generate what exists** — If no `lint` script, don't generate lint CI step
2. **Verify, don't assume** — `check` command validates everything
3. **Modern CLI UX** — Spinners, progress bars, clean output (like `create-next-app`)
4. **Works with ANY IDE, ANY LLM** — Not Claude-specific, not VS Code-specific
5. **Zero dependencies** — Entire package is `bin/` + `template/`, no `node_modules`

---

## File Structure

```
shipkit/
├── bin/
│   └── shipkit-pipe.js          ← CLI entry point (rewrite)
├── template/
│   ├── render.js                ← Template renderer (keep)
│   ├── github/
│   │   ├── dependabot.yml       ← Keep as-is
│   │   └── workflows/
│   │       ├── ci.yml           ← REWRITE: conditional steps
│   │       ├── health.yml       ← NEW: cron health check
│   │       └── codeql.yml       ← Keep as-is
│   ├── agents/
│   │   └── protocol.md          ← REWRITE: single file, simpler
│   └── docs/
│       ├── AGENTS.md            ← REWRITE: shorter, clearer
│       └── LAST_SESSION.md      ← Keep
├── package.json
└── README.md
```

### Key Changes from v2:
- Remove: `planner.md`, `security-reviewer.md`, `monitor.md`, `ROADMAP.md`, `BUGS.md`, `.husky/pre-commit`, `playwright.yml`
- Add: `health.yml` (cron health check), `check` command
- Rewrite: `ci.yml` (conditional), `AGENTS.md` (shorter), CLI (modern UX)
- Merge: All 4 agent files → 1 `protocol.md` (simpler)

### Why remove files:
- `planner.md`, `security-reviewer.md`, `monitor.md` → Overkill. One `AGENTS.md` is enough.
- `ROADMAP.md`, `BUGS.md` → Users have GitHub Issues/Projects. Don't duplicate.
- `.husky/pre-commit` → Users set up husky themselves. We shouldn't auto-touch their hooks.
- `playwright.yml` → Most solo devs don't have E2E tests. Generate only when detected.

---

## Task 1: Rewrite CLI with Modern UX

**Files:**
- Rewrite: `bin/shipkit-pipe.js`

**What changes:**
- Modern spinner/progress output (zero-dep, ANSI escape codes)
- Three commands: (default) generate, `check`, `--help`
- Smart detection: only include CI steps for scripts that exist
- Cleaner output: show what was detected, what was generated

- [ ] **Step 1: Create spinner utility (zero-dep)**

```javascript
function spinner(msg) {
  const frames = ['⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏'];
  let i = 0;
  const id = setInterval(() => {
    process.stdout.write(`\r  ${frames[i++ % frames.length]} ${msg}`);
  }, 80);
  return {
    stop: (result) => { clearInterval(id); process.stdout.write(`\r  ✓ ${result}\n`); },
    fail: (result) => { clearInterval(id); process.stdout.write(`\r  ✗ ${result}\n`); }
  };
}
```

- [ ] **Step 2: Rewrite detect() to return which scripts exist**

```javascript
function detect(cwd) {
  // ... existing detection ...
  // NEW: check which scripts actually exist
  const scripts = pkg.scripts || {};
  detected.hasLint = Boolean(scripts.lint);
  detected.hasTest = Boolean(scripts.test);
  detected.hasBuild = Boolean(scripts.build);
  detected.hasTypecheck = Boolean(scripts['type-check'] || scripts.typecheck);
  return detected;
}
```

- [ ] **Step 3: Rewrite generate() to conditionally include CI steps**

Pass `detected.hasLint`, `detected.hasTest`, etc. as template variables. Template uses `{% if HAS_LINT %}` blocks.

- [ ] **Step 4: Add `check` command**

```javascript
if (args[0] === 'check') { await check(cwd); process.exit(0); }
```

- [ ] **Step 5: Test all three modes: default, check, -i**

Run locally in a fresh directory, verify output.

- [ ] **Step 6: Commit**

```bash
git add bin/shipkit-pipe.js
git commit -m "feat: rewrite CLI with modern UX and smart detection"
```

---

## Task 2: Rewrite CI Workflow Template (Conditional Steps)

**Files:**
- Rewrite: `template/github/workflows/ci.yml`

**What changes:**
- Only include lint/test/typecheck/build steps if those scripts exist
- Remove hardcoded `npm run lint` — use detected values
- Add deployment status check

- [ ] **Step 1: Rewrite ci.yml with conditional blocks**

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    name: CI
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "{{NODE_VERSION}}"
          cache: "{{PACKAGE_MANAGER}}"
      - run: {{INSTALL_COMMAND}}
{% if HAS_LINT %}
      - name: Lint
        run: {{LINT_COMMAND}}
{% endif %}
{% if HAS_TYPECHECK %}
      - name: Type Check
        run: {{TYPECHECK_COMMAND}}
{% endif %}
{% if HAS_TEST %}
      - name: Test
        run: {{TEST_COMMAND}}
{% endif %}
{% if HAS_BUILD %}
      - name: Build
        run: {{BUILD_COMMAND}}
{% endif %}
```

- [ ] **Step 2: Commit**

```bash
git add template/github/workflows/ci.yml
git commit -m "feat: conditional CI steps — only include what exists"
```

---

## Task 3: Create Health Check Workflow

**Files:**
- Create: `template/github/workflows/health.yml`

**What changes:**
- New GitHub Action that runs on a cron schedule (every 6 hours)
- Pings the deploy URL
- Creates a GitHub Issue if it's down

- [ ] **Step 1: Write health.yml template**

```yaml
name: Health Check

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:        # Manual trigger

jobs:
  health:
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Check site is up
        run: |
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" "{{DEPLOY_URL}}" || echo "000")
          if [ "$STATUS" != "200" ]; then
            echo "::error::Site returned HTTP $STATUS"
            exit 1
          fi
          echo "✓ Site is up (HTTP $STATUS)"

      - name: Create issue if down
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            const issues = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              labels: 'health-check',
              state: 'open'
            });
            if (issues.data.length === 0) {
              await github.rest.issues.create({
                owner: context.repo.owner,
                repo: context.repo.repo,
                title: '🚨 Site is down',
                body: 'Health check failed. Site did not return HTTP 200.\n\nURL: {{DEPLOY_URL}}\nTime: ' + new Date().toISOString(),
                labels: ['health-check', 'bug']
              });
            }
```

- [ ] **Step 2: Only generate if DEPLOY_URL is detected**

In the CLI, only include `health.yml` in the files array when a deploy URL is known (from vercel.json, git remote, or user input).

- [ ] **Step 3: Commit**

```bash
git add template/github/workflows/health.yml
git commit -m "feat: health check workflow — auto-creates issue if site is down"
```

---

## Task 4: Simplify Agent Protocol (1 file instead of 4)

**Files:**
- Rewrite: `template/docs/AGENTS.md`
- Delete: `template/agents/co-developer.md`, `planner.md`, `security-reviewer.md`, `monitor.md`

**What changes:**
- Single `AGENTS.md` that's shorter and clearer
- Remove multi-role complexity
- Focus on: "here's your stack, here's your rules, here's how to help"

- [ ] **Step 1: Write new AGENTS.md template**

```markdown
# {{PROJECT_NAME}} — AI Agent Instructions

You are helping build **{{PROJECT_NAME}}**. Here's what you need to know.

## Stack
{{STACK_TABLE}}

## Rules
1. Read `shipkit.json` for project config
2. Read `LAST_SESSION.md` at session start (if it exists)
3. Update `LAST_SESSION.md` at session end
4. Never commit secrets or .env files
5. Never run destructive database commands without asking
6. Debug root cause first — don't guess fixes

## CI/CD
- Push to `main` triggers: {{CI_STEPS}}
- Deploy: {{DEPLOY_PLATFORM}}
- Health checks run every 6 hours

## Session Continuity
At the end of each session, write to `LAST_SESSION.md`:
- What was done
- What's next
- Key decisions

That's it. Keep it simple. Ship features.
```

- [ ] **Step 2: Remove old agent files from template/**

- [ ] **Step 3: Update CLI to generate only AGENTS.md + shipkit.json + LAST_SESSION.md + .github/**

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: simplify agent protocol — single AGENTS.md instead of 4 files"
```

---

## Task 5: Add `check` Command

**Files:**
- Modify: `bin/shipkit-pipe.js`

**What changes:**
- `npx shipkit-pipe check` verifies the setup works
- Checks: deploy URL responds, CI config valid, no missing scripts, dependencies up to date

- [ ] **Step 1: Implement check() function**

```javascript
async function check(cwd) {
  console.log(`\n  ${C.bold}${C.cyan}⚓ ShipKit Check${C.reset}\n`);

  const s = spinner('Checking project...');
  const pkg = JSON.parse(fs.readFileSync(path.join(cwd, 'package.json'), 'utf-8'));
  const config = fs.existsSync(path.join(cwd, 'shipkit.json'))
    ? JSON.parse(fs.readFileSync(path.join(cwd, 'shipkit.json'), 'utf-8'))
    : null;
  s.stop('Project loaded');

  // Check CI config
  const ciPath = path.join(cwd, '.github/workflows/ci.yml');
  if (fs.existsSync(ciPath)) step('CI workflow exists');
  else warn('No CI workflow — run `npx shipkit-pipe` to generate');

  // Check deploy URL
  if (config?.deploy?.url) {
    const s2 = spinner(`Pinging ${config.deploy.url}...`);
    try {
      const res = await fetch(config.deploy.url);
      if (res.ok) s2.stop(`Site is up (${res.status})`);
      else s2.fail(`Site returned ${res.status}`);
    } catch (e) { s2.fail(`Cannot reach site`); }
  }

  // Check scripts vs CI
  const scripts = pkg.scripts || {};
  if (!scripts.lint) info('No lint script — CI lint step will be skipped');
  if (!scripts.test) info('No test script — CI test step will be skipped');
  if (!scripts.build) info('No build script — CI build step will be skipped');

  console.log();
}
```

- [ ] **Step 2: Test check command**

```bash
node bin/shipkit-pipe.js check
```

- [ ] **Step 3: Commit**

```bash
git add bin/shipkit-pipe.js
git commit -m "feat: add check command — verifies setup works"
```

---

## Task 6: Update Output Files List

**Files:**
- Modify: `bin/shipkit-pipe.js` (generate function)

**What changes:**
- Reduce generated files from 15 to 7:
  1. `shipkit.json` — project config
  2. `AGENTS.md` — AI agent instructions
  3. `LAST_SESSION.md` — session continuity
  4. `.github/workflows/ci.yml` — CI pipeline (conditional)
  5. `.github/workflows/health.yml` — health checks (if deploy URL known)
  6. `.github/dependabot.yml` — dependency updates
  7. `.github/workflows/codeql.yml` — security scanning

- [ ] **Step 1: Update files array in generate()**

- [ ] **Step 2: Remove ROADMAP.md, BUGS.md, shipkit/ directory from output**

- [ ] **Step 3: Update help text and summary output**

- [ ] **Step 4: Test in fresh project**

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: reduce to 7 essential files — no bloat"
```

---

## Task 7: Detect Deploy URL

**Files:**
- Modify: `bin/shipkit-pipe.js` (detect function)

**What changes:**
- Auto-detect deploy URL from:
  - `vercel.json` → `https://<project>.vercel.app`
  - `.vercel/project.json` → extract project name
  - `package.json` `homepage` field
  - Git remote → `https://<owner>.github.io/<repo>` (for GitHub Pages)

- [ ] **Step 1: Add deploy URL detection**

```javascript
// In detect():
if (fs.existsSync(path.join(cwd, '.vercel/project.json'))) {
  try {
    const v = JSON.parse(fs.readFileSync(path.join(cwd, '.vercel/project.json'), 'utf-8'));
    if (v.projectId) detected.deployUrl = `https://${detected.name}.vercel.app`;
  } catch {}
}
if (pkg.homepage) detected.deployUrl = pkg.homepage;
```

- [ ] **Step 2: Store in shipkit.json**

```json
{ "deploy": { "url": "https://my-app.vercel.app" } }
```

- [ ] **Step 3: Commit**

```bash
git commit -am "feat: auto-detect deploy URL for health checks"
```

---

## Task 8: Final Polish & Publish

- [ ] **Step 1: Update README.md with new usage**
- [ ] **Step 2: Update package.json version to 3.0.0**
- [ ] **Step 3: Test full flow in fresh project**
- [ ] **Step 4: Test `check` command**
- [ ] **Step 5: Test `--help` output**
- [ ] **Step 6: Commit and push**
- [ ] **Step 7: Publish to npm**

```bash
npm version major
npm publish
git push --tags origin main
```

---

## Summary: What Users See After v3

### New user experience:

```bash
cd my-project
npx shipkit-pipe
```

```
⚓ ShipKit — my-project

  ⠼ Detecting project...
  ✓ Next.js | pnpm | Node 20
  ✓ Scripts: lint, test, build
  ✓ Git: sagar-grv/my-project
  ✓ Deploy: Vercel (my-project.vercel.app)

  ⠼ Generating...
  ✓ Generated 7 files

  Files:
    shipkit.json              ← Project config
    AGENTS.md                 ← AI agent instructions
    LAST_SESSION.md           ← Session continuity
    .github/workflows/ci.yml  ← CI: lint → test → build
    .github/workflows/health.yml  ← Health checks (every 6h)
    .github/dependabot.yml    ← Auto-update dependencies
    .github/workflows/codeql.yml  ← Security scanning

  Next: git add -A && git commit -m "init" && git push
```

### Check command:

```bash
npx shipkit-pipe check
```

```
⚓ ShipKit Check

  ✓ Project loaded (my-project)
  ✓ CI workflow valid (lint → test → build)
  ✓ Health check configured
  ✓ Site is up (200) — my-project.vercel.app
  ✓ No critical dependency alerts
  ⚠ 2 dependencies need updates (non-critical)
```
