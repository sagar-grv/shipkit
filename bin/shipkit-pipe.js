#!/usr/bin/env node

/**
 * ShipKit — MVP to Production Pipeline
 * =======================================
 * One command connects your AI agent, CI/CD, security, and deploy.
 * Zero dependencies. Works with any stack.
 *
 * Usage:
 *   npx shipkit-pipe           Auto-detect & generate (no prompts)
 *   npx shipkit-pipe -i        Interactive mode (asks questions)
 *   npx shipkit-pipe --help    Show help
 *   npx shipkit-pipe --version Show version
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ─── ANSI Colors ────────────────────────────────────────────────────────────
const C = {
  reset: '\x1b[0m', bold: '\x1b[1m', dim: '\x1b[2m',
  green: '\x1b[32m', cyan: '\x1b[36m', yellow: '\x1b[33m', red: '\x1b[31m',
};

const pkg = (() => {
  try { return require('../package.json'); } catch { return { version: '2.0.1' }; }
})();

// ─── Helpers ────────────────────────────────────────────────────────────────

function title(text) { console.log(`\n${C.bold}${C.cyan}═══ ${text} ═══${C.reset}\n`); }
function step(msg) { console.log(`  ${C.green}✓${C.reset} ${msg}`); }
function info(msg) { console.log(`  ${C.yellow}${msg}${C.reset}`); }

// ─── Prompt System ──────────────────────────────────────────────────────────

const readline = require('readline');

function rl() {
  const r = readline.createInterface({ input: process.stdin, output: process.stdout });
  return {
    ask: (q, d) => new Promise(res => {
      const s = d ? ` [${d}]` : '';
      r.question(`  ${q}${s}: `, a => { r.close(); res(a.trim() || d); });
    }),
    confirm: (q, d) => new Promise(res => {
      const h = d ? 'Y/n' : 'y/N';
      r.question(`  ${q} (${h}): `, a => { r.close(); res(a ? a.toLowerCase().startsWith('y') : d); });
    }),
    choose: async (q, opts, d) => {
      console.log(`  ${C.yellow}${q}${C.reset}`);
      opts.forEach((o, i) => console.log(`    ${i+1}. ${o}${o === d ? ` ${C.green}(default)${C.reset}` : ''}`));
      const a = await new Promise(res => r.question(`  Enter number (1-${opts.length}): `, res));
      r.close();
      const n = parseInt(a, 10);
      return n >= 1 && n <= opts.length ? opts[n-1] : d || opts[0];
    }
  };
}

// ─── Auto-Detect ────────────────────────────────────────────────────────────

function detect(cwd) {
  const detected = {
    name: path.basename(cwd), desc: '', frontend: '', pm: 'npm',
    nodeVer: '20', build: 'npm run build', test: 'npm test',
    lint: 'npm run lint', hasGit: false, gitRemote: '', e2e: '',
  };

  const pkgPath = path.join(cwd, 'package.json');
  if (!fs.existsSync(pkgPath)) return detected;

  try {
    const p = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'));
    if (p.name) detected.name = p.name;
    if (p.description) detected.desc = p.description;

    const deps = { ...p.dependencies || {}, ...p.devDependencies || {} };
    if (deps.next) detected.frontend = 'Next.js';
    else if (deps['@remix-run/react']) detected.frontend = 'Remix';
    else if (deps.vue || deps.nuxt) detected.frontend = 'Vue/Nuxt';
    else if (deps['@sveltejs/kit'] || deps.svelte) detected.frontend = 'Svelte';
    else if (deps.react) detected.frontend = 'React';
    else if (deps.angular) detected.frontend = 'Angular';

    if (deps.playwright) detected.e2e = 'Playwright';
    else if (deps.cypress) detected.e2e = 'Cypress';

    if (fs.existsSync(path.join(cwd, 'pnpm-lock.yaml'))) detected.pm = 'pnpm';
    else if (fs.existsSync(path.join(cwd, 'yarn.lock'))) detected.pm = 'yarn';
  } catch { /* ignore */ }

  if (fs.existsSync(path.join(cwd, '.git'))) {
    detected.hasGit = true;
    try {
      detected.gitRemote = execSync('git config --get remote.origin.url', { encoding: 'utf-8', stdio: 'pipe' }).trim();
    } catch { /* no remote */ }
  }

  return detected;
}

// ─── Template Renderer ──────────────────────────────────────────────────────

function render(content, vars) {
  let r = content;
  for (const [k, v] of Object.entries(vars)) {
    r = r.replace(new RegExp(`\\{\\{${k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\}\\}`, 'g'), String(v ?? ''));
  }
  return r.replace(/\{%\s*if\s+(\w+)\s*%\}([\s\S]*?)\{%\s*endif\s*%\}/g, (_, n, inner) => {
    const val = vars[n]; return (val && val !== 'false' && val !== '0' && val !== '') ? inner : '';
  });
}

// ─── Generate Files ─────────────────────────────────────────────────────────

function generate(cwd, choices, detected) {
  const { projName, projDesc, agent, ghOwner, ghRepo, deploy, db, monitor } = choices;

  let agentDst = '';
  if (agent.startsWith('Claude Code')) agentDst = 'CLAUDE.md';
  else if (agent.startsWith('Cursor')) agentDst = '.cursorrules';
  else if (agent.startsWith('GitHub Copilot')) agentDst = '.github/copilot-instructions.md';
  else if (agent.startsWith('OpenCode')) agentDst = '.opencode/agents/co-developer.md';

  const storage = db.includes('Supabase') ? 'Supabase Storage'
    : db.includes('Firebase') ? 'Firebase Storage' : 'Cloud storage';

  const vars = {
    PROJECT_NAME: projName, PROJECT_DESCRIPTION: projDesc,
    DATE: new Date().toISOString().split('T')[0],
    STACK_FRONTEND: detected.frontend || 'Web application',
    STACK_DATABASE: db, STACK_AUTH: db, STACK_DEPLOY: deploy,
    STACK_STORAGE: storage, STACK_AI: '', STACK_E2E: detected.e2e || 'Playwright',
    STACK_ANALYTICS: monitor,
    NODE_VERSION: detected.nodeVer, BUILD_COMMAND: detected.build,
    TEST_COMMAND: detected.test, LINT_COMMAND: detected.lint,
    TYPECHECK_COMMAND: 'npx tsc --noEmit', PACKAGE_MANAGER: detected.pm,
    COVERAGE_ENABLED: 'true',
    DATABASE_TYPE: db, DATABASE_PROJECT_ID: '', DATABASE_REGION: '',
    RLS_ENABLED: db.includes('Supabase') ? 'true' : 'false',
    GITHUB_OWNER: ghOwner, GITHUB_REPO: ghRepo,
    DEPLOY_PLATFORM: deploy, DEPLOY_PROJECT_ID: '',
    PREVIEW_URLS_ENABLED: deploy === 'Vercel' ? 'true' : 'false',
    MONITORING_PLATFORM: monitor, MONITORING_ORG: '', MONITORING_PROJECT: '',
    BUILD_ENV_VARS: [], AI_AGENT: agent, AGENT_CONFIG_FILES: agentDst || 'AGENTS.md',
  };

  // Find template dir
  const tmplDir = (p => {
    const dirs = [
      path.join(path.dirname(require.resolve('../package.json')), 'template'),
      path.join(__dirname, '..', 'template'),
      path.join(cwd, 'template'),
    ];
    return dirs.find(d => fs.existsSync(d));
  })();

  if (!tmplDir) { console.error(`${C.red}Template directory not found. Reinstall shipkit-pipe.${C.reset}`); process.exit(1); }

  const files = [
    ['github/dependabot.yml', '.github/dependabot.yml'],
    ['github/workflows/ci.yml', '.github/workflows/ci.yml'],
    ['github/workflows/codeql.yml', '.github/workflows/codeql.yml'],
    ['github/workflows/playwright.yml', '.github/workflows/playwright.yml'],
    ['agents/co-developer.md', 'shipkit/co-developer.md'],
    ['agents/planner.md', 'shipkit/planner.md'],
    ['agents/security-reviewer.md', 'shipkit/security-reviewer.md'],
    ['agents/monitor.md', 'shipkit/monitor.md'],
    ['husky/pre-commit', '.husky/pre-commit'],
    ['docs/AGENTS.md', 'AGENTS.md'],
    ['docs/ROADMAP.md', 'ROADMAP.md'],
    ['docs/BUGS.md', 'BUGS.md'],
    ['docs/LAST_SESSION.md', 'LAST_SESSION.md'],
  ];

  let gen = 0, skip = 0;

  for (const [src, dst] of files) {
    const srcPath = path.join(tmplDir, src);
    const dstPath = path.join(cwd, dst);
    if (!fs.existsSync(srcPath)) continue;
    if (fs.existsSync(dstPath)) { skip++; continue; }
    fs.mkdirSync(path.dirname(dstPath), { recursive: true });
    fs.writeFileSync(dstPath, render(fs.readFileSync(srcPath, 'utf-8'), vars), 'utf-8');
    gen++;
  }

  // Agent config file
  if (agentDst) {
    const ap = path.join(cwd, agentDst);
    if (!fs.existsSync(ap)) {
      fs.mkdirSync(path.dirname(ap), { recursive: true });
      fs.writeFileSync(ap, `# ${projName} — AI Agent Configuration\n\nThis file configures your AI agent (${agent}) for **${projName}**.\n\n→ Read \`AGENTS.md\` for the full protocol and rules\n→ Read \`shipkit.json\` for project config and tech stack\n→ Read \`ROADMAP.md\` for what's planned\n→ Read \`BUGS.md\` for what's broken\n→ Read \`LAST_SESSION.md\` for session continuity\n\n## Quick Start\n- Say "plan: <feature>" to start the planning process\n- Say "review security" before pushing changes\n- Say "check errors" at session start\n`, 'utf-8');
      gen++;
    } else { skip++; }
  }

  // shipkit.json
  const sjPath = path.join(cwd, 'shipkit.json');
  if (!fs.existsSync(sjPath)) {
    fs.writeFileSync(sjPath, JSON.stringify({
      project: { name: projName, description: projDesc },
      stack: { frontend: vars.STACK_FRONTEND, database: db, auth: db, deploy, storage, e2e: vars.STACK_E2E, monitoring: monitor },
      ci: { nodeVersion: vars.NODE_VERSION, buildCommand: vars.BUILD_COMMAND, testCommand: vars.TEST_COMMAND, lintCommand: vars.LINT_COMMAND, packageManager: vars.PACKAGE_MANAGER },
      aiAgent: { tool: agent, configFiles: vars.AGENT_CONFIG_FILES },
      github: { owner: ghOwner, repo: ghRepo },
      deploy: { platform: deploy, projectId: '', previewUrls: deploy === 'Vercel' },
      database: { type: db, rlsEnabled: db.includes('Supabase') },
      monitoring: { platform: monitor },
      version: pkg.version,
    }, null, 2), 'utf-8');
    gen++;
  } else { skip++; }

  return { gen, skip, agentDst, agent };
}

// ─── Main ───────────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const cwd = process.cwd();

  // --version
  if (args.includes('--version') || args.includes('-v')) {
    console.log(pkg.version);
    process.exit(0);
  }

  // --help
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
${C.bold}${C.cyan}ShipKit${C.reset} — MVP to Production Pipeline v${pkg.version}

${C.dim}One command connects your AI agent, CI/CD, security, and deploy.${C.reset}

${C.bold}Usage:${C.reset}
  ${C.green}npx shipkit-pipe${C.reset}               Auto-detect & generate (no prompts)
  ${C.green}npx shipkit-pipe -i${C.reset}           Interactive mode (asks questions)
  ${C.green}npx shipkit-pipe --help${C.reset}        Show this message
  ${C.green}npx shipkit-pipe --version${C.reset}     Show version

${C.bold}What it generates:${C.reset}
  • AGENTS.md + shipkit.json   ← Your AI agent knows your stack
  • .github/workflows/         ← CI/CD: lint → test → build
  • .github/workflows/         ← CI/CD: lint → test → build
  • .github/dependabot.yml     ← Dependency updates
  • .husky/pre-commit          ← Pre-commit hooks
  • shipkit/                   ← Planner, security, monitor prompts

${C.dim}Works with Claude Code, Cursor, Copilot, OpenCode, any agent.${C.reset}
${C.dim}https://github.com/sagar-grv/shipkit${C.reset}
`);
    process.exit(0);
  }

  // Check for project
  if (!fs.existsSync(path.join(cwd, 'package.json'))) {
    console.log(`\n  ${C.red}✗ No project found.${C.reset}`);
    console.log(`  Run this inside your project folder:\n`);
    console.log(`    ${C.cyan}cd my-project${C.reset}`);
    console.log(`    ${C.cyan}npx shipkit-pipe${C.reset}\n`);
    process.exit(1);
  }

  const interactive = args.includes('-i') || args.includes('--interactive');
  const detected = detect(cwd);

  // ── Auto mode (default) ─────────────────────────────────────────────────
  if (!interactive) {
    console.log(`\n  ${C.bold}${C.cyan}⚓ ShipKit${C.reset} — ${detected.name}\n`);

    const defaults = {
      projName: detected.name,
      projDesc: detected.desc || 'A web application',
      agent: 'Claude Code (Anthropic)',
      ghOwner: '', ghRepo: '',
      deploy: 'Vercel', db: 'Supabase Postgres', monitor: 'Sentry',
    };

    if (detected.gitRemote) {
      const m = detected.gitRemote.match(/[:/]([^/]+)\/([^/.]+)(?:\.git)?$/);
      if (m) { defaults.ghOwner = m[1]; defaults.ghRepo = m[2]; }
    }
    if (!defaults.ghOwner) {
      defaults.ghOwner = 'your-username';
      defaults.ghRepo = detected.name.toLowerCase().replace(/[^a-z0-9-]/g, '');
    }

    const hasVercel = fs.existsSync(path.join(cwd, 'vercel.json')) || fs.existsSync(path.join(cwd, '.vercel'));
    const hasNetlify = fs.existsSync(path.join(cwd, 'netlify.toml'));
    if (hasVercel) defaults.deploy = 'Vercel';
    else if (hasNetlify) defaults.deploy = 'Netlify';

    const { gen, skip } = generate(cwd, defaults, detected);

    console.log(`  ${C.green}✓ Generated ${gen} files${C.reset}${skip ? ` (${skip} skipped)` : ''}`);
    console.log(`  ${C.dim}Run with -i for interactive mode${C.reset}\n`);
    process.exit(0);
  }

  // ── Interactive mode ────────────────────────────────────────────────────
  const term = rl();

  console.log(`\n  ${C.bold}${C.cyan}⚓ ShipKit${C.reset} — interactive setup\n`);

  title('PROJECT');
  const projName = await term.ask('Project name', detected.name);
  const projDesc = await term.ask('Description', detected.desc || 'A web application');

  title('AI AGENT');
  const agent = await term.choose('Which AI agent do you use?',
    ['Claude Code (Anthropic)', 'Cursor', 'GitHub Copilot', 'OpenCode', 'CodeGPT', 'Continue.dev', 'Cline', 'Aider', 'Other'],
    'Claude Code (Anthropic)');

  title('GITHUB');
  let ghOwner = '', ghRepo = '';
  if (detected.gitRemote) {
    const m = detected.gitRemote.match(/[:/]([^/]+)\/([^/.]+)(?:\.git)?$/);
    if (m) { ghOwner = m[1]; ghRepo = m[2]; step(`Detected: ${m[1]}/${m[2]}`); }
  }
  if (!ghOwner) {
    ghOwner = await term.ask('GitHub username/organization', 'your-username');
    ghRepo = await term.ask('Repository name', projName.toLowerCase().replace(/[^a-z0-9-]/g, ''));
  }

  title('DEPLOY');
  const deploy = await term.choose('Where do you deploy?',
    ['Vercel', 'Netlify', 'Fly.io', 'Railway', 'Render', 'Cloudflare Pages', 'Docker / Self-hosted', 'AWS', 'GCP', 'None yet'],
    'Vercel');

  title('DATABASE');
  const db = await term.choose('Which database do you use?',
    ['Supabase Postgres', 'Firebase Firestore', 'MongoDB', 'PostgreSQL', 'MySQL', 'SQLite', 'None yet'],
    'Supabase Postgres');

  title('MONITORING');
  const monitor = await term.choose('Error tracking / monitoring?',
    ['Sentry', 'Datadog', 'LogRocket', 'PostHog', 'None'], 'Sentry');

  console.log();
  const { gen, skip, agentDst } = generate(cwd, { projName, projDesc, agent, ghOwner, ghRepo, deploy, db, monitor }, detected);

  title('DONE');
  console.log(`  ${C.green}✓ Generated ${gen} files for ${C.bold}${projName}${C.reset}${skip ? ` (${skip} skipped)` : ''}`);
  console.log(`\n  ${C.cyan}Files created:${C.reset}`);
  console.log(`    shipkit.json      ← Config for your AI agent`);
  console.log(`    AGENTS.md         ← AI agent protocol`);
  console.log(`    ROADMAP.md        ← Feature tracker`);
  console.log(`    BUGS.md           ← Bug tracker`);
  console.log(`    LAST_SESSION.md   ← Session continuity`);
    console.log(`    shipkit/          ← AI agent prompts`);
    console.log(`    .github/          ← CI/CD + Security`);
    console.log(`    .husky/pre-commit ← Pre-commit hooks`);
  if (agentDst) console.log(`    ${agentDst.padEnd(18)} ← ${agent} config`);
  console.log(`\n  ${C.cyan}Next steps:${C.reset}`);
  console.log(`    1. ${C.bold}npm install --save-dev husky lint-staged${C.reset}`);
  console.log(`    2. ${C.bold}git init && git add -A && git commit -m "init"${C.reset}`);
  console.log(`    3. ${C.bold}git push origin main${C.reset}`);
  console.log(`    4. Open in your AI agent → say: ${C.green}"plan: <feature>"${C.reset}\n`);
}

main().catch(err => { console.error(`${C.red}Error:${C.reset} ${err.message}`); process.exit(1); });
