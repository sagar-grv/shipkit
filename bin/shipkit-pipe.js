#!/usr/bin/env node

/**
 * ShipKit v3.1 — Your Automated Dev Team
 * =======================================
 * One command. Auto-detects your project. Generates only what you need.
 * Verifies everything works. Monitors your site.
 *
 * Zero dependencies. Works with any stack, any IDE, any AI agent.
 *
 * Commands:
 *   npx shipkit-pipe             Detect & generate pipeline
 *   npx shipkit-pipe check       Verify everything works
 *   npx shipkit-pipe upgrade     Check for updates
 *   npx shipkit-pipe --force     Overwrite existing files
 *   npx shipkit-pipe --dry-run   Preview without writing
 *   npx shipkit-pipe -i          Interactive mode
 *   npx shipkit-pipe --help      Help
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ─── Zero-Dep UI ────────────────────────────────────────────────────────────

const C = {
  reset: '\x1b[0m', bold: '\x1b[1m', dim: '\x1b[2m',
  green: '\x1b[32m', cyan: '\x1b[36m', yellow: '\x1b[33m', red: '\x1b[31m',
  magenta: '\x1b[35m',
};

const isCI = process.env.CI || process.env.GITHUB_ACTIONS;

function spinner(msg) {
  if (isCI) { process.stdout.write(`  … ${msg}\n`); return { stop: m => console.log(`  ✓ ${m}`), fail: m => console.log(`  ✗ ${m}`) }; }
  const frames = ['⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏'];
  let i = 0, text = msg;
  const id = setInterval(() => { process.stdout.write(`\r  ${C.cyan}${frames[i++ % frames.length]}${C.reset} ${text}`); }, 80);
  return {
    update: (m) => { text = m; },
    stop: (m) => { clearInterval(id); process.stdout.write(`\r  ${C.green}✓${C.reset} ${m}\n`); },
    fail: (m) => { clearInterval(id); process.stdout.write(`\r  ${C.red}✗${C.reset} ${m}\n`); },
  };
}

function step(msg) { console.log(`  ${C.green}✓${C.reset} ${msg}`); }
function warn(msg) { console.log(`  ${C.yellow}⚠${C.reset} ${msg}`); }
function fail(msg) { console.log(`  ${C.red}✗${C.reset} ${msg}`); }
function dim(msg) { console.log(`  ${C.dim}${msg}${C.reset}`); }

// ─── Detect ─────────────────────────────────────────────────────────────────

function detect(cwd) {
  const d = {
    name: path.basename(cwd),
    desc: '',
    frontend: '',
    pm: 'npm',
    installCmd: 'npm ci',
    nodeVer: '20',
    hasLint: false, lintCmd: '',
    hasTest: false, testCmd: '',
    hasBuild: false, buildCmd: '',
    hasTypecheck: false, typecheckCmd: '',
    hasGit: false,
    gitRemote: '',
    gitPlatform: 'github', // github | gitlab | bitbucket
    ghOwner: '',
    ghRepo: '',
    deployUrl: '',
    deployPlatform: '',
    isMonorepo: false,
    subProjects: [],
  };

  // Find package.json — root first, then subdirs
  let pkgPath = path.join(cwd, 'package.json');
  let pkgDir = cwd;

  if (!fs.existsSync(pkgPath)) {
    // Monorepo: look in common subdirectories
    const subdirs = ['frontend', 'backend', 'web', 'app', 'apps', 'packages', 'services', 'api', 'server', 'client'];
    const found = subdirs.filter(dir => fs.existsSync(path.join(cwd, dir, 'package.json')));
    if (found.length > 0) {
      d.isMonorepo = true;
      d.subProjects = found;
      // Use the first frontend-like subproject for detection
      const primary = found.find(f => ['frontend', 'web', 'app', 'client'].includes(f)) || found[0];
      pkgPath = path.join(cwd, primary, 'package.json');
      pkgDir = path.join(cwd, primary);
    }
  }

  if (!fs.existsSync(pkgPath)) return d;

  let pkg;
  try { pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf-8')); } catch { return d; }

  if (pkg.name) d.name = d.isMonorepo ? path.basename(cwd) : pkg.name;
  if (pkg.description) d.desc = pkg.description;
  if (pkg.homepage) d.deployUrl = pkg.homepage;

  // Framework detection
  const deps = { ...pkg.dependencies || {}, ...pkg.devDependencies || {} };
  if (deps.next) d.frontend = 'Next.js';
  else if (deps.nuxt) d.frontend = 'Nuxt';
  else if (deps['@remix-run/react']) d.frontend = 'Remix';
  else if (deps.astro) d.frontend = 'Astro';
  else if (deps['@sveltejs/kit'] || deps.svelte) d.frontend = 'SvelteKit';
  else if (deps.vue) d.frontend = 'Vue';
  else if (deps.react) d.frontend = 'React';
  else if (deps.express) d.frontend = 'Express';
  else if (deps.fastify) d.frontend = 'Fastify';
  else if (deps.hono) d.frontend = 'Hono';
  else if (deps.django || fs.existsSync(path.join(cwd, 'manage.py'))) d.frontend = 'Django';
  else if (fs.existsSync(path.join(cwd, 'go.mod'))) d.frontend = 'Go';

  // Package manager (check root level for monorepo)
  if (fs.existsSync(path.join(cwd, 'pnpm-lock.yaml'))) { d.pm = 'pnpm'; d.installCmd = 'pnpm install --frozen-lockfile'; }
  else if (fs.existsSync(path.join(cwd, 'yarn.lock'))) { d.pm = 'yarn'; d.installCmd = 'yarn --frozen-lockfile'; }
  else if (fs.existsSync(path.join(cwd, 'bun.lockb'))) { d.pm = 'bun'; d.installCmd = 'bun install --frozen-lockfile'; }
  else if (fs.existsSync(path.join(pkgDir, 'pnpm-lock.yaml'))) { d.pm = 'pnpm'; d.installCmd = 'pnpm install --frozen-lockfile'; }
  else if (fs.existsSync(path.join(pkgDir, 'yarn.lock'))) { d.pm = 'yarn'; d.installCmd = 'yarn --frozen-lockfile'; }
  else { d.pm = 'npm'; d.installCmd = 'npm ci'; }

  // Scripts — ONLY include CI steps for scripts that ACTUALLY EXIST
  const scripts = pkg.scripts || {};
  if (scripts.lint) { d.hasLint = true; d.lintCmd = `${d.pm} run lint`; }
  if (scripts.test) { d.hasTest = true; d.testCmd = `${d.pm === 'npm' ? 'npm test' : d.pm + ' run test'}`; }
  if (scripts.build) { d.hasBuild = true; d.buildCmd = `${d.pm} run build`; }
  if (scripts.typecheck || scripts['type-check']) {
    d.hasTypecheck = true;
    d.typecheckCmd = scripts.typecheck ? `${d.pm} run typecheck` : `${d.pm} run type-check`;
  } else if (deps.typescript) {
    d.hasTypecheck = true;
    d.typecheckCmd = 'npx tsc --noEmit';
  }

  // Node version from .nvmrc, .node-version, or engines
  const nvmrc = path.join(cwd, '.nvmrc');
  const nodeVer = path.join(cwd, '.node-version');
  if (fs.existsSync(nvmrc)) { d.nodeVer = fs.readFileSync(nvmrc, 'utf-8').trim().replace('v', ''); }
  else if (fs.existsSync(nodeVer)) { d.nodeVer = fs.readFileSync(nodeVer, 'utf-8').trim().replace('v', ''); }
  else if (pkg.engines?.node) {
    const m = pkg.engines.node.match(/(\d+)/);
    if (m) d.nodeVer = m[1];
  }

  // Git
  if (fs.existsSync(path.join(cwd, '.git'))) {
    d.hasGit = true;
    try { d.gitRemote = execSync('git config --get remote.origin.url', { cwd, encoding: 'utf-8', stdio: 'pipe' }).trim(); } catch {}
    if (d.gitRemote) {
      const m = d.gitRemote.match(/[:/]([^/]+)\/([^/.]+?)(?:\.git)?$/);
      if (m) { d.ghOwner = m[1]; d.ghRepo = m[2]; }
      // Detect git platform
      if (d.gitRemote.includes('gitlab')) d.gitPlatform = 'gitlab';
      else if (d.gitRemote.includes('bitbucket')) d.gitPlatform = 'bitbucket';
      else d.gitPlatform = 'github';
    }
  }
  // Also check for existing CI configs to detect platform
  if (!d.gitPlatform) {
    if (fs.existsSync(path.join(cwd, '.gitlab-ci.yml'))) d.gitPlatform = 'gitlab';
    else if (fs.existsSync(path.join(cwd, 'bitbucket-pipelines.yml'))) d.gitPlatform = 'bitbucket';
    else d.gitPlatform = 'github';
  }

  // Deploy platform detection
  if (fs.existsSync(path.join(cwd, 'vercel.json')) || fs.existsSync(path.join(cwd, '.vercel'))) {
    d.deployPlatform = 'Vercel';
    if (!d.deployUrl) d.deployUrl = `https://${d.ghRepo || d.name}.vercel.app`;
  } else if (fs.existsSync(path.join(cwd, 'netlify.toml'))) {
    d.deployPlatform = 'Netlify';
    if (!d.deployUrl) d.deployUrl = `https://${d.name}.netlify.app`;
  } else if (fs.existsSync(path.join(cwd, 'fly.toml'))) {
    d.deployPlatform = 'Fly.io';
    try { const fly = fs.readFileSync(path.join(cwd, 'fly.toml'), 'utf-8'); const m = fly.match(/app\s*=\s*"([^"]+)"/); if (m) d.deployUrl = `https://${m[1]}.fly.dev`; } catch {}
  } else if (fs.existsSync(path.join(cwd, 'render.yaml'))) {
    d.deployPlatform = 'Render';
  } else if (fs.existsSync(path.join(cwd, 'railway.json')) || fs.existsSync(path.join(cwd, 'railway.toml'))) {
    d.deployPlatform = 'Railway';
  } else if (fs.existsSync(path.join(cwd, 'docker-compose.yml')) || fs.existsSync(path.join(cwd, 'docker-compose.yaml'))) {
    d.deployPlatform = 'Docker';
  }

  return d;
}

// ─── Template Renderer ──────────────────────────────────────────────────────

function render(content, vars) {
  let r = content;
  const escaped = {};
  for (const [k, v] of Object.entries(vars)) {
    // Escape {{ and }} in values to prevent template injection
    escaped[k] = String(v ?? '').replace(/\{\{/g, '\\{\\{').replace(/\}\}/g, '\\}\\}');
  }
  for (const [k, v] of Object.entries(escaped)) {
    r = r.replace(new RegExp(`\\{\\{${k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\}\\}`, 'g'), v);
  }
  return r.replace(/\{%\s*if\s+(\w+)\s*%\}([\s\S]*?)\{%\s*endif\s*%\}/g, (_, n, inner) => {
    const val = vars[n]; return (val && val !== 'false' && val !== '0' && val !== '') ? inner : '';
  });
}

// ─── Generate ───────────────────────────────────────────────────────────────

function generate(cwd, d, opts = {}) {
  const vars = {
    PROJECT_NAME: d.name,
    PROJECT_DESCRIPTION: d.desc || 'A web application',
    DATE: new Date().toISOString().split('T')[0],
    // Stack
    STACK_FRONTEND: d.frontend || 'Node.js',
    DEPLOY_PLATFORM: d.deployPlatform || 'Not configured',
    DEPLOY_URL: d.deployUrl || '',
    // CI (only what exists)
    NODE_VERSION: d.nodeVer,
    PACKAGE_MANAGER: d.pm,
    INSTALL_COMMAND: d.installCmd,
    HAS_LINT: d.hasLint ? 'true' : '',
    LINT_COMMAND: d.lintCmd,
    HAS_TYPECHECK: d.hasTypecheck ? 'true' : '',
    TYPECHECK_COMMAND: d.typecheckCmd,
    HAS_TEST: d.hasTest ? 'true' : '',
    TEST_COMMAND: d.testCmd,
    HAS_BUILD: d.hasBuild ? 'true' : '',
    BUILD_COMMAND: d.buildCmd,
    // GitHub
    GITHUB_OWNER: d.ghOwner || 'your-username',
    GITHUB_REPO: d.ghRepo || d.name.toLowerCase().replace(/[^a-z0-9-]/g, ''),
    // Conditional: health check only if deploy URL is known
    HAS_DEPLOY_URL: d.deployUrl ? 'true' : '',
  };

  // Build CI steps summary for AGENTS.md
  const ciSteps = [d.hasLint && 'lint', d.hasTypecheck && 'typecheck', d.hasTest && 'test', d.hasBuild && 'build'].filter(Boolean).join(' -> ');
  vars.CI_STEPS = ciSteps || 'install';

  // Find template dir
  const tmplDir = [
    path.join(path.dirname(require.resolve('../package.json')), 'template'),
    path.join(__dirname, '..', 'template'),
    path.join(cwd, 'template'),
  ].find(d => fs.existsSync(d));

  if (!tmplDir) { fail('Template directory not found. Reinstall: npm i -g shipkit-pipe'); process.exit(1); }

  // Files to generate — platform-specific CI
  const files = [];

  if (d.gitPlatform === 'gitlab') {
    files.push(['gitlab/gitlab-ci.yml', '.gitlab-ci.yml']);
  } else if (d.gitPlatform === 'bitbucket') {
    files.push(['bitbucket/bitbucket-pipelines.yml', 'bitbucket-pipelines.yml']);
  } else {
    // GitHub (default)
    files.push(['github/workflows/ci.yml', '.github/workflows/ci.yml']);
    files.push(['github/dependabot.yml', '.github/dependabot.yml']);
    files.push(['github/workflows/codeql.yml', '.github/workflows/codeql.yml']);
    // Only add health check if we have a deploy URL
    if (d.deployUrl) {
      files.push(['github/workflows/health.yml', '.github/workflows/health.yml']);
    }
  }

  // Common files (all platforms)
  files.push(['docs/AGENTS.md', 'AGENTS.md']);
  files.push(['docs/LAST_SESSION.md', 'LAST_SESSION.md']);

  let gen = 0, skip = 0;

  for (const [src, dst] of files) {
    const srcPath = path.join(tmplDir, src);
    const dstPath = path.join(cwd, dst);
    if (!fs.existsSync(srcPath)) continue;
    if (fs.existsSync(dstPath) && !opts.force) { skip++; continue; }
    fs.mkdirSync(path.dirname(dstPath), { recursive: true });
    fs.writeFileSync(dstPath, render(fs.readFileSync(srcPath, 'utf-8'), vars), 'utf-8');
    gen++;
  }

  // shipkit.json — the project config AI agents read
  const sjPath = path.join(cwd, 'shipkit.json');
  if (!fs.existsSync(sjPath) || opts.force) {
    fs.writeFileSync(sjPath, JSON.stringify({
      project: { name: d.name, description: d.desc || '' },
      stack: { framework: d.frontend || 'Node.js', packageManager: d.pm, nodeVersion: d.nodeVer },
      scripts: { lint: d.hasLint, test: d.hasTest, build: d.hasBuild, typecheck: d.hasTypecheck },
      deploy: { platform: d.deployPlatform || '', url: d.deployUrl || '' },
      github: { owner: d.ghOwner || '', repo: d.ghRepo || '' },
      ci: { steps: ciSteps },
      version: '3.1.0',
    }, null, 2) + '\n', 'utf-8');
    gen++;
  } else { skip++; }

  return { gen, skip, vars };
}

// ─── Version Check ───────────────────────────────────────────────────────────

let _latestVersion = null;

async function checkVersion() {
  try {
    const res = await fetch('https://registry.npmjs.org/shipkit-pipe/latest', { signal: AbortSignal.timeout(3000) });
    if (res.ok) {
      const data = await res.json();
      _latestVersion = data.version;
    }
  } catch {}
}

function warnIfOutdated(current) {
  if (_latestVersion && _latestVersion !== current) {
    warn(`Version ${_latestVersion} available. Run "${C.green}npx shipkit-pipe upgrade${C.reset}" to update`);
  }
}

// ─── Upgrade Command ─────────────────────────────────────────────────────────

function upgrade(current) {
  console.log(`\n  ${C.bold}${C.cyan}⚓ ShipKit Upgrade${C.reset}\n`);
  if (_latestVersion && current !== _latestVersion) {
    console.log(`  ${C.yellow}${current} → ${_latestVersion}${C.reset}`);
    console.log(`\n  Run: ${C.green}npm install -g shipkit-pipe@${_latestVersion}${C.reset}\n`);
  } else {
    console.log(`  ${C.green}✓ You're on the latest version (${current})${C.reset}\n`);
  }
}

// ─── Check Command ──────────────────────────────────────────────────────────

async function check(cwd, asJson = false) {
  const pkgPath = path.join(cwd, 'package.json');
  let pkg = {};
  if (fs.existsSync(pkgPath)) {
    pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'));
  }
  const sjPath = path.join(cwd, 'shipkit.json');
  const ciPath = path.join(cwd, '.github', 'workflows', 'ci.yml');
  const healthPath = path.join(cwd, '.github', 'workflows', 'health.yml');
  const agentsPath = path.join(cwd, 'AGENTS.md');

  const result = {
    project: pkg.name || path.basename(cwd),
    shipkitJson: fs.existsSync(sjPath),
    ciWorkflow: fs.existsSync(ciPath),
    healthCheck: fs.existsSync(healthPath),
    agentsMd: fs.existsSync(agentsPath),
    ciWarnings: [],
    deploy: { url: null, status: null },
    vulnerabilities: { critical: 0, high: 0 },
  };

  // CI validation
  if (result.ciWorkflow) {
    const ci = fs.readFileSync(ciPath, 'utf-8');
    const scripts = pkg.scripts || {};
    if (ci.includes('run lint') && !scripts.lint) result.ciWarnings.push('CI has lint step but no "lint" script');
    if (ci.includes('run test') && !scripts.test) result.ciWarnings.push('CI has test step but no "test" script');
    if (ci.includes('run build') && !scripts.build) result.ciWarnings.push('CI has build step but no "build" script');
  }

  // Deploy
  const config = fs.existsSync(sjPath) ? JSON.parse(fs.readFileSync(sjPath, 'utf-8')) : null;
  const deployUrl = config?.deploy?.url;
  result.deploy.url = deployUrl || null;
  if (deployUrl) {
    try {
      const res = await fetch(deployUrl, { method: 'HEAD', signal: AbortSignal.timeout(10000) });
      result.deploy.status = res.ok ? 'up' : `error (${res.status})`;
    } catch { result.deploy.status = 'unreachable'; }
  }

  // Vulnerabilities
  try {
    const auditRes = execSync('npm audit --json 2>/dev/null || echo "{}"', { cwd, encoding: 'utf-8', stdio: 'pipe', timeout: 15000 });
    try {
      const audit = JSON.parse(auditRes);
      const vulns = audit.metadata?.vulnerabilities || {};
      result.vulnerabilities.critical = vulns.critical || 0;
      result.vulnerabilities.high = vulns.high || 0;
    } catch {}
  } catch {}

  if (asJson) {
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  console.log(`\n  ${C.bold}${C.cyan}⚓ ShipKit Check${C.reset}\n`);

  step(`Project: ${result.project}`);
  result.shipkitJson ? step('shipkit.json exists') : warn('No shipkit.json — run `npx shipkit-pipe` to generate');
  result.ciWorkflow ? step('CI workflow exists') : warn('No CI workflow — run `npx shipkit-pipe` to generate');
  for (const w of result.ciWarnings) warn(w);
  result.healthCheck ? step('Health check workflow exists') : null;
  result.agentsMd ? step('AGENTS.md exists') : dim('No AGENTS.md — your AI agent won\'t know your project config');

  if (result.deploy.url) {
    if (result.deploy.status === 'up') step(`Site is up — ${result.deploy.url}`);
    else warn(`Site ${result.deploy.status} — ${result.deploy.url}`);
  } else {
    dim('No deploy URL configured — add "homepage" to package.json or deploy to Vercel/Netlify');
  }

  const v = result.vulnerabilities;
  const total = v.critical + v.high;
  if (total > 0) warn(`${total} critical/high vulnerabilities — run \`npm audit fix\``);
  else step('No critical vulnerabilities');

  console.log();
}

// ─── Interactive Mode ───────────────────────────────────────────────────────

const readline = require('readline');

async function ask(question, defaultVal) {
  const r = readline.createInterface({ input: process.stdin, output: process.stdout });
  const suffix = defaultVal ? ` ${C.dim}[${defaultVal}]${C.reset}` : '';
  return new Promise(res => {
    r.question(`  ${question}${suffix}: `, a => { r.close(); res(a.trim() || defaultVal || ''); });
  });
}

async function interactive(cwd, d, opts = {}) {
  console.log(`\n  ${C.bold}${C.cyan}⚓ ShipKit${C.reset} — interactive setup\n`);
  console.log(`  ${C.dim}Detected: ${d.frontend || 'Node.js'} | ${d.pm} | Node ${d.nodeVer}${C.reset}\n`);

  // Only ask what we can't auto-detect
  if (!d.deployUrl) {
    const url = await ask('Deploy URL (leave empty to skip)', '');
    if (url) { d.deployUrl = url; d.deployPlatform = 'Custom'; }
  } else {
    step(`Deploy URL: ${d.deployUrl}`);
  }

  if (!d.ghOwner) {
    d.ghOwner = await ask('GitHub username/org', 'your-username');
    d.ghRepo = await ask('Repository name', d.name.toLowerCase().replace(/[^a-z0-9-]/g, ''));
  } else {
    step(`GitHub: ${d.ghOwner}/${d.ghRepo}`);
  }

  console.log();
  return generate(cwd, d, opts);
}

// ─── Main ───────────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const cwd = process.cwd();

  // Current version
  const pkg = (() => { try { return require('../package.json'); } catch { return { version: '3.0.0' }; } })();
  const currentVer = pkg.version;

  // Background version check (non-blocking)
  checkVersion();

  // Version
  if (args.includes('--version') || args.includes('-v')) {
    console.log(currentVer);
    process.exit(0);
  }

  // Uprade command
  if (args[0] === 'upgrade') {
    // Wait for version check to complete
    await new Promise(r => setTimeout(r, 1500));
    upgrade(currentVer);
    process.exit(0);
  }

  // Help
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
  ${C.bold}${C.cyan}ShipKit${C.reset} — Your Automated Dev Team

  ${C.dim}One command sets up CI/CD, monitoring, security, and AI agent config.
  Only generates what your project actually needs. Zero dependencies.${C.reset}

  ${C.bold}Usage:${C.reset}
    ${C.green}npx shipkit-pipe${C.reset}              Auto-detect & generate
    ${C.green}npx shipkit-pipe check${C.reset}        Verify everything works
    ${C.green}npx shipkit-pipe check --json${C.reset}  Machine-readable output
    ${C.green}npx shipkit-pipe upgrade${C.reset}       Check for updates
    ${C.green}npx shipkit-pipe --force${C.reset}       Overwrite existing files
    ${C.green}npx shipkit-pipe --dry-run${C.reset}    Preview without writing files
    ${C.green}npx shipkit-pipe -i${C.reset}           Interactive (ask questions)
    ${C.green}npx shipkit-pipe --help${C.reset}        This message

  ${C.bold}What it does:${C.reset}
    • Reads your project files (package.json, lock files, git remote)
    • Generates CI that ONLY includes steps you have (lint/test/build)
    • Supports GitHub Actions, GitLab CI, and Bitbucket Pipelines
    • Sets up health monitoring (pings your site every 6h)
    • Creates AGENTS.md so your AI agent knows your project
    • Adds dependency updates + security scanning
    • Auto-checks for new versions (non-blocking)

  ${C.bold}Works with:${C.reset} Any framework, any CI platform, any AI agent, any deploy target.

  ${C.bold}No Node.js?${C.reset} Download from: https://github.com/sagar-grv/shipkit/releases
`);
    process.exit(0);
  }

  // Check command
  if (args[0] === 'check') {
    const asJson = args.includes('--json');
    await check(cwd, asJson);
    process.exit(0);
  }

  // Works in ANY directory — if the user ran it here, they want to set it up
  const d = detect(cwd);
  const isInteractive = args.includes('-i') || args.includes('--interactive');
  const isDryRun = args.includes('--dry-run') || args.includes('--preview');
  const isForce = args.includes('--force');

  // Dry run mode — show what would be generated
  if (isDryRun) {
    console.log(`\n  ${C.bold}${C.cyan}⚓ ShipKit${C.reset} — dry run (no files will be written)\n`);
    console.log(`  ${C.bold}Detected:${C.reset}`);
    console.log(`    Project:   ${d.name}`);
    console.log(`    Framework: ${d.frontend || 'Not detected'}`);
    console.log(`    Platform:  ${d.gitPlatform} ${d.ghOwner ? `(${d.ghOwner}/${d.ghRepo})` : ''}`);
    console.log(`    PM:        ${d.pm}`);
    console.log(`    Node:      ${d.nodeVer}`);
    console.log(`    Deploy:    ${d.deployPlatform || 'None'} ${d.deployUrl ? `(${d.deployUrl})` : ''}`);
    const found = [d.hasLint && 'lint', d.hasTypecheck && 'typecheck', d.hasTest && 'test', d.hasBuild && 'build'].filter(Boolean);
    console.log(`    Scripts:   ${found.length ? found.join(', ') : 'None detected'}`);
    if (d.isMonorepo) console.log(`    Monorepo:  ${d.subProjects.join(', ')}`);
    console.log(`\n  ${C.bold}Would generate:${C.reset}`);
    if (d.gitPlatform === 'gitlab') {
      console.log(`    .gitlab-ci.yml              ← CI: ${found.join(' > ') || 'install'}`);
    } else if (d.gitPlatform === 'bitbucket') {
      console.log(`    bitbucket-pipelines.yml     ← CI: ${found.join(' > ') || 'install'}`);
    } else {
      console.log(`    .github/workflows/ci.yml    ← CI: ${found.join(' > ') || 'install'}`);
      console.log(`    .github/dependabot.yml      ← Auto-update deps`);
      console.log(`    .github/workflows/codeql.yml← Security scanning`);
      if (d.deployUrl) console.log(`    .github/workflows/health.yml← Health check (every 6h)`);
    }
    console.log(`    shipkit.json                ← Project config`);
    console.log(`    AGENTS.md                   ← AI agent instructions`);
    console.log(`    LAST_SESSION.md             ← Session continuity`);
    console.log(`\n  ${C.dim}Run without --dry-run to generate these files.${C.reset}\n`);
    process.exit(0);
  }

  // Interactive mode
  if (isInteractive) {
    const { gen, skip } = await interactive(cwd, d, { force: isForce });
    console.log(`  ${C.green}✓ Generated ${gen} files${C.reset}${skip ? ` ${C.dim}(${skip} skipped)${C.reset}` : ''}\n`);
    if (isForce) step('--force: overwrote existing files');
    console.log(`  ${C.dim}Next: git add -A && git commit -m "add shipkit pipeline" && git push${C.reset}\n`);
    process.exit(0);
  }

  // ── Auto mode (default) ─────────────────────────────────────────────────
  console.log(`\n  ${C.bold}${C.cyan}⚓ ShipKit${C.reset} — ${d.name}\n`);

  const s = spinner('Detecting project...');
  await new Promise(r => setTimeout(r, 300)); // Brief pause for visual feedback

  // Build detection summary
  const parts = [d.frontend || 'Node.js', d.pm, `Node ${d.nodeVer}`].join(' | ');
  s.stop(parts);

  // Monorepo info
  if (d.isMonorepo) step(`Monorepo: ${d.subProjects.join(', ')}`);

  // Show what scripts were found
  const found = [d.hasLint && 'lint', d.hasTypecheck && 'typecheck', d.hasTest && 'test', d.hasBuild && 'build'].filter(Boolean);
  if (found.length) step(`Scripts: ${found.join(', ')}`);
  else dim('No scripts detected yet — CI will verify deps install cleanly');

  // Git
  if (d.ghOwner) step(`Git: ${d.ghOwner}/${d.ghRepo} (${d.gitPlatform})`);
  else if (d.hasGit) step(`Git: ${d.gitPlatform}`);
  else dim('No git repo — run "git init" to enable CI');

  // Deploy
  if (d.deployUrl) step(`Deploy: ${d.deployPlatform} (${d.deployUrl})`);
  else dim('No deploy URL detected — health checks will be skipped');

  // Warn about outdated version (non-blocking, only if we got the check result)
  warnIfOutdated(currentVer);

  // Generate
  console.log();
  const s2 = spinner('Generating pipeline...');
  const { gen, skip } = generate(cwd, d, { force: isForce });
  const forceMsg = isForce ? ' (--force)' : '';
  s2.stop(`Generated ${gen} files${skip ? ` (${skip} already exist)${forceMsg}` : forceMsg}`);

  // Summary
  console.log(`\n  ${C.cyan}Files:${C.reset}`);
  const showFile = (f, desc) => { if (fs.existsSync(path.join(cwd, f))) console.log(`    ${f.padEnd(35)} ${C.dim}← ${desc}${C.reset}`); };
  showFile('shipkit.json', 'Project config');
  showFile('AGENTS.md', 'AI agent instructions');
  showFile('LAST_SESSION.md', 'Session continuity');
  // Platform-specific CI
  if (d.gitPlatform === 'gitlab') {
    showFile('.gitlab-ci.yml', `CI: ${found.join(' > ') || 'install'}`);
  } else if (d.gitPlatform === 'bitbucket') {
    showFile('bitbucket-pipelines.yml', `CI: ${found.join(' > ') || 'install'}`);
  } else {
    showFile('.github/workflows/ci.yml', `CI: ${found.join(' > ') || 'install'}`);
    showFile('.github/workflows/health.yml', 'Health check (every 6h)');
    showFile('.github/dependabot.yml', 'Auto-update deps');
    showFile('.github/workflows/codeql.yml', 'Security scanning');
  }

  console.log(`\n  ${C.bold}Next:${C.reset} ${C.dim}git add -A && git commit -m "add pipeline" && git push${C.reset}`);
  console.log(`  ${C.bold}Verify:${C.reset} ${C.dim}npx shipkit-pipe check${C.reset}\n`);
}

main().catch(err => { console.error(`\n  ${C.red}Error:${C.reset} ${err.message}\n`); process.exit(1); });
