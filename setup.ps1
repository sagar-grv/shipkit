<#
.SYNOPSIS
  Solo Dev Pipeline Setup - turns this template into YOUR project's CI/CD + AI Agent system

.DESCRIPTION
  Interactive setup script that generates all pipeline files for a solo development project:
    - GitHub Actions CI/CD (lint, typecheck, test, build)
    - CodeQL security scanning
    - Playwright E2E tests on preview deployments
    - OpenCode AI agents (planner, security reviewer, monitor)
    - Pre-commit hooks (Husky + lint-staged)
    - Project docs (AGENTS.md, ROADMAP.md, BUGS.md, LAST_SESSION.md)
    - pipeline.json (source of truth for agents and tooling)

.PARAMETER ConfigFile
  Path to a JSON config file to use instead of interactive prompts.
  Example: .\setup.ps1 -ConfigFile my-project-config.json

.PARAMETER OutputDir
  Directory to output generated files. Defaults to current directory.

.PARAMETER Force
  Overwrite existing files without asking.

.EXAMPLE
  .\setup.ps1
  # Interactive mode - answers all questions

.EXAMPLE
  .\setup.ps1 -ConfigFile project.json -Force
  # Headless mode from config file, overwrite existing files
#>

param(
  [string]$ConfigFile = "",
  [string]$OutputDir = ".",
  [switch]$Force
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
    Write-Host "  [$($i+1)] $($Options[$i])$mark"
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

  # Handle {% for var in vars %}...{% endfor %} blocks (simple array iteration)
  $forRegex = [regex]'\{\%\s*for\s+(\w+)\s+in\s+(\w+)\s*\%\}(.*?)\{\%\s*endfor\s*\%\}'
  $result = $forRegex.Replace($result, {
    param($match)
    $itemVar = $match.Groups[1].Value
    $listVar = $match.Groups[2].Value
    $template = $match.Groups[3].Value
    $list = $Vars[$listVar]

    if (-not $list -or $list.Count -eq 0) { return "" }

    $output = ""
    foreach ($item in $list) {
      $itemResult = $template
      if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
        foreach ($prop in $item.PSObject.Properties) {
          $itemResult = $itemResult -replace [regex]::Escape("{{${itemVar}.$($prop.Name)}}"), ($prop.Value.ToString())
        }
      } else {
        $itemResult = $itemResult -replace [regex]::Escape("{{${itemVar}}}"), ($item.ToString())
      }
      $output += $itemResult
    }
    return $output
  }.GetNewClosure())

  return $result
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

# ---------------------------------------------------------------
# Welcome
# ---------------------------------------------------------------

Write-Host @"
${C.Bold}${C.Cyan}
╔══════════════════════════════════════════╗
║          ShipKit Setup - v1.0           ║
║  Replace a 6-person team with AI agents ║
╚══════════════════════════════════════════╝

  This script generates a complete production pipeline:
    - GitHub Actions CI/CD (lint, typecheck, test, build)
    - CodeQL security scanning
    - Playwright E2E tests
    - OpenCode AI agents (planner, security, monitor)
    - Husky pre-commit hooks
    - Project management docs
${C.Reset}
"@

if (-not $ConfigFile) {
  Write-Host "${C.Yellow}Press Enter for defaults, type your values to customize.${C.Reset}"
}

# ---------------------------------------------------------------
# 1. Project Info
# ---------------------------------------------------------------

Write-Title "PROJECT INFORMATION"

$projName = if ($config.ContainsKey("project") -and $config.project.ContainsKey("name")) {
  $config.project.name
} else {
  Read-Value "Project name" "MyApp"
}

$projDesc = if ($config.ContainsKey("project") -and $config.project.ContainsKey("description")) {
  $config.project.description
} else {
  Read-Value "Project description" "A web application"
}

# ---------------------------------------------------------------
# 2. Tech Stack
# ---------------------------------------------------------------

Write-Title "TECH STACK"

$stackFrontend = if ($config.ContainsKey("stack") -and $config.stack.ContainsKey("frontend")) {
  $config.stack.frontend
} else {
  Read-Choice "Frontend framework" @("Next.js 15+", "React + Vite", "Nuxt.js", "SvelteKit", "Remix", "Other") "Next.js 15+"
}

$stackDatabase = if ($config.ContainsKey("stack") -and $config.stack.ContainsKey("database")) {
  $config.stack.database
} else {
  Read-Choice "Database" @("Supabase Postgres", "Firebase Firestore", "MongoDB", "PostgreSQL (direct)", "None / SQLite", "Other") "Supabase Postgres"
}

$stackAuth = if ($config.ContainsKey("stack") -and $config.stack.ContainsKey("auth")) {
  $config.stack.auth
} else {
  Read-Choice "Authentication" @("Supabase Auth", "Firebase Auth", "Clerk", "Auth0", "NextAuth.js", "Custom / None") "Supabase Auth"
}

$hasAi = Confirm-YN "Does your app use AI/LLM features?" $false
$stackAi = ""
if ($hasAi) {
  $stackAi = if ($config.ContainsKey("stack") -and $config.stack.ContainsKey("ai")) {
    $config.stack.ai
  } else {
    Read-Choice "AI provider" @("Gemini API", "OpenAI API", "Anthropic Claude", "Hugging Face", "Custom / Local") "Gemini API"
  }
}

$stackDeploy = if ($config.ContainsKey("stack") -and $config.stack.ContainsKey("deploy")) {
  $config.stack.deploy
} else {
  Read-Choice "Deploy platform" @("Vercel", "Netlify", "Fly.io", "Railway", "Cloudflare Pages", "Self-hosted") "Vercel"
}

$stackE2e = if ($config.ContainsKey("stack") -and $config.stack.ContainsKey("e2e")) {
  $config.stack.e2e
} else {
  Read-Choice "E2E test framework" @("Playwright", "Cypress", "None") "Playwright"
}

$hasAnalytics = Confirm-YN "Set up error tracking / analytics?" $true
$stackAnalytics = ""
if ($hasAnalytics) {
  $stackAnalytics = if ($config.ContainsKey("stack") -and $config.stack.ContainsKey("analytics")) {
    $config.stack.analytics
  } else {
    Read-Choice "Error tracking" @("Sentry", "LogRocket", "Datadog", "PostHog", "Custom") "Sentry"
  }
}

# Map database to storage
$stackStorage = if ($config.ContainsKey("stack") -and $config.stack.ContainsKey("storage")) {
  $config.stack.storage
} elseif ($stackDatabase -like "Supabase*") {
  "Supabase Storage"
} elseif ($stackDatabase -like "Firebase*") {
  "Firebase Storage"
} else {
  "Cloud storage (S3, etc.)"
}

# ---------------------------------------------------------------
# 3. CI/CD Config
# ---------------------------------------------------------------

Write-Title "CI/CD CONFIGURATION"

$nodeVersion = if ($config.ContainsKey("ci") -and $config.ci.ContainsKey("nodeVersion")) {
  $config.ci.nodeVersion
} else {
  Read-Value "Node.js version" "20"
}

$pkgManager = if ($config.ContainsKey("ci") -and $config.ci.ContainsKey("packageManager")) {
  $config.ci.packageManager
} else {
  Read-Choice "Package manager" @("npm", "pnpm", "yarn") "npm"
}

$buildCmd = if ($config.ContainsKey("ci") -and $config.ci.ContainsKey("buildCommand")) {
  $config.ci.buildCommand
} else {
  Read-Value "Build command" "$pkgManager run build"
}

$testCmd = if ($config.ContainsKey("ci") -and $config.ci.ContainsKey("testCommand")) {
  $config.ci.testCommand
} else {
  Read-Value "Test command" "$pkgManager test"
}

$lintCmd = "$pkgManager run lint"
$typecheckCmd = "npx tsc --noEmit"

$hasCoverage = Confirm-YN "Upload test coverage reports?" $true

# ---------------------------------------------------------------
# 4. Database Config
# ---------------------------------------------------------------

$dbType = ""
$dbProjectId = ""
$dbRegion = ""
$rlsEnabled = $false

if ($stackDatabase -like "Supabase*") {
  Write-Title "SUPABASE CONFIGURATION"
  $dbType = "supabase"
  $dbProjectId = Read-Value "Supabase project ID (from dashboard)" ""
  $dbRegion = Read-Value "Supabase region" "ap-south-1"
  $rlsEnabled = Confirm-YN "Enable Row Level Security (RLS)?" $true
} elseif ($stackDatabase -like "Firebase*") {
  $dbType = "firebase"
  $dbProjectId = Read-Value "Firebase project ID" ""
  $rlsEnabled = $true
} elseif ($stackDatabase -notlike "None*") {
  if ($stackDatabase -notlike "SQLite*") {
    $dbType = "postgresql"
    Write-Info "PostgreSQL database - remember to set up connection strings in .env"
  }
}

# ---------------------------------------------------------------
# 5. Deploy Config
# ---------------------------------------------------------------

$deployProjectId = ""
$previewUrlsEnabled = $false

if ($stackDeploy -eq "Vercel") {
  Write-Title "VERCEL CONFIGURATION"
  $deployProjectId = Read-Value "Vercel project ID (from Project Settings > General)" ""
  $previewUrlsEnabled = Confirm-YN "Enable E2E tests on preview deployments?" $true
}

# ---------------------------------------------------------------
# 6. Monitoring Config
# ---------------------------------------------------------------

$monitoringOrg = ""
$monitoringProject = ""

if ($stackAnalytics) {
  Write-Title "MONITORING CONFIGURATION"
  $monitoringOrg = Read-Value "$stackAnalytics organization slug" ""
  $monitoringProject = Read-Value "$stackAnalytics project slug" ""
}

# ---------------------------------------------------------------
# 7. GitHub Config
# ---------------------------------------------------------------

Write-Title "GITHUB CONFIGURATION"

$ghOwner = if ($config.ContainsKey("github") -and $config.github.ContainsKey("owner")) {
  $config.github.owner
} else {
  Read-Value "GitHub username/organization" "your-username"
}

$ghRepo = if ($config.ContainsKey("github") -and $config.github.ContainsKey("repo")) {
  $config.github.repo
} else {
  Read-Value "GitHub repository name" ($projName -replace '[^a-zA-Z0-9\-]', '').ToLower()
}

# ---------------------------------------------------------------
# 8. Build Env Vars
# ---------------------------------------------------------------

Write-Title "BUILD ENVIRONMENT VARIABLES"

$buildEnvVars = @()
$addEnvVars = Confirm-YN "Add build-time environment variables? (e.g., NEXT_PUBLIC_SUPABASE_URL)" $true
while ($addEnvVars) {
  $name = Read-Value "  Variable name (e.g., NEXT_PUBLIC_API_URL)" ""
  $secret = Read-Value "  GitHub secret name (e.g., NEXT_PUBLIC_API_URL)" ""
  if ($name -and $secret) {
    $buildEnvVars += @{ name = $name; secret = $secret }
  }
  $addEnvVars = Confirm-YN "  Add another?" $false
}

# ---------------------------------------------------------------
# Build Variables
# ---------------------------------------------------------------

$Vars = @{
  PROJECT_NAME = $projName
  PROJECT_DESCRIPTION = $projDesc
  DATE = (Get-Date -Format "yyyy-MM-dd")

  STACK_FRONTEND = $stackFrontend
  STACK_DATABASE = $stackDatabase
  STACK_AUTH = $stackAuth
  STACK_AI = if ($stackAi) { $stackAi } else { "None" }
  STACK_DEPLOY = $stackDeploy
  STACK_STORAGE = $stackStorage
  STACK_E2E = $stackE2e
  STACK_ANALYTICS = if ($stackAnalytics) { $stackAnalytics } else { "None" }

  NODE_VERSION = $nodeVersion
  BUILD_COMMAND = $buildCmd
  TEST_COMMAND = $testCmd
  LINT_COMMAND = $lintCmd
  TYPECHECK_COMMAND = $typecheckCmd
  PACKAGE_MANAGER = $pkgManager
  COVERAGE_ENABLED = if ($hasCoverage) { "true" } else { "false" }

  DATABASE_TYPE = $dbType
  DATABASE_PROJECT_ID = $dbProjectId
  DATABASE_REGION = $dbRegion
  RLS_ENABLED = if ($rlsEnabled) { "true" } else { "false" }

  GITHUB_OWNER = $ghOwner
  GITHUB_REPO = $ghRepo

  DEPLOY_PLATFORM = $stackDeploy
  DEPLOY_PROJECT_ID = $deployProjectId
  PREVIEW_URLS_ENABLED = if ($previewUrlsEnabled) { "true" } else { "false" }

  MONITORING_PLATFORM = if ($stackAnalytics) { $stackAnalytics } else { "None" }
  MONITORING_ORG = $monitoringOrg
  MONITORING_PROJECT = $monitoringProject

  BUILD_ENV_VARS = $buildEnvVars
}

# ---------------------------------------------------------------
# Generate Files
# ---------------------------------------------------------------

Write-Title "GENERATING PIPELINE FILES"

$TemplateDir = Join-Path $PSScriptRoot "template"
$ProjectRoot = Resolve-Path $OutputDir

# Define all source -> destination mappings
$Files = @(
  @{ src = "github/dependabot.yml";            dst = ".github/dependabot.yml" }
  @{ src = "github/workflows/ci.yml";          dst = ".github/workflows/ci.yml" }
  @{ src = "github/workflows/codeql.yml";      dst = ".github/workflows/codeql.yml" }
  @{ src = "github/workflows/playwright.yml";  dst = ".github/workflows/playwright.yml" }
  @{ src = "agents/co-developer.md";           dst = ".opencode/agents/co-developer.md" }
  @{ src = "agents/planner.md";                dst = ".opencode/agents/planner.md" }
  @{ src = "agents/security-reviewer.md";      dst = ".opencode/agents/security-reviewer.md" }
  @{ src = "agents/monitor.md";                dst = ".opencode/agents/monitor.md" }
  @{ src = "husky/pre-commit";                 dst = ".husky/pre-commit" }
  @{ src = "docs/AGENTS.md";                   dst = "AGENTS.md" }
  @{ src = "docs/ROADMAP.md";                  dst = "ROADMAP.md" }
  @{ src = "docs/BUGS.md";                     dst = "BUGS.md" }
  @{ src = "docs/LAST_SESSION.md";             dst = "LAST_SESSION.md" }
)

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

# ---------------------------------------------------------------
# Generate pipeline.json
# ---------------------------------------------------------------

$pipelineJson = @"
{
  "project": {
    "name": "$projName",
    "description": "$projDesc"
  },
  "stack": {
    "frontend": "$stackFrontend",
    "database": "$stackDatabase",
    "auth": "$stackAuth",
    "ai": "$stackAi",
    "deploy": "$stackDeploy",
    "storage": "$stackStorage",
    "e2e": "$stackE2e",
    "analytics": "$stackAnalytics"
  },
  "ci": {
    "nodeVersion": "$nodeVersion",
    "buildCommand": "$buildCmd",
    "testCommand": "$testCmd",
    "lintCommand": "$lintCmd",
    "typecheckCommand": "$typecheckCmd",
    "packageManager": "$pkgManager"
  },
  "database": {
    "type": "$dbType",
    "projectId": "$dbProjectId",
    "region": "$dbRegion",
    "rlsEnabled": $($rlsEnabled.ToString().ToLower())
  },
  "github": {
    "owner": "$ghOwner",
    "repo": "$ghRepo"
  },
  "deploy": {
    "platform": "$stackDeploy",
    "projectId": "$deployProjectId",
    "previewUrls": $($previewUrlsEnabled.ToString().ToLower())
  },
  "monitoring": {
    "platform": "$stackAnalytics",
    "org": "$monitoringOrg",
    "project": "$monitoringProject"
  },
  "version": "1.0.0"
}
"@

$pipelineJsonPath = Join-Path $ProjectRoot "pipeline.json"
$pipelineJson | Set-Content $pipelineJsonPath
Write-Step "Created pipeline.json"
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

  # Ensure the pre-commit hook is executable on non-Windows
  $hookPath = Join-Path $ProjectRoot ".husky/pre-commit"
  if (Test-Path $hookPath) {
    if ($IsLinux -or $IsMacOS) {
      chmod +x $hookPath 2>$null
    }
    # Ensure the hook has the lint-staged command
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

Write-Title "SETUP COMPLETE"

Write-Host @"
${C.Green}[DONE]${C.Reset} Generated $generatedCount files for $projName
${C.Cyan}${C.Reset}

${C.Cyan}Project Structure:${C.Reset}
  |-- pipeline.json            Config (source of truth for agents)
  |-- AGENTS.md                ShipKit Agent Protocol
  |-- ROADMAP.md               Product roadmap
  |-- BUGS.md                  Bug tracker
  |-- LAST_SESSION.md          Session continuity
  |-- .github/
  |   |-- dependabot.yml       Weekly dependency updates
  |   |-- workflows/
  |       |-- ci.yml           lint, typecheck, test, build
  |       |-- codeql.yml       Security scanning
  |       |-- playwright.yml   E2E on preview
  |-- .opencode/agents/
  |   |-- planner.md           PM + Eng Lead
  |   |-- security-reviewer.md Security Engineer
  |   |-- monitor.md           SRE + Incident Commander
  |   |-- co-developer.md      Builder
  |-- .husky/pre-commit        Pre-commit hooks

${C.Yellow}Next Steps:${C.Reset}
  1. Install deps:     ${C.Cyan}npm install --save-dev husky lint-staged prettier${C.Reset}
  2. Init Husky:       ${C.Cyan}npx husky init${C.Reset}
  3. Push to GitHub:   ${C.Cyan}git push origin main${C.Reset}
  4. Add GitHub Secrets: Settings > Secrets > Actions
  5. Enable branch protection on main branch
  6. Start building:   ${C.Cyan}Say "plan: <feature>" to the Planner Agent${C.Reset}

${C.Bold}Remember:${C.Reset}
  - Run 'review security' before pushing to catch issues early
  - Run 'check errors' at session start for automated health check
  - All agent files read pipeline.json to adapt to YOUR stack
"@

if ($skippedCount -gt 0) {
  Write-Host @"
${C.Yellow}[WARN]${C.Reset} $skippedCount files were skipped (already exist). Use -Force to overwrite.
"@
}

return $Vars
