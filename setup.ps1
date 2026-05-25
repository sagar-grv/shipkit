<#
.SYNOPSIS
  ShipKit Setup — Auto-detect & generate CI/CD, health checks, security

.DESCRIPTION
  Reads your project files and generates CI/CD, health monitoring, security
  scanning, and AI agent config. Only generates what your project needs.

.PARAMETER Interactive
  Ask questions instead of auto-detect

.PARAMETER DryRun
  Preview what would be generated without writing files

.EXAMPLE
  .\setup.ps1
  Auto-detect & generate (no prompts)

.EXAMPLE
  .\setup.ps1 -Interactive
  Ask questions

.EXAMPLE
  .\setup.ps1 -DryRun
  Preview without writing files
#>

param(
  [switch]$Interactive,
  [switch]$DryRun
)

$C = @{
  Green  = [char]0x1b + '[32m'
  Yellow = [char]0x1b + '[33m'
  Cyan   = [char]0x1b + '[36m'
  Red    = [char]0x1b + '[31m'
  Bold   = [char]0x1b + '[1m'
  Dim    = [char]0x1b + '[2m'
  Reset  = [char]0x1b + '[0m'
}

function Get-NodeValue {
  param($Expr)
  try {
    return $(node -e "try{$Expr}catch(e){console.log('')}" 2>$null)
  } catch { return '' }
}

# ─── Detect ──────────────────────────────────────────────────────────────────

$cwd = Get-Location
$Name = ''
$Desc = ''
$Frontend = ''
$Pm = 'npm'
$GitRemote = ''
$GitPlatform = 'github'
$GhOwner = ''
$GhRepo = ''
$NodeVer = '20'
$HasLint = $false
$HasTest = $false
$HasBuild = $false
$HasTypecheck = $false
$IsMonorepo = $false
$SubProjects = @()
$DeployUrl = ''
$HasPackageJson = Test-Path (Join-Path $cwd 'package.json')

if ($HasPackageJson) {
  $pkg = Get-Content (Join-Path $cwd 'package.json') -Raw | ConvertFrom-Json
  if ($pkg.name) { $Name = $pkg.name }
  if ($pkg.description) { $Desc = $pkg.description }

  # Framework detection
  $deps = @{}
  if ($pkg.dependencies) { $pkg.dependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
  if ($pkg.devDependencies) { $pkg.devDependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
  if ($deps.ContainsKey('next')) { $Frontend = 'Next.js' }
  elseif ($deps.ContainsKey('nuxt')) { $Frontend = 'Nuxt' }
  elseif ($deps.ContainsKey('astro')) { $Frontend = 'Astro' }
  elseif ($deps.ContainsKey('react')) { $Frontend = 'React' }
  elseif ($deps.ContainsKey('vue')) { $Frontend = 'Vue' }
  elseif ($deps.ContainsKey('svelte')) { $Frontend = 'Svelte' }
  elseif ($deps.ContainsKey('express')) { $Frontend = 'Express' }

  # Scripts detection
  if ($pkg.scripts) {
    $HasLint = ![string]::IsNullOrEmpty($pkg.scripts.lint)
    $HasTest = ![string]::IsNullOrEmpty($pkg.scripts.test)
    $HasBuild = ![string]::IsNullOrEmpty($pkg.scripts.build)
    $HasTypecheck = (![string]::IsNullOrEmpty($pkg.scripts.typecheck) -or ![string]::IsNullOrEmpty($pkg.scripts.'type-check') -or ![string]::IsNullOrEmpty($pkg.scripts.tsc))
  }

  # Node version
  $nvmrc = Join-Path $cwd '.nvmrc'
  $nodeVer = Join-Path $cwd '.node-version'
  if (Test-Path $nvmrc) { $NodeVer = (Get-Content $nvmrc).Trim().TrimStart('v') }
  elseif (Test-Path $nodeVer) { $NodeVer = (Get-Content $nodeVer).Trim().TrimStart('v') }
  elseif ($pkg.engines -and $pkg.engines.node) {
    $m = [regex]::Match($pkg.engines.node, '(\d+)')
    if ($m.Success) { $NodeVer = $m.Groups[1].Value }
  }

  # Monorepo check
  if (!$Name -or !$pkg.scripts -or ($pkg.scripts.PSObject.Properties.Name.Count -eq 0)) {
    $IsMonorepo = $true
    foreach ($dir in @('frontend','backend','web','app','api','server','client')) {
      if (Test-Path (Join-Path $cwd "$dir\package.json")) { $SubProjects += $dir }
    }
  }
} else {
  # Non-Node project detection
  if (Test-Path (Join-Path $cwd 'pyproject.toml')) { $Frontend = 'Python' }
  elseif (Test-Path (Join-Path $cwd 'go.mod')) { $Frontend = 'Go' }
  elseif (Test-Path (Join-Path $cwd 'Cargo.toml')) { $Frontend = 'Rust' }
  elseif (Test-Path (Join-Path $cwd 'docker-compose.yml') -or (Test-Path (Join-Path $cwd 'docker-compose.yaml'))) { $Frontend = 'Docker' }
  # Monorepo check
  foreach ($dir in @('frontend','backend','web','app','api','server','client')) {
    if (Test-Path (Join-Path $cwd "$dir\package.json")) { $SubProjects += $dir; $IsMonorepo = $true }
  }
}

# Package manager
if (Test-Path (Join-Path $cwd 'pnpm-lock.yaml')) { $Pm = 'pnpm' }
elseif (Test-Path (Join-Path $cwd 'yarn.lock')) { $Pm = 'yarn' }
elseif (Test-Path (Join-Path $cwd 'bun.lockb')) { $Pm = 'bun' }

# Git
if (Test-Path (Join-Path $cwd '.git')) {
  try { $GitRemote = git config --get remote.origin.url 2>$null } catch {}
  if ($GitRemote) {
    $m = [regex]::Match($GitRemote, '[:/]([^/]+)/([^/.]+?)(?:\.git)?$')
    if ($m.Success) { $GhOwner = $m.Groups[1].Value; $GhRepo = $m.Groups[2].Value }
    if ($GitRemote -match 'gitlab') { $GitPlatform = 'gitlab' }
    elseif ($GitRemote -match 'bitbucket') { $GitPlatform = 'bitbucket' }
  }
}

# Deploy URL
if (Test-Path (Join-Path $cwd 'vercel.json')) { $DeployUrl = "https://$GhRepo.vercel.app" }
elseif (Test-Path (Join-Path $cwd 'fly.toml')) {
  $fly = Get-Content (Join-Path $cwd 'fly.toml') -Raw
  $m = [regex]::Match($fly, "app\s*=\s*`"([^`"]+)`"")
  if ($m.Success) { $DeployUrl = "https://$($m.Groups[1].Value).fly.dev" }
}

[string]$Name = if ($Name) { $Name } else { Split-Path $cwd -Leaf }
[string]$Desc = if ($Desc) { $Desc } else { 'A web application' }

# ─── Interactive mode ────────────────────────────────────────────────────────
if ($Interactive) {
  Write-Host "`n  $($C.Bold)$($C.Cyan)⚓ ShipKit$($C.Reset) — interactive setup`n"
  $input = Read-Host "  Project name [$Name]"
  if ($input) { $Name = $input }
  $input = Read-Host "  Description [$Desc]"
  if ($input) { $Desc = $input }
  $input = Read-Host "  GitHub owner [$GhOwner]"
  if ($input) { $GhOwner = $input }
  $input = Read-Host "  GitHub repo [$GhRepo]"
  if ($input) { $GhRepo = $input }
}

if (!$GhOwner) { $GhOwner = 'your-username' }
if (!$GhRepo) { $GhRepo = $Name.ToLower() -replace '[^a-z0-9-]','' }

# ─── Generate files ──────────────────────────────────────────────────────────
$templateDir = Join-Path (Split-Path $PSCommandPath -Parent) 'template'
$renderer = Join-Path $templateDir 'render.js'
$Gen = 0; $Skip = 0

function Write-File {
  param($Src, $Dst)
  if (Test-Path $Dst) { $script:Skip++; return }
  if ($DryRun) { Write-Host "  would write: $Dst"; $script:Gen++; return }
  $srcPath = Join-Path $templateDir $Src
  if (!(Test-Path $srcPath)) { return }
  $dstDir = Split-Path $Dst -Parent
  if ($dstDir) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
  $env:SK_PROJECT_NAME = $Name
  $env:SK_PROJECT_DESCRIPTION = $Desc
  $env:SK_NODE_VERSION = $NodeVer
  $env:SK_PACKAGE_MANAGER = $Pm
  $env:SK_GITHUB_OWNER = $GhOwner
  $env:SK_GITHUB_REPO = $GhRepo
  $env:SK_GIT_PLATFORM = $GitPlatform
  $env:SK_DEPLOY_URL = $DeployUrl
  $env:SK_HAS_LINT = "$HasLint".ToLower()
  $env:SK_HAS_TEST = "$HasTest".ToLower()
  $env:SK_HAS_BUILD = "$HasBuild".ToLower()
  $env:SK_HAS_TYPECHECK = "$HasTypecheck".ToLower()
  $env:SK_IS_MONOREPO = "$IsMonorepo".ToLower()
  $env:SK_SUB_PROJECTS = ($SubProjects -join ' ')
  $env:SK_FRONTEND = $Frontend
  $env:SK_DATE = (Get-Date -Format 'yyyy-MM-dd')
  & node $renderer $srcPath $Dst 2>$null
  if ($?) { $script:Gen++ }
}

# Platform-specific CI
switch ($GitPlatform) {
  'gitlab' { Write-File 'gitlab/gitlab-ci.yml' '.gitlab-ci.yml' }
  'bitbucket' { Write-File 'bitbucket/bitbucket-pipelines.yml' 'bitbucket-pipelines.yml' }
  default {
    Write-File 'github/workflows/ci.yml' '.github/workflows/ci.yml'
    Write-File 'github/dependabot.yml' '.github/dependabot.yml'
    Write-File 'github/workflows/codeql.yml' '.github/workflows/codeql.yml'
    if ($DeployUrl) { Write-File 'github/workflows/health.yml' '.github/workflows/health.yml' }
  }
}

# Common files
Write-File 'docs/AGENTS.md' 'AGENTS.md'
Write-File 'docs/LAST_SESSION.md' 'LAST_SESSION.md'

# shipkit.json
$shipkitJson = Join-Path $cwd 'shipkit.json'
if (!(Test-Path $shipkitJson)) {
  if ($DryRun) {
    Write-Host "  would write: shipkit.json"
    $Gen++
  } else {
    @"
{
  "project": { "name": "$Name", "description": "$Desc" },
  "ci": { "nodeVersion": "$NodeVer", "packageManager": "$Pm" },
  "github": { "owner": "$GhOwner", "repo": "$GhRepo", "platform": "$GitPlatform" },
  "deploy": { "url": "$DeployUrl" },
  "version": "3.0.4"
}
"@ | Set-Content $shipkitJson
    $Gen++
  }
}

if ($DryRun) {
  Write-Host "`n  $($C.Yellow)Dry run — no files written. Run without -DryRun to generate.$($C.Reset)"
  exit 0
}

Write-Host "`n  $($C.Green)✓ Generated $Gen files$($C.Reset)$(if ($Skip -gt 0) { " ($($C.Yellow)$Skip already exist$($C.Reset))" })`n"