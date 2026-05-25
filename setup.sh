#!/usr/bin/env bash
# Self-clean CRLF line endings (fixes heredoc issues on cross-platform clones)
if grep -q $'\r' "$0" 2>/dev/null; then
  sed -i 's/\r$//' "$0"
  exec "$0" "$@"
fi
#
# ShipKit Setup — Connect your tools. Ship to production. No team required.
#
# Usage:
#   curl -fsSL https://shipkit.dev/setup.sh | bash
#   ./setup.sh                        # Interactive
#   ./setup.sh --config config.json   # Headless
#   ./setup.sh --detect-only          # Print detected config
#
# Works with ANY stack, ANY AI agent, ANY IDE, ANY deploy platform.

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Parse args
CONFIG_FILE=""
OUTPUT_DIR="."
FORCE=false
DETECT_ONLY=false
DEFAULTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG_FILE="$2"; shift 2 ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --force|-f) FORCE=true; shift ;;
    --detect-only) DETECT_ONLY=true; shift ;;
    --defaults|-y) DEFAULTS=true; shift ;;
    *) echo "Usage: $0 [--config file] [--output dir] [--force] [--detect-only] [--defaults]"; exit 1 ;;
  esac
done

# Check Node.js availability early
if ! command -v node &>/dev/null; then
  echo -e "${RED}Error: Node.js is required but not installed.${NC}"
  echo -e "Install Node.js from ${CYAN}https://nodejs.org${NC} or use:"
  echo -e "  ${CYAN}npx shipkit-pipe setup${NC} (auto-installs via npm)"
  exit 1
fi

# Helpers
title() { $DEFAULTS && return; echo -e "\n${BOLD}${CYAN}===== $1 =====${NC}\n"; }
step() { echo -e "${GREEN}[*]${NC} $1"; }
info() { echo -e "  ${YELLOW}$1${NC}"; }
err()  { echo -e "  ${RED}$1${NC}"; }

read_value() {
  local prompt="$1" default="$2"
  $DEFAULTS && echo "$default" && return
  local default_str=""
  [ -n "$default" ] && default_str=" [$default]"
  read -r -p "$prompt$default_str: " val
  echo "${val:-$default}"
}

read_choice() {
  local prompt="$1"; shift
  local default="$1"; shift
  $DEFAULTS && echo "$default" && return
  local options=("$@")
  echo -e "${YELLOW}$prompt${NC}"
  for i in "${!options[@]}"; do
    local mark=""
    [ "${options[$i]}" = "$default" ] && mark=" ${GREEN}(default)${NC}"
    echo "  $((i+1)). ${options[$i]}$mark"
  done
  read -r -p "Enter number (1-${#options[@]}): " val
  [ -z "$val" ] && echo "$default" && return
  local num
  num=$(echo "$val" | tr -dc '0-9')
  if [ "$num" -ge 1 ] && [ "$num" -le "${#options[@]}" ]; then
    echo "${options[$((num-1))]}"
  else
    echo "$default"
  fi
}

confirm_yn() {
  local prompt="$1" default="$2"
  $DEFAULTS && echo "$default" && return
  local default_str="y/N"
  $default && default_str="Y/n"
  read -r -p "$prompt ($default_str): " val
  [ -z "$val" ] && echo "$default" && return
  [[ "$val" =~ ^[Yy] ]] && echo true || echo false
}

# Auto-detect project
auto_detect() {
  local project_name=""
  local project_desc=""
  local frontend=""
  local pkg_manager="npm"
  local node_ver="20"
  local build_cmd=""
  local test_cmd=""
  local lint_cmd=""
  local has_docker=false
  local has_git=false
  local git_remote=""

  if [ -f "package.json" ]; then
    if command -v node &>/dev/null; then
      project_name=$(node -e "try{console.log(require('./package.json').name||'')}catch(e){}" 2>/dev/null || true)
      project_desc=$(node -e "try{console.log(require('./package.json').description||'')}catch(e){}" 2>/dev/null || true)
      build_cmd=$(node -e "try{const s=require('./package.json').scripts||{};console.log(s.build?'npm run build':'')}catch(e){}" 2>/dev/null || true)
      test_cmd=$(node -e "try{const s=require('./package.json').scripts||{};console.log(s.test?'npm test':'')}catch(e){}" 2>/dev/null || true)
      lint_cmd=$(node -e "try{const s=require('./package.json').scripts||{};console.log(s.lint?'npm run lint':'')}catch(e){}" 2>/dev/null || true)

      # Detect framework
      if node -e "try{require('next/package.json')}catch(e){process.exit(1)}" 2>/dev/null; then
        frontend="Next.js"
      elif node -e "try{require('react/package.json')}catch(e){process.exit(1)}" 2>/dev/null; then
        frontend="React + Vite"
      elif node -e "try{require('vue/package.json')}catch(e){process.exit(1)}" 2>/dev/null; then
        frontend="Vue"
      elif node -e "try{require('svelte/package.json')}catch(e){process.exit(1)}" 2>/dev/null; then
        frontend="Svelte"
      fi

      # Detect package manager
      if command -v pnpm &>/dev/null && [ -f "pnpm-lock.yaml" ]; then
        pkg_manager="pnpm"
      elif command -v yarn &>/dev/null && [ -f "yarn.lock" ]; then
        pkg_manager="yarn"
      fi
    fi
  fi

  [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] && has_docker=true
  [ -d ".git" ] && has_git=true
  [ "$has_git" = true ] && git_remote=$(git config --get remote.origin.url 2>/dev/null || true)

  echo "{\"projectName\":\"$project_name\",\"projectDesc\":\"$project_desc\",\"frontend\":\"$frontend\",\"packageManager\":\"$pkg_manager\",\"nodeVersion\":\"$node_ver\",\"buildCommand\":\"$build_cmd\",\"testCommand\":\"$test_cmd\",\"lintCommand\":\"$lint_cmd\",\"hasDocker\":$has_docker,\"hasGit\":$has_git,\"gitRemote\":\"$git_remote\"}"
}

# Load config
CONFIG="{}"
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
  step "Loading config from $CONFIG_FILE"
  CONFIG=$(cat "$CONFIG_FILE")
fi

# Detect
DETECTED=$(auto_detect)

if $DETECT_ONLY; then
  echo -e "${CYAN}Detected project config:${NC}"
  echo "$DETECTED" | node -e "process.stdin.on('data',d=>{try{console.log(JSON.stringify(JSON.parse(d),null,2))}catch(e){console.log(d+'')}})" 2>/dev/null || echo "$DETECTED"
  exit 0
fi

# Extract values from config (using Node.js for JSON parsing)
get_config_val() {
  local key="$1"
  echo "$CONFIG" | node -e "process.stdin.on('data',d=>{try{const c=JSON.parse(d);console.log(c['$key']||'')}catch(e){console.log('')}})" 2>/dev/null || true
}

get_proj_val() {
  echo "$CONFIG" | node -e "process.stdin.on('data',d=>{try{const c=JSON.parse(d).project||{};console.log(c['$1']||'')}catch(e){console.log('')}})" 2>/dev/null || true
}

get_detected_val() {
  echo "$DETECTED" | node -e "process.stdin.on('data',d=>{try{const c=JSON.parse(d);console.log(c['$1']||'')}catch(e){console.log('')}})" 2>/dev/null || true
}

# ============================
# WELCOME
# ============================
echo -e "${BOLD}${CYAN}"
cat << 'EOF'
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
EOF
echo -e "${NC}"

DETECTED_FRONTEND=$(get_detected_val "frontend")
DETECTED_PM=$(get_detected_val "packageManager")
DETECTED_NODE=$(get_detected_val "nodeVersion")
[ -n "$DETECTED_FRONTEND" ] && info "Detected: $DETECTED_FRONTEND | $DETECTED_PM | Node $DETECTED_NODE"

# ============================
# 1. PROJECT INFO
# ============================
title "PROJECT"

DEFAULT_NAME=$(get_detected_val "projectName")
DEFAULT_DESC=$(get_detected_val "projectDesc")
PROJ_NAME=$(read_value "Project name" "${DEFAULT_NAME:-MyApp}")
PROJ_DESC=$(read_value "Project description" "${DEFAULT_DESC:-A web application}")

# ============================
# 2. AI AGENT
# ============================
title "AI AGENT"

read -r -d '' AGENT_CHOICES << 'AGENTS' || true
Claude Code (Anthropic)
Cursor
GitHub Copilot
OpenCode
CodeGPT
Continue.dev
Cline
Aider
Other / Custom
AGENTS

SELECTED_AGENT=$(read_choice "Which AI agent do you use?" "Claude Code (Anthropic)" $AGENT_CHOICES)

# Map agent to config file
case "$SELECTED_AGENT" in
  "Claude Code"*) AGENT_CONFIG_FILES="CLAUDE.md" ;;
  "Cursor"*) AGENT_CONFIG_FILES=".cursorrules" ;;
  "GitHub Copilot"*) AGENT_CONFIG_FILES=".github/copilot-instructions.md" ;;
  "OpenCode"*) AGENT_CONFIG_FILES=".opencode/agents/co-developer.md" ;;
  *) AGENT_CONFIG_FILES="AGENTS.md" ;;
esac

# ============================
# 3. GITHUB
# ============================
title "GITHUB"

GH_OWNER=""
GH_REPO=""

if command -v gh &>/dev/null; then
  if [ "$(confirm_yn "GitHub CLI detected. Auto-configure from current repo?" false)" = true ]; then
    GH_OWNER=$(gh repo view --json owner --jq .owner.login 2>/dev/null || true)
    GH_REPO=$(gh repo view --json name --jq .name 2>/dev/null || true)
    [ -n "$GH_OWNER" ] && step "Detected: $GH_OWNER / $GH_REPO"
  fi
fi

if [ -z "$GH_OWNER" ]; then
  GIT_REMOTE=$(get_detected_val "gitRemote")
  GH_OWNER=$(read_value "GitHub username/organization" "$(echo "$GIT_REMOTE" | sed -E 's/.*[:/]([^/]+)\/.*/\1/')")
  GH_REPO=$(read_value "GitHub repository name" "$(echo "$PROJ_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')")
fi

if ! $DEFAULTS && command -v gh &>/dev/null; then
  if [ "$(confirm_yn "Authenticate ShipKit with GitHub?" true)" = true ]; then
    GH_TOKEN=$(gh auth token 2>/dev/null || true)
    [ -n "$GH_TOKEN" ] && step "GitHub authenticated."
  fi
fi

# ============================
# 4. DEPLOY PLATFORM
# ============================
title "DEPLOY PLATFORM"

read -r -d '' DEPLOY_CHOICES << 'DEPLOYS' || true
Vercel
Netlify
Fly.io
Railway
Render
Cloudflare Pages
Docker / Self-hosted
AWS
GCP
None yet
DEPLOYS

DEPLOY_PLATFORM="Vercel"
[ -f "vercel.json" ] || [ -d ".vercel" ] && DEPLOY_PLATFORM="Vercel"
[ -f "netlify.toml" ] && DEPLOY_PLATFORM="Netlify"
[ -z "$DEPLOY_PLATFORM" ] && DEPLOY_PLATFORM=$(read_choice "Where do you deploy?" "Vercel" $DEPLOY_CHOICES)

DEPLOY_TOKEN=""
DEPLOY_PROJECT_ID=""
if ! $DEFAULTS && [ "$DEPLOY_PLATFORM" != "None yet" ]; then
  if [ "$DEPLOY_PLATFORM" = "Vercel" ] && command -v vercel &>/dev/null; then
    if [ "$(confirm_yn "Authenticate with Vercel?" true)" = true ]; then
      DEPLOY_TOKEN=$(vercel token 2>/dev/null || true)
      DEPLOY_PROJECT_ID=$(vercel project --json 2>/dev/null | node -e "process.stdin.on('data',d=>{try{console.log(JSON.parse(d).id||'')}catch(e){console.log('')}})" 2>/dev/null || true)
      [ -n "$DEPLOY_PROJECT_ID" ] && step "Vercel project detected."
    fi
  fi
fi

# ============================
# 5. DATABASE
# ============================
title "DATABASE"

read -r -d '' DB_CHOICES << 'DBS' || true
Supabase Postgres
Firebase Firestore
MongoDB
PostgreSQL (direct)
MySQL
SQLite
None yet
DBS

DB_CHOICE="Supabase Postgres"
[ -d "supabase" ] || [ -f "supabase.json" ] && DB_CHOICE="Supabase Postgres"
[ -f "firebase.json" ] && DB_CHOICE="Firebase Firestore"
[ -z "$DB_CHOICE" ] && DB_CHOICE=$(read_choice "Which database do you use?" "Supabase Postgres" $DB_CHOICES)

if ! $DEFAULTS && [[ "$DB_CHOICE" == "Supabase"* ]] && command -v supabase &>/dev/null; then
  if [ "$(confirm_yn "Authenticate with Supabase?" true)" = true ]; then
    DB_TOKEN=$(supabase auth token 2>/dev/null || true)
    [ -n "$DB_TOKEN" ] && step "Supabase authenticated."
  fi
fi

# ============================
# 6. MONITORING
# ============================
title "MONITORING"

MONITORING_CHOICE=$(read_choice "Error tracking / monitoring?" "None" "Sentry" "Datadog" "LogRocket" "PostHog" "None")

# ============================
# GENERATE FILES
# ============================
title "GENERATING PIPELINE FILES"

TEMPLATE_DIR="$(dirname "$0")/template"
SCRIPT_DIR="$(dirname "$0")"
RENDERER="$(dirname "$0")/template/render.js"

# If running from curl pipe, template won't exist locally
# In that case, we need to download the template
if [ ! -d "$TEMPLATE_DIR" ] && [ -n "${BASH_SOURCE[0]}" ]; then
  # Try relative to script
  SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TEMPLATE_DIR="$SCRIPT_PATH/template"
  RENDERER="$SCRIPT_PATH/template/render.js"
fi

# If template still doesn't exist, the user needs to clone the repo
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo -e "${RED}Template directory not found.${NC}"
  echo -e "Please clone the ShipKit repo and run setup from there:"
  echo -e "  ${CYAN}git clone https://github.com/sagar-grv/shipkit.git${NC}"
  echo -e "  ${CYAN}cd shipkit && ./setup.sh${NC}"
  exit 1
fi

PROJECT_ROOT="$(cd "$OUTPUT_DIR" && pwd)"

# Export all template variables as SK_* env vars (safe — no quoting issues)
# These are read by Node.js render_template via process.env
export_sk_vars() {
  export SK_PROJECT_NAME="$PROJ_NAME"
  export SK_PROJECT_DESCRIPTION="$PROJ_DESC"
  export SK_DATE="$(date +%Y-%m-%d)"
  export SK_STACK_FRONTEND="${DETECTED_FRONTEND:-Web application}"
  export SK_STACK_DATABASE="$DB_CHOICE"
  export SK_STACK_AUTH="$DB_CHOICE"
  export SK_STACK_AI="AI-powered features"
  export SK_STACK_DEPLOY="$DEPLOY_PLATFORM"
  local storage_val="${DB_CHOICE}"
  case "$storage_val" in
    Supabase*) storage_val="Supabase Storage" ;;
    Firebase*) storage_val="Firebase Storage" ;;
    *) storage_val="Cloud storage (S3, etc.)" ;;
  esac
  export SK_STACK_STORAGE="$storage_val"
  export SK_STACK_E2E="Playwright"
  export SK_STACK_ANALYTICS="$MONITORING_CHOICE"
  export SK_NODE_VERSION="${DETECTED_NODE:-20}"
  export SK_BUILD_COMMAND="${DEFAULT_BUILD:-npm run build}"
  export SK_TEST_COMMAND="${DEFAULT_TEST:-npm test}"
  export SK_LINT_COMMAND="${DEFAULT_LINT:-npm run lint}"
  export SK_TYPECHECK_COMMAND="npx tsc --noEmit"
  export SK_PACKAGE_MANAGER="${DETECTED_PM:-npm}"
  export SK_COVERAGE_ENABLED="true"
  export SK_DATABASE_TYPE="$DB_CHOICE"
  export SK_DATABASE_PROJECT_ID=""
  export SK_DATABASE_REGION=""
  export SK_RLS_ENABLED="true"
  export SK_GITHUB_OWNER="$GH_OWNER"
  export SK_GITHUB_REPO="$GH_REPO"
  export SK_DEPLOY_PLATFORM="$DEPLOY_PLATFORM"
  export SK_DEPLOY_PROJECT_ID="${DEPLOY_PROJECT_ID:-}"
  export SK_PREVIEW_URLS_ENABLED="true"
  export SK_MONITORING_PLATFORM="$MONITORING_CHOICE"
  export SK_MONITORING_ORG=""
  export SK_MONITORING_PROJECT=""
  export SK_AI_AGENT="$SELECTED_AGENT"
  export SK_AGENT_CONFIG_FILES="$AGENT_CONFIG_FILES"
}

# Render template function (uses Node.js — safe from shell injection)
render_template() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  node "$RENDERER" "$src" "$dst"

  if [ -f "$dst" ]; then
    step "Created ${dst#$PROJECT_ROOT/}"
    echo "$dst"
  else
    info "ERROR: Failed to render $src"
    return 1
  fi
}

# Export all SK_* env vars for template rendering
export_sk_vars

FILES_GENERATED=0
FILES_SKIPPED=0

write_file() {
  local src="$1" dst="$2"
  local full_dst="$PROJECT_ROOT/$dst"

  if [ -f "$full_dst" ] && ! $FORCE; then
    info "SKIP: $dst (already exists, use --force to overwrite)"
    FILES_SKIPPED=$((FILES_SKIPPED + 1))
    return
  fi

  local full_src="$TEMPLATE_DIR/$src"
  if [ ! -f "$full_src" ]; then
    info "WARN: Template not found: $src"
    return
  fi

  render_template "$full_src" "$full_dst" && FILES_GENERATED=$((FILES_GENERATED + 1))
}

write_file "github/dependabot.yml"          ".github/dependabot.yml"
write_file "github/workflows/ci.yml"        ".github/workflows/ci.yml"
write_file "github/workflows/codeql.yml"    ".github/workflows/codeql.yml"
write_file "github/workflows/playwright.yml" ".github/workflows/playwright.yml"
write_file "agents/co-developer.md"         "shipkit/co-developer.md"
write_file "agents/planner.md"              "shipkit/planner.md"
write_file "agents/security-reviewer.md"    "shipkit/security-reviewer.md"
write_file "agents/monitor.md"              "shipkit/monitor.md"
write_file "husky/pre-commit"               ".husky/pre-commit"
write_file "docs/AGENTS.md"                 "AGENTS.md"
write_file "docs/ROADMAP.md"                "ROADMAP.md"
write_file "docs/BUGS.md"                   "BUGS.md"
write_file "docs/LAST_SESSION.md"           "LAST_SESSION.md"

# Generate AI-agent-specific config
case "$SELECTED_AGENT" in
  "Claude Code"*)   AGENT_DST="CLAUDE.md" ;;
  "Cursor"*)        AGENT_DST=".cursorrules" ;;
  "GitHub Copilot"*) AGENT_DST=".github/copilot-instructions.md" ;;
  "OpenCode"*)      AGENT_DST=".opencode/agents/co-developer.md" ;;
  *)                AGENT_DST="" ;;
esac

if [ -n "$AGENT_DST" ]; then
  AGENT_FULL="$PROJECT_ROOT/$AGENT_DST"
  if [ ! -f "$AGENT_FULL" ] || $FORCE; then
    mkdir -p "$(dirname "$AGENT_FULL")"
    cat > "$AGENT_FULL" << AGENTEOF
# $PROJ_NAME — AI Agent Configuration

This file configures your AI agent ($SELECTED_AGENT) for **$PROJ_NAME**.

→ Read \`AGENTS.md\` for the full protocol and rules
→ Read \`shipkit.json\` for project config and tech stack
→ Read \`ROADMAP.md\` for what's planned
→ Read \`BUGS.md\` for what's broken
→ Read \`LAST_SESSION.md\` for session continuity

## Quick Start
- Say "plan: <feature>" to start the planning process
- Say "review security" before pushing changes
- Say "check errors" at session start
AGENTEOF
    step "Created $AGENT_DST"
    FILES_GENERATED=$((FILES_GENERATED + 1))
  fi
fi

# Generate shipkit.json
SHIPKIT_JSON="$PROJECT_ROOT/shipkit.json"
cat > "$SHIPKIT_JSON" << JSONEOF
{
  "project": {
    "name": "$PROJ_NAME",
    "description": "$PROJ_DESC"
  },
  "stack": {
    "frontend": "${DETECTED_FRONTEND:-Web application}",
    "database": "$DB_CHOICE",
    "auth": "$DB_CHOICE",
    "deploy": "$DEPLOY_PLATFORM",
    "storage": "${DB_CHOICE/Supabase*/Supabase Storage}",
    "e2e": "Playwright",
    "monitoring": "$MONITORING_CHOICE"
  },
  "ci": {
    "nodeVersion": "${DETECTED_NODE:-20}",
    "buildCommand": "npm run build",
    "testCommand": "npm test",
    "lintCommand": "npm run lint",
    "typecheckCommand": "npx tsc --noEmit",
    "packageManager": "${DETECTED_PM:-npm}"
  },
  "aiAgent": {
    "tool": "$SELECTED_AGENT",
    "configFiles": "$AGENT_CONFIG_FILES"
  },
  "github": {
    "owner": "$GH_OWNER",
    "repo": "$GH_REPO"
  },
  "deploy": {
    "platform": "$DEPLOY_PLATFORM",
    "projectId": "${DEPLOY_PROJECT_ID:-}",
    "previewUrls": $([ "$DEPLOY_PLATFORM" = "Vercel" ] && echo "true" || echo "false")
  },
  "database": {
    "type": "$DB_CHOICE",
    "rlsEnabled": $([ "$DB_CHOICE" = "${DB_CHOICE#Supabase}" ] && echo "false" || echo "true")
  },
  "version": "2.0.1"
}
JSONEOF
step "Created shipkit.json"
FILES_GENERATED=$((FILES_GENERATED + 1))

# Husky setup
title "SETTING UP PRE-COMMIT HOOKS"

if command -v npx &>/dev/null; then
  HUSKY_DIR="$PROJECT_ROOT/.husky"
  if [ ! -d "$HUSKY_DIR" ]; then
    step "Initializing Husky..."
    (cd "$PROJECT_ROOT" && npx husky init 2>/dev/null) || info "Could not init Husky. Run 'npx husky init' manually."
  fi
  HOOK_PATH="$PROJECT_ROOT/.husky/pre-commit"
  if [ -f "$HOOK_PATH" ]; then
    chmod +x "$HOOK_PATH" 2>/dev/null || true
  fi
  step "Pre-commit hooks configured."
else
  info "Node.js not found. Run 'npx husky init' manually after installing dependencies."
fi

# ============================
# SUMMARY
# ============================
title "SETUP COMPLETE — $PROJ_NAME is ShipKit ready"

echo -e "${GREEN}[DONE]${NC} Generated $FILES_GENERATED files"

echo -e "
${CYAN}ShipKit Files:${NC}
  shipkit.json          ← Config for your AI agent (reads this at startup)
  AGENTS.md             ← Universal AI agent protocol
  ROADMAP.md            ← Feature tracker
  BUGS.md               ← Bug tracker
  LAST_SESSION.md       ← Session continuity
  shipkit/              ← AI agent prompts
  |-- planner.md        PM + Eng Lead
  |-- co-developer.md   Builder (default agent)
  |-- security-reviewer.md  Security Engineer
  |-- monitor.md        SRE + Incident Commander
  .github/              ← CI/CD + Security + Dependencies
  .husky/pre-commit     ← Pre-commit hooks"

[ -n "$AGENT_DST" ] && echo "  $AGENT_DST    ← $SELECTED_AGENT config file"

echo -e "
${YELLOW}Next Steps:${NC}
  1. Install deps:     ${CYAN}npm install --save-dev husky lint-staged prettier${NC}
  2. Init Husky:       ${CYAN}npx husky init${NC}
  3. Push to GitHub:   ${CYAN}git push origin main${NC}
  4. Open in your AI agent and say \"${CYAN}plan: <feature>${NC}\"
  5. Before pushing: say \"${CYAN}review security${NC}\"
  6. At session start: say \"${CYAN}check errors${NC}\"

${CYAN}Your AI Agent will automatically:${NC}
  • Read shipkit.json to learn your tech stack
  • Follow AGENTS.md for the development protocol
  • Plan features with planner.md
  • Review security before each push
  • Monitor production health every session

${BOLD}One team. Zero overhead. Production apps.${NC}
"

if [ $FILES_SKIPPED -gt 0 ]; then
  echo -e "${YELLOW}[WARN]${NC} $FILES_SKIPPED files were skipped (already exist). Use --force to overwrite."
fi
