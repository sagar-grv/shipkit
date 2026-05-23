<#
.SYNOPSIS
  ShipKit Setup — connects your tools and generates your production pipeline

.DESCRIPTION
  ShipKit is an open-source orchestration layer that configures your AI agent,
  CI/CD, security scanning, pre-commit hooks, and session management — all from
  a single setup command.

  Works with ANY stack, ANY AI agent (Claude Code, Cursor, Copilot, OpenCode, etc.),
  ANY IDE, and ANY deploy platform.

.PARAMETER ConfigFile
  Path to a JSON config file for headless setup.
  Example: .\setup.ps1 -ConfigFile project-config.json

.PARAMETER OutputDir
  Directory to output generated files. Defaults to current directory.

.PARAMETER Force
  Overwrite existing files without asking.

.EXAMPLE
  .\setup.ps1
  Interactive mode — answers ~5 questions about your tools

.EXAMPLE
  .\setup.ps1 -ConfigFile project-config.json -Force
  Headless mode from config file

.EXAMPLE
  .\setup.ps1 -DetectOnly
  Auto-detect project config and print it without writing files
#>

param(
  [string]$ConfigFile = "",
  [string]$OutputDir = ".",
  [switch]$Force,
  [switch]$DetectOnly
)

# ---------------------------------------------------------------
# Colors & Helpers
# ---------------------------------------------------------------

$C = @{
  Green  = "`e[32m"
  Yellow = "`e[33m"
  Cyan   = "`e[36m"
  Red    = "`e[31m"
  Reset  = "`e[0m"
  Bold   = "`e[1m"
}

function Write-Title($Text) {
  Write-Host "`n${C.Bold}${C.Cyan}===== $Text =====${C.Reset}`n"
}

function Write-Step($Text) {
  Write-Host "${C.Green}[*]${C.Reset} $Text"
}

function Write-Info($Text) {
  Write-Host "  ${C.Yellow}${Text}${C.Reset}"
}

function Read-Value($Prompt, $Default) {
  $defaultStr = ""
  if ($Default) { $defaultStr = " [$Default]" }
  $val = Read-Host "${Prompt}${defaultStr}"
  if ([string]::IsNullOrWhiteSpace($val)) { return $Default }
  return $val
}

function Read-Choice($Prompt, $Options, $Default) {
  Write-Host "${C.Yellow}$Prompt${C.Reset}"
  for ($i = 0; $i -lt $Options.Count; $i++) {
    $mark = if ($Options[$i] -eq $Default) { " ${C.Green}(default)${C.Reset}" } else { "" }
    Write-Host "  [$($i+1)] $($Options[i])$mark"
  }
  $val = Read-Host "Enter number (1-$($Options.Count))"
  if ([string]::IsNullOrWhiteSpace($val)) { return $Default }
  $num = 0
  if ([int]::TryParse($val, [ref]$num) -and $num -ge 1 -and $num -le $Options.Count) {
    return $Options[$num - 1]
  }
  return $Default
}

function Confirm-YN($Prompt, $Default) {
  $defaultStr = if ($Default -eq $true) { "Y/n" } else { "y/N" }
  $val = Read-Host "${Prompt} ($defaultStr)"
  if ([string]::IsNullOrWhiteSpace($val)) { return $Default }
  return $val.ToLower().StartsWith("y")
}

# ---------------------------------------------------------------
# Template Engine
# ---------------------------------------------------------------

function Render-Template {
  param(
    [string]$Content,
    [hashtable]$Vars
  )

  $result = $Content

  # Replace all {{VAR}} placeholders
  foreach ($key in $Vars.Keys) {
    $val = if ($null -ne $Vars[$key]) { $Vars[$key].ToString() } else { "" }
    $result = $result -replace [regex]::Escape("{{${key}}}"), $val
  }

  # Handle {% if VAR %}...{% endif %} blocks
  $regex = [regex]'\{\%\s*if\s+(\w+)\s*\%\}(.*?)\{\%\s*endif\s*\%\}'
  $result = $regex.Replace($result, {
    param($match)
    $varName = $match.Groups[1].Value
    $innerContent = $match.Groups[2].Value
    $varValue = $Vars[$varName]
    $isTruthy = $varValue -and $varValue -ne "false" -and $varValue -ne "0" -and $varValue -ne ""
    if ($isTruthy) { return $innerContent } else { return "" }
  }.GetNewClosure())

  return $result
}

# ---------------------------------------------------------------
# Auto-Detect Project Info
# ---------------------------------------------------------------

function Auto-Detect {
  $detected = @{
    frontend = ""
    packageManager = "npm"
    nodeVersion = "20"
    buildCommand = ""
    testCommand = ""
    lintCommand = ""
    hasDocker = $false
    hasGit = $false
  }

  # Check for package.json
  $pkgPath = Join-Path $OutputDir "package.json"
  if (Test-Path $pkgPath) {
    try {
      $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
      $detected.projectName = $pkg.name
      $detected.projectDesc = $pkg.description

      # Detect framework from dependencies
      $deps = @{}
      if ($pkg.dependencies) { $pkg.dependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
      if ($pkg.devDependencies) { $pkg.devDependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }

      if ($deps.ContainsKey("next")) { $detected.frontend = "Next.js" }
      elseif ($deps.ContainsKey("react") -or $deps.ContainsKey("react-dom")) { $detected.frontend = "React + Vite" }
      elseif ($deps.ContainsKey("vue")) { $detected.frontend = "Vue" }
      elseif ($deps.ContainsKey("svelte")) { $detected.frontend = "Svelte" }
      elseif ($deps.ContainsKey("@remix-run/react")) { $detected.frontend = "Remix" }

      # Detect tests
      if ($deps.ContainsKey("playwright")) { $detected.e2e = "Playwright" }
      elseif ($deps.ContainsKey("cypress")) { $detected.e2e = "Cypress" }

      # Detect lint tools
      if ($deps.ContainsKey("eslint")) { $detected.lintCommand = "npm run lint" }

      # Detect build/test scripts
      if ($pkg.scripts) {
        $scripts = $pkg.scripts
        if ($scripts.build) { $detected.buildCommand = "npm run build" }
        else { $detected.buildCommand = "npm run build" }
        if ($scripts.test) { $detected.testCommand = "npm test" }

        # Detect package manager
        if (Get-Command pnpm -ErrorAction SilentlyContinue) { $detected.packageManager = "pnpm" }
        elseif (Get-Command yarn -ErrorAction SilentlyContinue) { $detected.packageManager = "yarn" }

        # Detect node version from engines or .nvmrc
        if ($pkg.engines -and $pkg.engines.node) {
          $detected.nodeVersion = ($pkg.engines.node -replace '[^0-9.]', '')
        }
      }
    } catch {
      Write-Info "Could not read package.json"
    }
  }

  # Check for Docker
  if (Test-Path (Join-Path $OutputDir "Dockerfile") -or (Test-Path (Join-Path $OutputDir "docker-compose.yml"))) {
    $detected.hasDocker = $true
  }

  # Check for Git
  if (Test-Path (Join-Path $OutputDir ".git")) {
    $detected.hasGit = $true
    try {
      $remote = git config --get remote.origin.url 2>$null
      if ($remote) {
        $detected.gitRemote = $remote
      }
    } catch {}
  }

  # Check for existing config files
  $detected.hasSupabase = Test-Path (Join-Path $OutputDir "supabase") -or (Test-Path (Join-Path $OutputDir "supabase.json"))
  $detected.hasFirebase = Test-Path (Join-Path $OutputDir "firebase.json")
  $detected.hasVercel = Test-Path (Join-Path $OutputDir "vercel.json") -or (Test-Path (Join-Path $OutputDir ".vercel"))
  $detected.hasNetlify = Test-Path (Join-Path $OutputDir "netlify.toml")
  $detected.hasSentry = (Test-Path (Join-Path $OutputDir ".sentryclirc")) -or (Test-Path (Join-Path $OutputDir "sentry.client.config.ts")) -or (Test-Path (Join-Path $OutputDir "sentry.client.config.js"))
  $detected.hasHusky = Test-Path (Join-Path $OutputDir ".husky")

  return $detected
}

# ---------------------------------------------------------------
# Load Config from File or Interactive
# ---------------------------------------------------------------

$config = @{}

if ($ConfigFile -and (Test-Path $ConfigFile)) {
  Write-Step "Loading config from $ConfigFile"
  $raw = Get-Content $ConfigFile -Raw
  if ($raw) {
    $config = $raw | ConvertFrom-Json -AsHashtable
  }
  Write-Step "Config loaded."
}

# Auto-detect project
$detected = Auto-Detect

if ($DetectOnly) {
  Write-Host "${C.Cyan}Detected project config:${C.Reset}"
  $detected | ConvertTo-Json | Write-Host
  return $detected
}

# ---------------------------------------------------------------
# Welcome
# ---------------------------------------------------------------

Write-Host @"
${C.Bold}${C.Cyan}
 ⚓ ShipKit — MVP to Production Pipeline
   Connect your tools. Ship to production. No team required.

   This script will:
   • Detect your project's tech stack
   • Configure CI/CD (lint → test → build → deploy)
   • Set up security scanning (CodeQL + Dependabot)
   • Generate AI agent prompts (works with Claude Code, Cursor, Copilot, any agent)
   • Create pre-commit hooks
   • Set up session continuity for your AI agent

   Takes ~2 minutes. Works with any stack, any AI agent.
${C.Reset}
"@

if (-not $ConfigFile) {
  Write-Host "${C.Yellow}Press Enter for defaults (auto-detected values shown).${C.Reset}"
  Write-Info "Detected: $($detected.frontend) | $($detected.packageManager) | Node $($detected.nodeVersion)"
}

# ---------------------------------------------------------------
# 1. Project Info
# ---------------------------------------------------------------

Write-Title "PROJECT"

$projName = if ($config.ContainsKey("project") -and $config.project.ContainsKey("name")) {
  $config.project.name
} else {
  Read-Value "Project name" $detected.projectName
}

$projDesc = if ($config.ContainsKey("project") -and $config.project.ContainsKey("description")) {
  $config.project.description
} else {
  Read-Value "Project description" $detected.projectDesc
}

# ---------------------------------------------------------------
# 2. AI Agent Selection
# ---------------------------------------------------------------

Write-Title "AI AGENT"

$aiAgentOptions = @("Claude Code (Anthropic)", "Cursor", "GitHub Copilot", "OpenCode", "CodeGPT", "Continue.dev", "Cline", "Aider", "Other / Custom")
$selectedAgent = if ($config.ContainsKey("aiAgent")) {
  $config.aiAgent
} else {
  Read-Choice "Which AI agent do you use?" $aiAgentOptions "Claude Code (Anthropic)"
}

# Map AI agent to config file paths
$agentFiles = @{}
switch -Wildcard ($selectedAgent) {
  "Claude Code*"   { $agentFiles = @{ agent = "claude-code"; configFiles = @("CLAUDE.md") } }
  "Cursor*"        { $agentFiles = @{ agent = "cursor"; configFiles = @(".cursorrules") } }
  "GitHub Copilot*" { $agentFiles = @{ agent = "copilot"; configFiles = @(".github/copilot-instructions.md") } }
  "OpenCode*"      { $agentFiles = @{ agent = "opencode"; configFiles = @(".opencode/agents/co-developer.md") } }
  default          { $agentFiles = @{ agent = "custom"; configFiles = @("AGENTS.md") } }
}

# ---------------------------------------------------------------
# 3. GitHub Auth
# ---------------------------------------------------------------

Write-Title "GITHUB"

$ghOwner = ""
$ghRepo = ""
$ghToken = ""

if ($config.ContainsKey("github") -and $config.github.ContainsKey("owner")) {
  $ghOwner = $config.github.owner
  $ghRepo = $config.github.repo
} else {
  # Try gh CLI
  $ghCli = Get-Command gh -ErrorAction SilentlyContinue
  if ($ghCli -and (Confirm-YN "GitHub CLI detected. Auto-configure from current repo?" $true)) {
    try {
      $ghOwner = gh repo view --json owner --jq .owner.login 2>$null
      $ghRepo = gh repo view --json name --jq .name 2>$null
      Write-Step "Detected: $ghOwner / $ghRepo"
    } catch {
      Write-Info "Could not auto-detect GitHub repo"
    }
  }

  if (-not $ghOwner) {
    $ghOwner = Read-Value "GitHub username/organization" ($detected.gitRemote -replace '.*[:/]([^/]+)/.*', '$1')
    $ghRepo = Read-Value "GitHub repository name" ($projName -replace '[^a-zA-Z0-9\-]', '').ToLower()
  }

  if ($ghCli -and (Confirm-YN "Authenticate ShipKit with GitHub? (enables CI/CD status checks)" $true)) {
    try {
      $ghToken = gh auth token 2>$null
      if ($ghToken) {
        Write-Step "GitHub authenticated."
      }
    } catch {
      Write-Info "GitHub CLI not authenticated. Run 'gh auth login' later."
    }
  }
}

# ---------------------------------------------------------------
# 4. Deploy Platform
# ---------------------------------------------------------------

Write-Title "DEPLOY PLATFORM"

$deployOptions = @("Vercel", "Netlify", "Fly.io", "Railway", "Render", "Cloudflare Pages", "Docker / Self-hosted", "AWS", "GCP", "None yet")
$deployPlatform = if ($config.ContainsKey("deploy") -and $config.deploy.ContainsKey("platform")) {
  $config.deploy.platform
} elseif ($detected.hasVercel) {
  "Vercel"
} elseif ($detected.hasNetlify) {
  "Netlify"
} else {
  Read-Choice "Where do you deploy?" $deployOptions "Vercel"
}

$deployToken = ""
$deployProjectId = ""
if ($deployPlatform -ne "None yet") {
  if ($deployPlatform -eq "Vercel" -and (Get-Command vercel -ErrorAction SilentlyContinue) -and (Confirm-YN "Authenticate with Vercel?" $true)) {
    try {
      $deployToken = vercel token 2>$null
      $deployProjectId = vercel project --json 2>$null | ConvertFrom-Json | Select-Object -ExpandProperty id -ErrorAction SilentlyContinue
      if ($deployProjectId) { Write-Step "Vercel project detected." }
    } catch {
      Write-Info "Could not auto-detect Vercel config"
    }
  }
}

# ---------------------------------------------------------------
# 5. Database
# ---------------------------------------------------------------

Write-Title "DATABASE"

$dbOptions = @("Supabase Postgres", "Firebase Firestore", "MongoDB", "PostgreSQL (direct)", "MySQL", "SQLite", "None yet")
$dbChoice = if ($config.ContainsKey("database") -and $config.database.ContainsKey("type")) {
  $config.database.type
} elseif ($detected.hasSupabase) {
  "Supabase Postgres"
} elseif ($detected.hasFirebase) {
  "Firebase Firestore"
} else {
  Read-Choice "Which database do you use?" $dbOptions "Supabase Postgres"
}

$dbToken = ""
if ($dbChoice -like "Supabase*" -and (Get-Command supabase -ErrorAction SilentlyContinue) -and (Confirm-YN "Authenticate with Supabase?" $true)) {
  try {
    $dbToken = supabase auth token 2>$null
    Write-Step "Supabase authenticated."
  } catch {}
}

# ---------------------------------------------------------------
# 6. Error Tracking (Optional)
# ---------------------------------------------------------------

$monitoringOptions = @("Sentry", "Datadog", "LogRocket", "PostHog", "None")
$monitoringChoice = if ($config.ContainsKey("monitoring") -and $config.monitoring.ContainsKey("platform")) {
  $config.monitoring.platform
} elseif ($detected.hasSentry) {
  "Sentry"
} else {
  Read-Choice "Error tracking / monitoring?" $monitoringOptions "None"
}

# ---------------------------------------------------------------
# Map DB to storage
# ---------------------------------------------------------------

$storageChoice = if ($dbChoice -like "Supabase*") { "Supabase Storage" }
elseif ($dbChoice -like "Firebase*") { "Firebase Storage" }
else { "Cloud storage (S3, etc.)" }

# ---------------------------------------------------------------
# Build Variables
# ---------------------------------------------------------------

$Vars = @{
  PROJECT_NAME = $projName
  PROJECT_DESCRIPTION = $projDesc
  DATE = (Get-Date -Format "yyyy-MM-dd")

  STACK_FRONTEND = if ($detected.frontend) { $detected.frontend } else { "Web application" }
  STACK_DATABASE = $dbChoice
  STACK_AUTH = $dbChoice  # default: same as DB auth provider
  STACK_AI = "AI-powered features"
  STACK_DEPLOY = $deployPlatform
  STACK_STORAGE = $storageChoice
  STACK_E2E = if ($detected.e2e) { $detected.e2e } else { "Playwright" }
  STACK_ANALYTICS = $monitoringChoice

  NODE_VERSION = $detected.nodeVersion
  BUILD_COMMAND = $detected.buildCommand
  TEST_COMMAND = $detected.testCommand
  LINT_COMMAND = $detected.lintCommand
  TYPECHECK_COMMAND = "npx tsc --noEmit"
  PACKAGE_MANAGER = $detected.packageManager
  COVERAGE_ENABLED = "true"

  DATABASE_TYPE = $dbChoice
  DATABASE_PROJECT_ID = ""
  DATABASE_REGION = ""
  RLS_ENABLED = if ($dbChoice -like "Supabase*") { "true" } else { "false" }

  GITHUB_OWNER = $ghOwner
  GITHUB_REPO = $ghRepo

  DEPLOY_PLATFORM = $deployPlatform
  DEPLOY_PROJECT_ID = $deployProjectId
  PREVIEW_URLS_ENABLED = if ($deployPlatform -eq "Vercel") { "true" } else { "false" }

  MONITORING_PLATFORM = $monitoringChoice
  MONITORING_ORG = ""
  MONITORING_PROJECT = ""

  BUILD_ENV_VARS = @()

  AI_AGENT = $selectedAgent
  AGENT_CONFIG_FILES = $agentFiles.configFiles -join ", "
}

# ---------------------------------------------------------------
# Generate Files
# ---------------------------------------------------------------

Write-Title "GENERATING PIPELINE FILES"

$TemplateDir = Join-Path $PSScriptRoot "template"
$ProjectRoot = Resolve-Path $OutputDir

$Files = @(
  @{ src = "github/dependabot.yml";            dst = ".github/dependabot.yml" }
  @{ src = "github/workflows/ci.yml";          dst = ".github/workflows/ci.yml" }
  @{ src = "github/workflows/codeql.yml";      dst = ".github/workflows/codeql.yml" }
  @{ src = "github/workflows/playwright.yml";  dst = ".github/workflows/playwright.yml" }
  @{ src = "agents/co-developer.md";           dst = "shipkit/co-developer.md" }
  @{ src = "agents/planner.md";                dst = "shipkit/planner.md" }
  @{ src = "agents/security-reviewer.md";      dst = "shipkit/security-reviewer.md" }
  @{ src = "agents/monitor.md";                dst = "shipkit/monitor.md" }
  @{ src = "husky/pre-commit";                 dst = ".husky/pre-commit" }
  @{ src = "docs/AGENTS.md";                   dst = "AGENTS.md" }
  @{ src = "docs/ROADMAP.md";                  dst = "ROADMAP.md" }
  @{ src = "docs/BUGS.md";                     dst = "BUGS.md" }
  @{ src = "docs/LAST_SESSION.md";             dst = "LAST_SESSION.md" }
)

# Also generate AI-agent-specific config file
$agentConfigDst = ""
switch -Wildcard ($selectedAgent) {
  "Claude Code*"   { $agentConfigDst = "CLAUDE.md" }
  "Cursor*"        { $agentConfigDst = ".cursorrules" }
  "GitHub Copilot*" { $agentConfigDst = ".github/copilot-instructions.md" }
  "OpenCode*"      { $agentConfigDst = ".opencode/agents/co-developer.md" }
}

$generatedCount = 0
$skippedCount = 0

foreach ($file in $Files) {
  $srcPath = Join-Path $TemplateDir $file.src
  $dstPath = Join-Path $ProjectRoot $file.dst

  # Check if destination already exists
  if ((Test-Path $dstPath) -and -not $Force) {
    Write-Info "SKIP: $($file.dst) (already exists, use -Force to overwrite)"
    $skippedCount++
    continue
  }

  # Ensure destination directory exists
  $dstDir = Split-Path $dstPath -Parent
  if (-not (Test-Path $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
  }

  # Read template, render, write
  $template = Get-Content $srcPath -Raw
  $rendered = Render-Template -Content $template -Vars $Vars
  if ($rendered) {
    $rendered | Set-Content $dstPath -NoNewline
    Write-Step "Created $($file.dst)"
    $generatedCount++
  } else {
    Write-Info "ERROR: Failed to render $($file.src)"
  }
}

# Generate AI-agent-specific config file (copies AGENTS.md or references it)
if ($agentConfigDst) {
  $agentDstPath = Join-Path $ProjectRoot $agentConfigDst
  $agentDir = Split-Path $agentDstPath -Parent
  if (-not (Test-Path $agentDir)) {
    New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
  }

  if (-not (Test-Path $agentDstPath) -or $Force) {
    # Write a reference file that points to AGENTS.md
    $agentRef = @"
# {{PROJECT_NAME}} — AI Agent Configuration

This file configures your AI agent ($selectedAgent) for **{{PROJECT_NAME}}**.

→ Read `AGENTS.md` for the full protocol and rules
→ Read `shipkit.json` for project config and tech stack
→ Read `ROADMAP.md` for what's planned
→ Read `BUGS.md` for what's broken
→ Read `LAST_SESSION.md` for session continuity

## Quick Start
- Say "plan: <feature>" to start the planning process
- Say "review security" before pushing changes
- Say "check errors" at session start
"@
    $renderedAgentRef = Render-Template -Content $agentRef -Vars $Vars
    $renderedAgentRef | Set-Content $agentDstPath -NoNewline
    Write-Step "Created $agentConfigDst (AI agent config)"
    $generatedCount++
  } else {
    Write-Info "SKIP: $agentConfigDst (already exists)"
    $skippedCount++
  }
}

# ---------------------------------------------------------------
# Generate shipkit.json
# ---------------------------------------------------------------

$shipkitJson = @"
{
  "project": {
    "name": "$projName",
    "description": "$projDesc"
  },
  "stack": {
    "frontend": "$($Vars.STACK_FRONTEND)",
    "database": "$($Vars.STACK_DATABASE)",
    "auth": "$($Vars.STACK_AUTH)",
    "deploy": "$($Vars.STACK_DEPLOY)",
    "storage": "$($Vars.STACK_STORAGE)",
    "e2e": "$($Vars.STACK_E2E)",
    "monitoring": "$($Vars.STACK_ANALYTICS)"
  },
  "ci": {
    "nodeVersion": "$($Vars.NODE_VERSION)",
    "buildCommand": "$($Vars.BUILD_COMMAND)",
    "testCommand": "$($Vars.TEST_COMMAND)",
    "lintCommand": "$($Vars.LINT_COMMAND)",
    "typecheckCommand": "$($Vars.TYPECHECK_COMMAND)",
    "packageManager": "$($Vars.PACKAGE_MANAGER)"
  },
  "aiAgent": {
    "tool": "$selectedAgent",
    "configFiles": "$($Vars.AGENT_CONFIG_FILES)"
  },
  "github": {
    "owner": "$($Vars.GITHUB_OWNER)",
    "repo": "$($Vars.GITHUB_REPO)"
  },
  "deploy": {
    "platform": "$($Vars.DEPLOY_PLATFORM)",
    "projectId": "$($Vars.DEPLOY_PROJECT_ID)",
    "previewUrls": $($Vars.PREVIEW_URLS_ENABLED.ToString().ToLower())
  },
  "database": {
    "type": "$($Vars.DATABASE_TYPE)",
    "rlsEnabled": $($Vars.RLS_ENABLED.ToString().ToLower())
  },
  "monitoring": {
    "platform": "$($Vars.MONITORING_PLATFORM)"
  },
  "version": "2.0.0"
}
"@

$shipkitJsonPath = Join-Path $ProjectRoot "shipkit.json"
$shipkitJson | Set-Content $shipkitJsonPath
Write-Step "Created shipkit.json"
$generatedCount++

# ---------------------------------------------------------------
# Husky Setup
# ---------------------------------------------------------------

Write-Title "SETTING UP PRE-COMMIT HOOKS"

if (Get-Command npx -ErrorAction SilentlyContinue) {
  $huskyDir = Join-Path $ProjectRoot ".husky"
  if (-not (Test-Path $huskyDir)) {
    Write-Step "Initializing Husky..."
    Push-Location $ProjectRoot
    npx husky init 2>$null
    Pop-Location
  }

  $hookPath = Join-Path $ProjectRoot ".husky/pre-commit"
  if (Test-Path $hookPath) {
    if ($IsLinux -or $IsMacOS) {
      chmod +x $hookPath 2>$null
    }
    $hookContent = Get-Content $hookPath -Raw
    if ($hookContent -notmatch "lint-staged") {
      Set-Content $hookPath ". `"`$(dirname -- `"`$0`")/_/husky.sh`n`nnpx lint-staged`n"
    }
  }

  Write-Step "Pre-commit hooks configured."
} else {
  Write-Info "Node.js not found. Run 'npx husky init' manually after installing dependencies."
}

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------

Write-Title "SETUP COMPLETE — $projName is ShipKit ready"

Write-Host @"
${C.Green}[DONE]${C.Reset} Generated $generatedCount files

${C.Cyan}ShipKit Files:${C.Reset}
  shipkit.json          ← Config for your AI agent (reads this at startup)
  AGENTS.md             ← Universal AI agent protocol
  ROADMAP.md            ← Feature tracker
  BUGS.md               ← Bug tracker
  LAST_SESSION.md       ← Session continuity
  shipkit/              ← AI agent prompts
  │-- planner.md        PM + Eng Lead
  │-- co-developer.md   Builder (default agent)
  │-- security-reviewer.md  Security Engineer
  |-- monitor.md        SRE + Incident Commander
  .github/              ← CI/CD + Security + Dependencies
  .husky/pre-commit     ← Pre-commit hooks

$(if ($agentConfigDst) { "  $agentConfigDst    ← $selectedAgent config file" } else { "" })

${C.Yellow}Next Steps:${C.Reset}
  1. Install deps:     ${C.Cyan}npm install --save-dev husky lint-staged prettier${C.Reset}
  2. Init Husky:       ${C.Cyan}npx husky init${C.Reset}
  3. Push to GitHub:   ${C.Cyan}git push origin main${C.Reset}
  4. Open in your AI agent and say "${C.Cyan}plan: <feature>${C.Reset}"
  5. Before pushing: say "${C.Cyan}review security${C.Reset}"
  6. At session start: say "${C.Cyan}check errors${C.Reset}"

${C.Cyan}Your AI Agent will automatically:${C.Reset}
  • Read shipkit.json to learn your tech stack
  • Follow AGENTS.md for the development protocol
  • Plan features with planner.md
  • Review security before each push
  • Monitor production health every session

${C.Bold}One team. Zero overhead. Production apps.${C.Reset}
"@

if ($skippedCount -gt 0) {
  Write-Host @"
${C.Yellow}[WARN]${C.Reset} $skippedCount files were skipped (already exist). Use -Force to overwrite.
"@
}

return $Vars
