#!/usr/bin/env node

/**
 * ShipKit — MVP to Production Pipeline
 * =======================================
 * Zero-dependency CLI. Works on any platform with Node >= 18.
 *
 * Usage:
 *   npx shipkit-pipe setup        Run the interactive setup wizard
 *   npx shipkit-pipe --help       Show help
 *   npx shipkit-pipe --version    Show version
 */

'use strict';

// ─── ANSI Colors (zero deps) ────────────────────────────────────────────────
const C = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  cyan: '\x1b[36m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
};

// ─── Helpers ────────────────────────────────────────────────────────────────

const pkg = (() => {
  try { return require('../package.json'); } catch { return { version: '2.0.1' }; }
})();

function wrap(msg, ...colors) {
  return colors.join('') + msg + C.reset;
}

function title(text) {
  console.log(`\n${C.bold}${C.cyan}═════ ${text} ═════${C.reset}\n`);
}

function step(text) {
  console.log(`${C.green}✓${C.reset} ${text}`);
}

function info(text) {
  console.log(`  ${C.yellow}${text}${C.reset}`);
}

function warn(text) {
  console.log(`  ${C.red}${text}${C.reset}`);
}

// ─── Prompt System (readline-based, zero deps) ──────────────────────────────

const readline = require('readline');

function createPrompt() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return {
    question: (query) => new Promise((resolve) => rl.question(query, resolve)),
    close: () => rl.close(),
  };
}

async function ask(question, defaultValue = '') {
  const prompt = createPrompt();
  const defaultStr = defaultValue ? ` [${defaultValue}]` : '';
  const answer = await prompt.question(`  ${question}${defaultStr}: `);
  prompt.close();
  return answer.trim() || defaultValue;
}

async function confirm(question, defaultYes = true) {
  const prompt = createPrompt();
  const hint = defaultYes ? 'Y/n' : 'y/N';
  const answer = await prompt.question(`  ${question} (${hint}): `);
  prompt.close();
  if (!answer.trim()) return defaultYes;
  return answer.toLowerCase().startsWith('y');
}

async function choose(question, options, defaultOption) {
  console.log(`  ${C.yellow}${question}${C.reset}`);
  for (let i = 0; i < options.length; i++) {
    const isDefault = options[i] === defaultOption;
    const mark = isDefault ? ` ${C.green}(default)${C.reset}` : '';
    console.log(`    ${i + 1}. ${options[i]}${mark}`);
  }
  const answer = await ask(`Enter number (1-${options.length})`, '');
  const num = parseInt(answer, 10);
  if (num >= 1 && num <= options.length) return options[num - 1];
  return defaultOption || options[0];
}

// ─── Auto-Detect ────────────────────────────────────────────────────────────

function detectProject() {
  const fs = require('fs');
  const path = require('path');
  const cwd = process.cwd();

  const detected = {
    projectName: path.basename(cwd),
    projectDesc: '',
    frontend: '',
    packageManager: 'npm',
    nodeVersion: '20',
    buildCommand: 'npm run build',
    testCommand: 'npm test',
    lintCommand: 'npm run lint',
    hasGit: false,
    gitRemote: '',
    e2e: '',
  };

  // Check package.json
  const pkgPath = path.join(cwd, 'package.json');
  if (fs.existsSync(pkgPath)) {
    try {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'));
      if (pkg.name) detected.projectName = pkg.name;
      if (pkg.description) detected.projectDesc = pkg.description;

      const allDeps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };
      if (allDeps.next) detected.frontend = 'Next.js';
      else if (allDeps['@remix-run/react']) detected.frontend = 'Remix';
      else if (allDeps.vue || allDeps.nuxt) detected.frontend = 'Vue/Nuxt';
      else if (allDeps.svelte || allDeps['@sveltejs/kit']) detected.frontend = 'Svelte/SvelteKit';
      else if (allDeps.react) detected.frontend = 'React';
      else if (allDeps.angular) detected.frontend = 'Angular';

      if (allDeps.playwright) detected.e2e = 'Playwright';
      else if (allDeps.cypress) detected.e2e = 'Cypress';

      if (pkg.scripts) {
        if (pkg.scripts.build) detected.buildCommand = 'npm run build';
        if (pkg.scripts.test) detected.testCommand = 'npm test';
        if (pkg.scripts.lint) detected.lintCommand = 'npm run lint';
      }

      // Detect package manager
      if (fs.existsSync(path.join(cwd, 'pnpm-lock.yaml'))) detected.packageManager = 'pnpm';
      else if (fs.existsSync(path.join(cwd, 'yarn.lock'))) detected.packageManager = 'yarn';
    } catch { /* ignore */ }
  }

  // Check git
  if (fs.existsSync(path.join(cwd, '.git'))) {
    detected.hasGit = true;
    const { execSync } = require('child_process');
    try {
      const remote = execSync('git config --get remote.origin.url', { encoding: 'utf-8', stdio: 'pipe' }).trim();
      if (remote) detected.gitRemote = remote;
    } catch { /* no remote */ }
  }

  return detected;
}

// ─── Template Engine ────────────────────────────────────────────────────────

function renderTemplate(content, vars) {
  let result = content;

  // Replace {{VAR}} placeholders (function-based to avoid $ injection in replacement value)
  for (const [key, val] of Object.entries(vars)) {
    const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    result = result.replace(new RegExp(`\\{\\{${escaped}\\}\\}`, 'g'), () => String(val ?? ''));
  }

  // Handle {% if VAR %}...{% endif %}
  result = result.replace(/\{%\s*if\s+(\w+)\s*%\}(.*?)\{%\s*endif\s*%\}/gs, (_, varName, inner) => {
    const val = vars[varName];
    const truthy = val && val !== 'false' && val !== '0' && val !== '';
    return truthy ? inner : '';
  });

  return result;
}

// ─── Setup Wizard ───────────────────────────────────────────────────────────

async function setup() {
  const fs = require('fs');
  const path = require('path');

  // Support --cwd <dir> for testing
  const args = process.argv.slice(2);
  const cwdIndex = args.indexOf('--cwd');
  if (cwdIndex >= 0 && cwdIndex + 1 < args.length) {
    const targetDir = path.resolve(args[cwdIndex + 1]);
    process.chdir(targetDir);
  }

  const cwd = process.cwd();
  const detected = detectProject();

  // ── Welcome ───────────────────────────────────────────────────────────────
  console.log(`
${C.bold}${C.cyan} ⚓ ShipKit — MVP to Production Pipeline${C.reset}
${C.dim}   Connect your tools. Ship to production. No team required.${C.reset}

   ${C.green}This will set up:${C.reset}
   • CI/CD pipeline (GitHub Actions)
   • AI agent protocol (works with Claude, Cursor, Copilot, any agent)
   • Security scanning (CodeQL + Dependabot)
   • Pre-commit hooks (Husky + lint-staged)
   • Session continuity for your AI agent

${C.dim}   Takes ~2 minutes. Works with any stack.${C.reset}
`);

  console.log(`${C.dim}   Detected: ${detected.frontend || 'unknown stack'} | ${detected.packageManager} | ${path.basename(cwd)}${C.reset}\n`);

  // ── Detect defaults for non-interactive mode ───────────────────────────
  const defaults = {
    projName: detected.projectName,
    projDesc: detected.projectDesc || 'A web application',
    selectedAgent: 'Claude Code (Anthropic)',
    ghOwner: '',
    ghRepo: '',
    deployPlatform: '',
    dbChoice: '',
    monitorChoice: 'Sentry',
  };

  // Extract git remote info
  if (detected.gitRemote) {
    const match = detected.gitRemote.match(/[:/]([^/]+)\/([^/.]+)(?:\.git)?$/);
    if (match) {
      defaults.ghOwner = match[1];
      defaults.ghRepo = match[2];
    }
  }

  // Detect deploy platform
  const hasVercel = fs.existsSync(path.join(cwd, 'vercel.json')) || fs.existsSync(path.join(cwd, '.vercel'));
  const hasNetlify = fs.existsSync(path.join(cwd, 'netlify.toml'));
  defaults.deployPlatform = hasVercel ? 'Vercel' : (hasNetlify ? 'Netlify' : 'Vercel');

  // Detect database
  const hasSupabase = fs.existsSync(path.join(cwd, 'supabase')) || fs.existsSync(path.join(cwd, 'supabase.json'));
  const hasFirebase = fs.existsSync(path.join(cwd, 'firebase.json'));
  defaults.dbChoice = hasSupabase ? 'Supabase Postgres' : (hasFirebase ? 'Firebase Firestore' : 'Supabase Postgres');

  // Detect monitoring
  const hasSentry = fs.existsSync(path.join(cwd, '.sentryclirc')) || fs.existsSync(path.join(cwd, 'sentry.client.config.ts'));
  if (hasSentry) defaults.monitorChoice = 'Sentry';

  // ── Non-interactive mode ──────────────────────────────────────────────
  const useDefaults = process.argv.includes('--defaults') || process.argv.includes('-y');

  if (useDefaults) {
    if (!defaults.ghOwner) {
      defaults.ghOwner = 'your-username';
      defaults.ghRepo = detected.projectName.toLowerCase().replace(/[^a-z0-9-]/g, '');
    }
    return await generateFiles(cwd, defaults, detected);
  }
  // ── End non-interactive gate ──────────────────────────────────────────

  // ── 1. Project Info ─────────────────────────────────────────────────────
  title('PROJECT');
  const projName = await ask('Project name', defaults.projName);
  const projDesc = await ask('Description', defaults.projDesc);

  // ── 2. AI Agent ─────────────────────────────────────────────────────────
  title('AI AGENT');
  const agentOptions = ['Claude Code (Anthropic)', 'Cursor', 'GitHub Copilot', 'OpenCode', 'CodeGPT', 'Continue.dev', 'Cline', 'Aider', 'Other / Custom'];
  const selectedAgent = await choose('Which AI agent do you use?', agentOptions, defaults.selectedAgent);

  // ── 3. GitHub ──────────────────────────────────────────────────────────
  title('GITHUB');
  let ghOwner = defaults.ghOwner;
  let ghRepo = defaults.ghRepo;

  if (!ghOwner) {
    ghOwner = await ask('GitHub username/organization', 'your-username');
    ghRepo = await ask('GitHub repository name', projName.toLowerCase().replace(/[^a-z0-9-]/g, ''));
  } else {
    step(`Detected: ${ghOwner}/${ghRepo}`);
  }

  // ── 4. Deploy Platform ────────────────────────────────────────────────
  title('DEPLOY');
  const deployOptions = ['Vercel', 'Netlify', 'Fly.io', 'Railway', 'Render', 'Cloudflare Pages', 'Docker / Self-hosted', 'AWS', 'GCP', 'None yet'];
  const deployPlatform = await choose('Where do you deploy?', deployOptions, defaults.deployPlatform);

  // ── 5. Database ────────────────────────────────────────────────────────
  title('DATABASE');
  const dbOptions = ['Supabase Postgres', 'Firebase Firestore', 'MongoDB', 'PostgreSQL', 'MySQL', 'SQLite', 'None yet'];
  const dbChoice = await choose('Which database do you use?', dbOptions, defaults.dbChoice);

  // ── 6. Monitoring (optional) ──────────────────────────────────────────
  title('MONITORING');
  const monitorOptions = ['Sentry', 'Datadog', 'LogRocket', 'PostHog', 'None'];
  const monitorChoice = await choose('Error tracking / monitoring?', monitorOptions, defaults.monitorChoice);

  return await generateFiles(cwd, {
    projName, projDesc,
    selectedAgent,
    ghOwner, ghRepo,
    deployPlatform, dbChoice, monitorChoice,
  }, detected);
}

// ─── File Generation ────────────────────────────────────────────────────────

async function generateFiles(cwd, choices, detected) {
  const fs = require('fs');
  const path = require('path');

  const { projName, projDesc, selectedAgent, ghOwner, ghRepo, deployPlatform, dbChoice, monitorChoice } = choices;

  // Map agent to config file path
  let agentConfigDst = '';
  if (selectedAgent.startsWith('Claude Code')) agentConfigDst = 'CLAUDE.md';
  else if (selectedAgent.startsWith('Cursor')) agentConfigDst = '.cursorrules';
  else if (selectedAgent.startsWith('GitHub Copilot')) agentConfigDst = '.github/copilot-instructions.md';
  else if (selectedAgent.startsWith('OpenCode')) agentConfigDst = '.opencode/agents/co-developer.md';

  // ── Map DB to storage ────────────────────────────────────────────────
  const storageChoice = dbChoice.includes('Supabase') ? 'Supabase Storage'
    : dbChoice.includes('Firebase') ? 'Firebase Storage'
    : 'Cloud storage';

  // ── Build variables ────────────────────────────────────────────────────
  // Variables are categorized:
  //   [T] = used in template files (AGENTS.md, workflows, etc.)
  //   [C] = stored in shipkit.json only (config, not rendered into templates)
  const vars = {
    // ── [T] Project info ──────────────────────────────────────────────
    PROJECT_NAME: projName,
    PROJECT_DESCRIPTION: projDesc,
    DATE: new Date().toISOString().split('T')[0],

    // ── [T] Stack ─────────────────────────────────────────────────────
    STACK_FRONTEND: detected.frontend || 'Web application',
    STACK_DATABASE: dbChoice,
    STACK_AUTH: dbChoice,
    STACK_DEPLOY: deployPlatform,
    STACK_STORAGE: storageChoice,
    STACK_AI: '', // [T] Set in shipkit.json later (Gemini, OpenAI, etc.)
    STACK_E2E: detected.e2e || 'Playwright',
    STACK_ANALYTICS: monitorChoice,

    // ── [T] CI ─────────────────────────────────────────────────────────
    NODE_VERSION: detected.nodeVersion,
    BUILD_COMMAND: detected.buildCommand,
    TEST_COMMAND: detected.testCommand,
    LINT_COMMAND: detected.lintCommand,
    TYPECHECK_COMMAND: 'npx tsc --noEmit',
    PACKAGE_MANAGER: detected.packageManager,
    COVERAGE_ENABLED: 'true',

    // ── [C] Database (stored in shipkit.json) ──────────────────────────
    DATABASE_TYPE: dbChoice,
    DATABASE_PROJECT_ID: '',
    DATABASE_REGION: '',
    RLS_ENABLED: dbChoice.includes('Supabase') ? 'true' : 'false',

    // ── [C] GitHub (stored in shipkit.json) ────────────────────────────
    GITHUB_OWNER: ghOwner,
    GITHUB_REPO: ghRepo,

    // ── [C] Deploy (stored in shipkit.json) ────────────────────────────
    DEPLOY_PLATFORM: deployPlatform,
    DEPLOY_PROJECT_ID: '',
    PREVIEW_URLS_ENABLED: deployPlatform === 'Vercel' ? 'true' : 'false',

    // ── [C] Monitoring (stored in shipkit.json) ────────────────────────
    MONITORING_PLATFORM: monitorChoice,
    MONITORING_ORG: '',
    MONITORING_PROJECT: '',

    // ── [C] AI Agent (stored in shipkit.json) ──────────────────────────
    BUILD_ENV_VARS: [],
    AI_AGENT: selectedAgent,
    AGENT_CONFIG_FILES: agentConfigDst || 'AGENTS.md',
  };

  // ── Generate Files ────────────────────────────────────────────────────
  title('GENERATING FILES');

  // Find template directory
  const scriptDir = path.dirname(require.resolve('../package.json'));
  const templateDir = path.join(scriptDir, 'template');

  // Fallback: try relative to this script
  const altTemplateDir = path.join(__dirname, '..', 'template');

  const tmplDir = fs.existsSync(templateDir) ? templateDir
    : fs.existsSync(altTemplateDir) ? altTemplateDir
    : path.join(cwd, 'template');

  if (!fs.existsSync(tmplDir)) {
    warn('Template directory not found. Ensure shipkit-pipe is properly installed.');
    warn(`Looked in: ${templateDir} and ${altTemplateDir}`);
    process.exit(1);
  }

  const files = [
    { src: path.join('github', 'dependabot.yml'), dst: path.join('.github', 'dependabot.yml') },
    { src: path.join('github', 'workflows', 'ci.yml'), dst: path.join('.github', 'workflows', 'ci.yml') },
    { src: path.join('github', 'workflows', 'codeql.yml'), dst: path.join('.github', 'workflows', 'codeql.yml') },
    { src: path.join('github', 'workflows', 'playwright.yml'), dst: path.join('.github', 'workflows', 'playwright.yml') },
    { src: path.join('agents', 'co-developer.md'), dst: path.join('shipkit', 'co-developer.md') },
    { src: path.join('agents', 'planner.md'), dst: path.join('shipkit', 'planner.md') },
    { src: path.join('agents', 'security-reviewer.md'), dst: path.join('shipkit', 'security-reviewer.md') },
    { src: path.join('agents', 'monitor.md'), dst: path.join('shipkit', 'monitor.md') },
    // NOTE: .husky/pre-commit is NOT generated from template — it's created by the Husky setup step below
    { src: path.join('docs', 'AGENTS.md'), dst: 'AGENTS.md' },
    { src: path.join('docs', 'ROADMAP.md'), dst: 'ROADMAP.md' },
    { src: path.join('docs', 'BUGS.md'), dst: 'BUGS.md' },
    { src: path.join('docs', 'LAST_SESSION.md'), dst: 'LAST_SESSION.md' },
  ];

  let generated = 0;
  let skipped = 0;

  for (const file of files) {
    const srcPath = path.join(tmplDir, file.src);
    const dstPath = path.join(cwd, file.dst);

    if (!fs.existsSync(srcPath)) {
      warn(`Template not found: ${file.src}`);
      continue;
    }

    // Check if destination exists (skip if so)
    if (fs.existsSync(dstPath)) {
      info(`SKIP: ${file.dst} (already exists)`);
      skipped++;
      continue;
    }

    // Create dir
    fs.mkdirSync(path.dirname(dstPath), { recursive: true });

    // Read, render, write
    let content = fs.readFileSync(srcPath, 'utf-8');
    content = renderTemplate(content, vars);

    // For the pre-commit hook, ensure it's executable-friendly
    fs.writeFileSync(dstPath, content, 'utf-8');
    step(`Created ${file.dst}`);
    generated++;
  }

  // ── Generate AI-agent-specific config ──────────────────────────────────
  if (agentConfigDst) {
    const agentPath = path.join(cwd, agentConfigDst);
    if (!fs.existsSync(agentPath)) {
      fs.mkdirSync(path.dirname(agentPath), { recursive: true });
      const agentContent = `# ${projName} — AI Agent Configuration

This file configures your AI agent (${selectedAgent}) for **${projName}**.

→ Read \`AGENTS.md\` for the full protocol and rules
→ Read \`shipkit.json\` for project config and tech stack
→ Read \`ROADMAP.md\` for what's planned
→ Read \`BUGS.md\` for what's broken
→ Read \`LAST_SESSION.md\` for session continuity

## Quick Start
- Say "plan: <feature>" to start the planning process
- Say "review security" before pushing changes
- Say "check errors" at session start
`;
      fs.writeFileSync(agentPath, agentContent, 'utf-8');
      step(`Created ${agentConfigDst}`);
      generated++;
    } else {
      info(`SKIP: ${agentConfigDst} (already exists)`);
      skipped++;
    }
  }

  // ── Generate shipkit.json ──────────────────────────────────────────────
  const shipkitJson = {
    project: { name: projName, description: projDesc },
    stack: {
      frontend: vars.STACK_FRONTEND,
      database: vars.STACK_DATABASE,
      auth: vars.STACK_AUTH,
      deploy: vars.STACK_DEPLOY,
      storage: vars.STACK_STORAGE,
      e2e: vars.STACK_E2E,
      monitoring: vars.STACK_ANALYTICS,
    },
    ci: {
      nodeVersion: vars.NODE_VERSION,
      buildCommand: vars.BUILD_COMMAND,
      testCommand: vars.TEST_COMMAND,
      lintCommand: vars.LINT_COMMAND,
      packageManager: vars.PACKAGE_MANAGER,
    },
    aiAgent: {
      tool: vars.AI_AGENT,
      configFiles: vars.AGENT_CONFIG_FILES,
    },
    github: {
      owner: vars.GITHUB_OWNER,
      repo: vars.GITHUB_REPO,
    },
    deploy: {
      platform: vars.DEPLOY_PLATFORM,
      projectId: vars.DEPLOY_PROJECT_ID,
      previewUrls: vars.PREVIEW_URLS_ENABLED === 'true',
    },
    database: {
      type: vars.DATABASE_TYPE,
      rlsEnabled: vars.RLS_ENABLED === 'true',
    },
    monitoring: {
      platform: vars.MONITORING_PLATFORM,
    },
    version: '2.0.1',
  };

  const shipkitPath = path.join(cwd, 'shipkit.json');
  if (!fs.existsSync(shipkitPath)) {
    fs.writeFileSync(shipkitPath, JSON.stringify(shipkitJson, null, 2), 'utf-8');
    step('Created shipkit.json');
    generated++;
  } else {
    info('SKIP: shipkit.json (already exists)');
    skipped++;
  }

  // ── Husky setup ────────────────────────────────────────────────────────
  const useDefaults = process.argv.includes('--defaults') || process.argv.includes('-y');
  title('OPTIONAL: PRE-COMMIT HOOKS');
  let wantHusky = useDefaults; // skip prompt in non-interactive mode
  if (!useDefaults) {
    wantHusky = await confirm('Set up Husky pre-commit hooks? (requires Node.js)', true);
  }
  if (wantHusky) {
    try {
      const { execSync } = require('child_process');
      const huskyDir = path.join(cwd, '.husky');

      if (!fs.existsSync(huskyDir)) {
        execSync('npx husky init', { cwd, stdio: 'pipe', timeout: 30000 });
        step('Husky initialized');
      } else {
        info('Husky already initialized');
      }

      // Ensure pre-commit hook has lint-staged
      const hookFile = path.join(huskyDir, 'pre-commit');
      if (fs.existsSync(hookFile)) {
        const hookContent = fs.readFileSync(hookFile, 'utf-8');
        if (!hookContent.includes('lint-staged')) {
          fs.writeFileSync(hookFile, `. "$(dirname "$0")/_/husky.sh"\n\nnpx lint-staged\n`, 'utf-8');
        }
      }
      step('Pre-commit hooks configured.');
      info('Remember to: npm install --save-dev husky lint-staged');
    } catch (e) {
      info(`Husky setup skipped (${e.message})`);
      info('Run "npx husky init && npm install --save-dev husky lint-staged" manually.');
    }
  }

  // ── Summary ────────────────────────────────────────────────────────────
  title('DONE!');

  console.log(`
${C.green}✓${C.reset} Generated ${generated} files for ${C.bold}${projName}${C.reset}
${skipped > 0 ? `  ${C.yellow}${skipped} files skipped (already exist)${C.reset}\n` : ''}
${C.cyan}Files created:${C.reset}
  shipkit.json            ← Config for your AI agent
  AGENTS.md               ← Universal AI agent protocol
  ROADMAP.md              ← Feature tracker
  BUGS.md                 ← Bug tracker
  LAST_SESSION.md         ← Session continuity
  shipkit/                ← AI agent prompts
  .github/workflows/      ← CI/CD + Security
  .husky/pre-commit       ← Pre-commit hooks
${agentConfigDst ? `  ${agentConfigDst.padEnd(Math.max(agentConfigDst.length + 2, 23))} ← ${selectedAgent} config\n` : ''}
${C.cyan}Next Steps:${C.reset}
  1. ${C.bold}npm install --save-dev husky lint-staged prettier${C.reset}
  2. ${C.bold}git init && git add -A && git commit -m "init shipkit"${C.reset}
  3. ${C.bold}git push origin main${C.reset}
  4. Open in your AI agent and say:  ${C.green}"plan: <feature>"${C.reset}
  5. Before pushing, say:            ${C.yellow}"review security"${C.reset}
  6. At session start, say:          ${C.cyan}"check errors"${C.reset}

${C.bold}Your AI agent now knows your stack, your pipeline, and your rules.${C.reset}
${C.dim}ShipKit — Because your MVP deserves a production pipeline.${C.reset}
`);
}

// ─── CLI Entry Point ────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);

  if (args.includes('--version') || args.includes('-v')) {
    console.log(pkg.version);
    process.exit(0);
  }

  if (args.includes('--help') || args.includes('-h') || args.length === 0) {
    console.log(`
${C.bold}${C.cyan}ShipKit${C.reset} — MVP to Production Pipeline v${pkg.version}

${C.bold}Usage:${C.reset}
  ${C.green}npx shipkit-pipe setup${C.reset}        Interactive setup wizard
  ${C.green}npx shipkit-pipe setup --defaults${C.reset}  Auto-detect and generate (CI)
  ${C.green}npx shipkit-pipe --help${C.reset}           Show this help
  ${C.green}npx shipkit-pipe --version${C.reset}        Show version

${C.bold}What it does:${C.reset}
  Configures your project with:
  • CI/CD pipeline (GitHub Actions: lint → test → build → deploy)
  • AI agent protocol (works with Claude, Cursor, Copilot, any agent)
  • Security scanning (CodeQL + Dependabot)
  • Pre-commit hooks (Husky + lint-staged)
  • Session continuity for your AI agent

${C.bold}Works with:${C.reset}
  Any frontend, any backend, any database, any deploy platform,
  any AI coding agent, any IDE.

${C.dim}https://github.com/sagar-grv/shipkit${C.reset}
`);
    process.exit(0);
  }

  if (args[0] === 'setup') {
    await setup();
    process.exit(0);
  }

  console.log(`${C.red}Unknown command: ${args[0]}${C.reset}`);
  console.log(`Run ${C.green}npx shipkit-pipe --help${C.reset} for usage.`);
  process.exit(1);
}

main().catch((err) => {
  console.error(`${C.red}Error:${C.reset} ${err.message}`);
  process.exit(1);
});
