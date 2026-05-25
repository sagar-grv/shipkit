# ShipKit — Usage Guide

> One command sets up CI/CD, monitoring, security, and AI agent config.
> This guide walks through every scenario with real output.

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Scenario: New / empty project](#2-scenario-new--empty-project)
3. [Scenario: Existing Node.js app](#3-scenario-existing-nodejs-app)
4. [Scenario: App with a deploy URL](#4-scenario-app-with-a-deploy-url)
5. [Scenario: Monorepo](#5-scenario-monorepo)
6. [Scenario: GitLab CI](#6-scenario-gitlab-ci)
7. [Scenario: Bitbucket Pipelines](#7-scenario-bitbucket-pipelines)
8. [What each generated file does](#8-what-each-generated-file-does)
9. [Commands reference](#9-commands-reference)
10. [Troubleshooting](#10-troubleshooting)
11. [FAQ](#11-faq)

---

## 1. Quick Start

```bash
cd your-project
npx shipkit-pipe
```

That's it. ShipKit reads your project, detects your stack, and generates everything in seconds.

**Expected output:**

```
⚓ ShipKit — my-project

✓ Next.js | npm | Node 22
✓ Scripts: lint, test, build
✓ Git: github (user/my-project)
✓ Deploy: Vercel (https://my-project.vercel.app)
✓ Generated 8 files

Files:
  shipkit.json                     ← Project config
  AGENTS.md                        ← AI agent instructions
  LAST_SESSION.md                  ← Session continuity
  .github/workflows/ci.yml         ← CI: lint > test > build
  .github/workflows/health.yml     ← Health check (every 6h)
  .github/dependabot.yml           ← Auto-update deps
  .github/workflows/codeql.yml     ← Security scanning
  .github/workflows/auto-merge.yml ← Auto-merge safe dependabot PRs

Next: git add -A && git commit -m "add pipeline" && git push
Verify: npx shipkit-pipe check
```

**Then push:**

```bash
git add -A && git commit -m "add shipkit pipeline" && git push
```

CI runs on your first push. Done.

---

## 2. Scenario: New / empty project

No `package.json`, no git remote yet.

```bash
mkdir my-new-app && cd my-new-app
git init
npx shipkit-pipe
```

**What happens:**
- No `package.json` → defaults to Node.js, npm, Node 20
- No git remote → CI is generated but `GITHUB_OWNER` defaults to `your-username`
- No scripts detected → CI workflow only installs dependencies

**Output:**

```
✓ Node.js | npm | Node 20
  No scripts detected yet — CI will verify deps install cleanly
  No git repo detected — health checks will be skipped
✓ Generated 5 files
```

**After setup:**

```bash
# Create package.json
npm init -y

# Add your remote
git remote add origin https://github.com/you/my-new-app.git

# Re-run to pick up the new remote and update files
npx shipkit-pipe --force
```

---

## 3. Scenario: Existing Node.js app

Standard project with lint, test, and build scripts on GitHub.

```bash
cd my-app    # has package.json, .git with GitHub remote
npx shipkit-pipe
```

**What ShipKit reads:**
- `package.json` → name, scripts, dependencies, homepage
- `pnpm-lock.yaml` / `yarn.lock` / `bun.lockb` → package manager
- `.nvmrc` / `.node-version` → Node version
- `git remote origin` → GitHub owner + repo
- `vercel.json` / `fly.toml` / `netlify.toml` → deploy platform

**Generated `ci.yml` only includes what you have:**

```yaml
# If you have lint + test + build:
- name: Lint
  run: npm run lint
- name: Test
  run: npm test
- name: Build
  run: npm run build
```

```yaml
# If you only have test:
- name: Test
  run: npm test
```

**Skip existing files:** ShipKit never overwrites files that already exist, unless you pass `--force`.

---

## 4. Scenario: App with a deploy URL

Any project where you have a live production URL — Vercel, Netlify, Fly.io, Railway, Render, or custom.

**How ShipKit detects your deploy URL:**

| Config file | Platform | URL format |
|---|---|---|
| `vercel.json` | Vercel | `https://<repo>.vercel.app` |
| `netlify.toml` | Netlify | `https://<name>.netlify.app` |
| `fly.toml` | Fly.io | `https://<app>.fly.dev` |
| `render.yaml` | Render | — |
| `railway.json` | Railway | — |
| `package.json` `homepage` field | Custom | your URL |

**If detected**, `health.yml` is also generated:

```
✓ Deploy: Vercel (https://my-app.vercel.app)
✓ Generated 8 files  ← includes health.yml
```

**If not detected**, add it manually to `package.json`:

```json
{
  "homepage": "https://my-app.vercel.app"
}
```

Then re-run `npx shipkit-pipe --force` to regenerate.

> **Note:** GitHub repo URLs (`https://github.com/...`) are intentionally skipped — health checks only make sense for live sites.

---

## 5. Scenario: Monorepo

A repo with multiple apps in subdirectories.

```
my-monorepo/
  frontend/   ← has package.json
  backend/    ← has package.json
  .git/
```

```bash
cd my-monorepo
npx shipkit-pipe
```

**What happens:**
- No `package.json` at root → ShipKit scans `frontend/`, `backend/`, `web/`, `app/`, `api/`, `server/`, `client/`
- Detects monorepo, uses the primary frontend app for stack detection
- Generates CI at the root level

**Output:**

```
✓ Next.js | npm | Node 22
✓ Monorepo: frontend, backend
✓ Generated 7 files
```

**Tip:** If the wrong subproject is being used as the primary, add a `package.json` at root level with a `workspaces` field.

---

## 6. Scenario: GitLab CI

ShipKit detects GitLab from your git remote URL automatically.

```bash
cd my-gitlab-project   # remote is git@gitlab.com:user/repo.git
npx shipkit-pipe
```

**What gets generated:**

```
✓ Generated: .gitlab-ci.yml   ← instead of .github/workflows/ci.yml
✓ Generated: AGENTS.md
✓ Generated: LAST_SESSION.md
✓ Generated: shipkit.json
```

**No GitHub-specific files** (no dependabot.yml, no codeql.yml) — GitLab has built-in equivalents.

**Force GitLab even without a remote:**

```bash
# Add a GitLab remote first:
git remote add origin https://gitlab.com/you/your-project.git
npx shipkit-pipe
```

---

## 7. Scenario: Bitbucket Pipelines

Same as GitLab — detected automatically from your remote URL.

```bash
cd my-bitbucket-project   # remote is git@bitbucket.org:user/repo.git
npx shipkit-pipe
```

**What gets generated:**

```
✓ Generated: bitbucket-pipelines.yml
✓ Generated: AGENTS.md
✓ Generated: LAST_SESSION.md
✓ Generated: shipkit.json
```

---

## 8. What each generated file does

### `shipkit.json`
The project config file. AI agents (Claude, Cursor, Copilot, OpenCode) read this to understand your stack without asking.

```json
{
  "project": { "name": "my-app", "description": "..." },
  "stack": { "framework": "Next.js", "packageManager": "npm", "nodeVersion": "22" },
  "scripts": { "lint": true, "test": true, "build": true, "typecheck": false },
  "deploy": { "platform": "Vercel", "url": "https://my-app.vercel.app" },
  "github": { "owner": "you", "repo": "my-app" },
  "ci": { "steps": "lint -> test -> build" }
}
```

### `AGENTS.md`
Universal AI agent protocol. Tells your AI assistant your stack, rules, CI steps, and session continuity instructions. Works with Claude, Cursor, Copilot, OpenCode, and any other AI coding tool.

### `LAST_SESSION.md`
Session continuity file. Your AI agent writes what it did at the end of each session, and reads it at the start of the next one. Prevents repeating yourself every time you open a new chat.

### `.github/workflows/ci.yml`
Smart CI workflow. Only includes steps for scripts that actually exist in your `package.json`. If you have a `lint` script → lint step. No `build` script → no build step. **Your CI never fails because of a missing script.**

Runs on every push and pull request to `main`.

### `.github/workflows/health.yml`
Pings your production URL every 6 hours. If it returns a non-2xx/3xx status:
- Creates a GitHub Issue automatically with the URL, status code, and timestamp
- Closes the issue automatically when the site recovers

Only generated if a deploy URL is detected.

### `.github/dependabot.yml`
Configures Dependabot to open weekly PRs for outdated npm packages and GitHub Actions. Groups patch and minor updates together to reduce PR noise. Auto-merge workflow handles safe updates automatically.

### `.github/workflows/codeql.yml`
Runs GitHub's CodeQL security scanner on every push and PR. Detects 100+ vulnerability classes including injection, XSS, insecure crypto, and path traversal. Also runs on a Monday 6 AM UTC schedule.

### `.github/workflows/auto-merge.yml`
Automatically merges Dependabot PRs that pass CI and are patch or minor version bumps. Major version bumps are left for manual review.

---

## 9. Commands reference

| Command | What it does |
|---|---|
| `npx shipkit-pipe` | Auto-detect and generate (default) |
| `npx shipkit-pipe --dry-run` | Preview what would be generated — no files written |
| `npx shipkit-pipe --force` | Re-run and overwrite existing files |
| `npx shipkit-pipe -i` | Interactive mode — asks for deploy URL and GitHub info if not detected |
| `npx shipkit-pipe check` | Verify CI, ping your site, check for vulnerabilities |
| `npx shipkit-pipe check --json` | Same as check but machine-readable JSON output |
| `npx shipkit-pipe upgrade` | Check if a newer version is available |
| `npx shipkit-pipe --version` | Print current version |
| `npx shipkit-pipe --help` | Show help |

**Other install methods:**

```bash
# Global install (run as `shipkit-pipe` anywhere)
npm install -g shipkit-pipe
pnpm add -g shipkit-pipe
yarn global add shipkit-pipe
bun add -g shipkit-pipe
```

---

## 10. Troubleshooting

### Node version is too old

**Error:** `SyntaxError: Unexpected token` or `Error [ERR_REQUIRE_ESM]`

**Cause:** ShipKit requires Node.js >= 18.

**Fix:**
```bash
node --version   # check current version

# Install Node 22 via nvm:
nvm install 22 && nvm use 22

# Or via fnm:
fnm install 22 && fnm use 22
```

---

### `npx: command not found` or `npx` hangs

**Cause:** npm is not installed, or npx cache is corrupted.

**Fix:**
```bash
# Clear npx cache
npx clear-npx-cache

# Or run with explicit version
npm exec shipkit-pipe@latest
```

---

### Files already exist — nothing was generated

**Cause:** ShipKit skips files that already exist to avoid overwriting your customizations.

**Fix:** Use `--force` to overwrite:
```bash
npx shipkit-pipe --force
```

Or delete individual files and re-run normally.

---

### `health.yml` was not generated

**Cause:** No deploy URL was detected.

**Fix — option 1:** Add `homepage` to `package.json`:
```json
{ "homepage": "https://your-app.vercel.app" }
```

**Fix — option 2:** Use interactive mode to enter it manually:
```bash
npx shipkit-pipe -i
# It will ask: Deploy URL (leave empty to skip):
```

Then re-run `npx shipkit-pipe` or `npx shipkit-pipe --force`.

---

### CI fails on first push — `npm run lint` not found

**Cause:** ShipKit detected a `lint` script in your `package.json` when you ran it, but the script was later removed or renamed.

**Fix:** Re-run with `--force` to regenerate a fresh `ci.yml`:
```bash
npx shipkit-pipe --force
```

---

### CI fails — `actions/checkout` permission error

**Cause:** Repository workflow permissions are set to read-only.

**Fix:** In your GitHub repo → Settings → Actions → General → Workflow permissions → set to **Read and write permissions**.

---

### CodeQL fails — `Resource not accessible by integration`

**Cause:** CodeQL needs `security-events: write` permission, which private repos may restrict.

**Fix:** In your GitHub repo → Settings → Actions → General → Workflow permissions → enable **Allow GitHub Actions to create and approve pull requests**.

Or for private repos, go to Settings → Code security → Code scanning and enable it explicitly.

---

### Windows: `shipkit-pipe` not found after global install

**Cause:** npm global bin directory is not in your PATH.

**Fix:**
```powershell
# Find where npm installs global packages
npm config get prefix

# Add <prefix>\bin to your PATH in System Environment Variables
# Or use npx which always works:
npx shipkit-pipe
```

---

### Corporate network / proxy — `npm` can't reach registry

**Cause:** Your network blocks `registry.npmjs.org`.

**Fix:**
```bash
# Configure npm to use your proxy
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080

# Then run normally
npx shipkit-pipe
```

---

### Monorepo: wrong subdirectory was used for detection

**Cause:** ShipKit picks the first frontend-like directory (`frontend/`, `web/`, `app/`, `client/`). If your structure is different, it may pick the wrong one.

**Fix — option 1:** Add a `package.json` at the repo root:
```json
{ "name": "my-monorepo", "workspaces": ["apps/*"] }
```

**Fix — option 2:** Use interactive mode to override detection:
```bash
npx shipkit-pipe -i
```

---

### GitLab or Bitbucket not detected — GitHub CI was generated instead

**Cause:** No git remote is set, or the remote URL doesn't contain `gitlab` or `bitbucket`.

**Fix:** Set the remote first:
```bash
git remote add origin https://gitlab.com/you/your-project.git
npx shipkit-pipe --force
```

---

### `check` shows site is unreachable but site is up

**Cause:** Your production URL requires authentication, redirects to a login page, or blocks HEAD requests.

**Fix:** Open `health.yml` and change the `--max-time` or method:
```yaml
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 -L "$URL" || echo "000")
```
The `-L` flag follows redirects (useful for Vercel/Netlify preview URLs).

---

### Want to customize a generated file

All generated files are plain YAML/JSON/Markdown — edit them directly. ShipKit will not overwrite them on future runs unless you use `--force`.

To regenerate a single file, delete it and re-run:
```bash
rm .github/workflows/ci.yml
npx shipkit-pipe
```

---

## 11. FAQ

**Q: Is ShipKit free?**
Yes. MIT licensed. Open source. No account, no API key, no cloud service. Everything runs locally.

---

**Q: Will it overwrite my existing CI workflows?**
No. ShipKit skips any file that already exists. Use `--force` only when you intentionally want to regenerate.

---

**Q: Does it work on private repositories?**
Yes. The CLI runs locally — it never sends your code anywhere. The generated GitHub Actions workflows work on both public and private repos. CodeQL is free for both.

---

**Q: I don't use GitHub — will it still work?**
Yes. ShipKit detects your git remote and generates the right format:
- GitHub → `.github/workflows/ci.yml`
- GitLab → `.gitlab-ci.yml`
- Bitbucket → `bitbucket-pipelines.yml`

---

**Q: I use pnpm / yarn / bun — does it work?**
Yes. ShipKit detects your lock file and uses the right install command:
- `pnpm-lock.yaml` → `pnpm install --frozen-lockfile`
- `yarn.lock` → `yarn --frozen-lockfile`
- `bun.lockb` → `bun install --frozen-lockfile`
- Default → `npm ci`

---

**Q: Can I run it again after making changes?**
Yes. Run `npx shipkit-pipe` anytime — it skips existing files. Use `--force` to regenerate all files from scratch with updated detection.

---

**Q: Something isn't working — how do I get help?**
Open an issue at [github.com/sagar-grv/shipkit/issues](https://github.com/sagar-grv/shipkit/issues) with:
1. Your OS and Node version (`node --version`)
2. The output of `npx shipkit-pipe --dry-run`
3. The error message
