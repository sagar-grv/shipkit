#!/usr/bin/env bash
# ShipKit — Connect your AI agent, CI/CD, security, and deploy.
# Usage:
#   bash setup.sh              Auto-detect & generate (no prompts)
#   bash setup.sh -i           Interactive mode (asks questions)
#   bash setup.sh --help       Show help

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

INTERACTIVE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interactive) INTERACTIVE=true; shift ;;
    --help|-h) echo "Usage: bash setup.sh [-i]"; echo "  -i, --interactive  Ask questions instead of auto-detect"; exit 0 ;;
    *) echo "Usage: bash setup.sh [-i]"; exit 1 ;;
  esac
done

# Check Node.js
if ! command -v node &>/dev/null; then
  echo -e "${RED}Node.js is required.${NC} Install: ${CYAN}https://nodejs.org${NC}"; exit 1
fi

# Check project
if [ ! -f "package.json" ]; then
  echo -e "\n  ${RED}✗ No project found.${NC}"
  echo -e "  Run this inside your project folder:\n"
  echo -e "    ${CYAN}cd my-project${NC}"
  echo -e "    ${CYAN}bash setup.sh${NC}\n"
  exit 1
fi

# ─── Detect ──────────────────────────────────────────────────────────────────
detect() {
  local n=$(node -e "try{console.log(require('./package.json').name||'')}catch(e){}" 2>/dev/null)
  local d=$(node -e "try{console.log(require('./package.json').description||'')}catch(e){}" 2>/dev/null)
  local f=""; node -e "try{require('next/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Next.js"
  [ -z "$f" ] && node -e "try{require('react/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="React"
  [ -z "$f" ] && node -e "try{require('vue/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Vue"
  [ -z "$f" ] && node -e "try{require('svelte/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Svelte"
  local pm="npm"; [ -f "pnpm-lock.yaml" ] && pm="pnpm"; [ -f "yarn.lock" ] && pm="yarn"
  local gr=""; [ -d ".git" ] && gr=$(git config --get remote.origin.url 2>/dev/null || true)
  echo "{\"name\":\"$n\",\"desc\":\"$d\",\"frontend\":\"$f\",\"pm\":\"$pm\",\"gitRemote\":\"$gr\"}"
}

DETECTED=$(detect)

get_val() { echo "$DETECTED" | node -e "process.stdin.on('data',d=>{try{console.log(JSON.parse(d)['$1']||'')}catch(e){console.log('')}})" 2>/dev/null; }

NAME=$(get_val "name")
DESC=$(get_val "desc")
FRONTEND=$(get_val "frontend")
PM=$(get_val "pm")
GIT_REMOTE=$(get_val "gitRemote")

# Extract GitHub info
GH_OWNER=""; GH_REPO=""
if [ -n "$GIT_REMOTE" ]; then
  GH_OWNER=$(echo "$GIT_REMOTE" | sed -E 's/.*[:/]([^/]+)\/.*/\1/')
  GH_REPO=$(echo "$GIT_REMOTE" | sed -E 's/.*[:/][^/]+\/([^/.]+)(\.git)?$/\1/')
fi
[ -z "$GH_OWNER" ] && { GH_OWNER="your-username"; GH_REPO=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-'); }

# ─── Read values (interactive mode only) ────────────────────────────────────

title() { $INTERACTIVE || return; echo -e "\n${BOLD}${CYAN}===== $1 =====${NC}\n"; }
ask() { $INTERACTIVE || { echo "$2"; return; }; local a; read -r -p "  $1 [$2]: " a; echo "${a:-$2}"; }
choose() {
  $INTERACTIVE || { echo "$2"; return; }
  local p="$1" d="$2"; shift 2; local opts=("$@")
  echo -e "${YELLOW}$p${NC}"
  for i in "${!opts[@]}"; do
    local mark=""
    [ "${opts[$i]}" = "$d" ] && mark=" ${GREEN}(default)${NC}"
    echo "  $((i+1)). ${opts[$i]}$mark"
  done
  local a; read -r -p "Enter number (1-${#opts[@]}): " a
  local n=$(echo "$a" | tr -dc '0-9')
  [ -n "$n" ] && [ "$n" -ge 1 ] && [ "$n" -le "${#opts[@]}" ] && echo "${opts[$((n-1))]}" || echo "$d"
}

if $INTERACTIVE; then
  echo -e "\n  ${BOLD}${CYAN}⚓ ShipKit${NC} — interactive setup\n"
  title "PROJECT"; PROJ_NAME=$(ask "Project name" "$NAME"); PROJ_DESC=$(ask "Description" "${DESC:-A web application}")
  title "AI AGENT"; SELECTED_AGENT=$(choose "Which AI agent do you use?" "Claude Code (Anthropic)" "Claude Code (Anthropic)" "Cursor" "GitHub Copilot" "OpenCode" "CodeGPT" "Continue.dev" "Cline" "Aider" "Other")
  title "GITHUB"; [ -z "$GH_OWNER" ] && GH_OWNER=$(ask "GitHub username/organization" "your-username"); [ -z "$GH_REPO" ] && GH_REPO=$(ask "Repository name" "$(echo "$PROJ_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')")
  title "DEPLOY"; DEPLOY_PLATFORM=$(choose "Where do you deploy?" "Vercel" "Vercel" "Netlify" "Fly.io" "Railway" "Render" "Cloudflare Pages" "Docker" "AWS" "GCP" "None yet")
  title "DATABASE"; DB_CHOICE=$(choose "Which database?" "Supabase Postgres" "Supabase Postgres" "Firebase Firestore" "MongoDB" "PostgreSQL" "MySQL" "SQLite" "None yet")
  title "MONITORING"; MONITORING_CHOICE=$(choose "Error tracking?" "Sentry" "Sentry" "Datadog" "LogRocket" "PostHog" "None")
else
  PROJ_NAME="$NAME"; PROJ_DESC="${DESC:-A web application}"
  SELECTED_AGENT="Claude Code (Anthropic)"; DEPLOY_PLATFORM="Vercel"; DB_CHOICE="Supabase Postgres"; MONITORING_CHOICE="Sentry"
fi

# Map agent to config file
case "$SELECTED_AGENT" in
  "Claude Code"*) AGENT_CFG="CLAUDE.md" ;;
  "Cursor"*)      AGENT_CFG=".cursorrules" ;;
  "GitHub Copilot"*) AGENT_CFG=".github/copilot-instructions.md" ;;
  "OpenCode"*)    AGENT_CFG=".opencode/agents/co-developer.md" ;;
  *)              AGENT_CFG="" ;;
esac

# Storage mapping
case "$DB_CHOICE" in
  Supabase*) STORAGE="Supabase Storage" ;;
  Firebase*) STORAGE="Firebase Storage" ;;
  *)         STORAGE="Cloud storage" ;;
esac

# ─── Render & Write ────────────────────────────────────────────────────────

TEMPLATE_DIR="$(dirname "$0")/template"
RENDERER="$(dirname "$0")/template/render.js"

export SK_PROJECT_NAME="$PROJ_NAME"
export SK_PROJECT_DESCRIPTION="$PROJ_DESC"
export SK_DATE="$(date +%Y-%m-%d)"
export SK_STACK_FRONTEND="${FRONTEND:-Web application}"
export SK_STACK_DATABASE="$DB_CHOICE"
export SK_STACK_AUTH="$DB_CHOICE"
export SK_STACK_AI=""
export SK_STACK_DEPLOY="$DEPLOY_PLATFORM"
export SK_STACK_STORAGE="$STORAGE"
export SK_STACK_E2E="Playwright"
export SK_STACK_ANALYTICS="$MONITORING_CHOICE"
export SK_NODE_VERSION="20"
export SK_BUILD_COMMAND="npm run build"
export SK_TEST_COMMAND="npm test"
export SK_LINT_COMMAND="npm run lint"
export SK_TYPECHECK_COMMAND="npx tsc --noEmit"
export SK_PACKAGE_MANAGER="$PM"
export SK_COVERAGE_ENABLED="true"
export SK_DATABASE_TYPE="$DB_CHOICE"
export SK_DATABASE_PROJECT_ID=""
export SK_DATABASE_REGION=""
export SK_RLS_ENABLED="true"
export SK_GITHUB_OWNER="$GH_OWNER"
export SK_GITHUB_REPO="$GH_REPO"
export SK_DEPLOY_PLATFORM="$DEPLOY_PLATFORM"
export SK_DEPLOY_PROJECT_ID=""
export SK_PREVIEW_URLS_ENABLED="true"
export SK_MONITORING_PLATFORM="$MONITORING_CHOICE"
export SK_MONITORING_ORG=""
export SK_MONITORING_PROJECT=""
export SK_AI_AGENT="$SELECTED_AGENT"
export SK_AGENT_CONFIG_FILES="${AGENT_CFG:-AGENTS.md}"

render() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  node "$RENDERER" "$src" "$dst" &>/dev/null && echo "$dst"
}

GEN=0; SKIP=0

write() {
  local src="$1" dst="$2"
  [ -f "$dst" ] && { SKIP=$((SKIP+1)); return; }
  local tmpl="$TEMPLATE_DIR/$src"
  [ ! -f "$tmpl" ] && return
  render "$tmpl" "$dst" && GEN=$((GEN+1))
}

write "github/dependabot.yml"              ".github/dependabot.yml"
write "github/workflows/ci.yml"            ".github/workflows/ci.yml"
write "github/workflows/codeql.yml"        ".github/workflows/codeql.yml"
write "github/workflows/playwright.yml"    ".github/workflows/playwright.yml"
write "agents/co-developer.md"             "shipkit/co-developer.md"
write "agents/planner.md"                  "shipkit/planner.md"
write "agents/security-reviewer.md"        "shipkit/security-reviewer.md"
write "agents/monitor.md"                  "shipkit/monitor.md"
write "husky/pre-commit"                   ".husky/pre-commit"
write "docs/AGENTS.md"                     "AGENTS.md"
write "docs/ROADMAP.md"                    "ROADMAP.md"
write "docs/BUGS.md"                       "BUGS.md"
write "docs/LAST_SESSION.md"               "LAST_SESSION.md"

# Agent config file
if [ -n "$AGENT_CFG" ]; then
  AGENT_PATH="$AGENT_CFG"
  if [ ! -f "$AGENT_PATH" ]; then
    mkdir -p "$(dirname "$AGENT_PATH")"
    cat > "$AGENT_PATH" << EOF
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
EOF
    GEN=$((GEN+1))
  fi
fi

# shipkit.json
SHIPKIT_JSON="shipkit.json"
if [ ! -f "$SHIPKIT_JSON" ]; then
  cat > "$SHIPKIT_JSON" << JSONEOF
{
  "project": { "name": "$PROJ_NAME", "description": "$PROJ_DESC" },
  "stack": { "frontend": "${FRONTEND:-Web application}", "database": "$DB_CHOICE", "auth": "$DB_CHOICE", "deploy": "$DEPLOY_PLATFORM", "storage": "$STORAGE", "e2e": "Playwright", "monitoring": "$MONITORING_CHOICE" },
  "ci": { "nodeVersion": "20", "buildCommand": "npm run build", "testCommand": "npm test", "lintCommand": "npm run lint", "packageManager": "$PM" },
  "aiAgent": { "tool": "$SELECTED_AGENT", "configFiles": "${AGENT_CFG:-AGENTS.md}" },
  "github": { "owner": "$GH_OWNER", "repo": "$GH_REPO" },
  "deploy": { "platform": "$DEPLOY_PLATFORM", "projectId": "", "previewUrls": $([ "$DEPLOY_PLATFORM" = "Vercel" ] && echo "true" || echo "false") },
  "database": { "type": "$DB_CHOICE", "rlsEnabled": $([[ "$DB_CHOICE" == "Supabase"* ]] && echo "true" || echo "false") },
  "monitoring": { "platform": "$MONITORING_CHOICE" },
  "version": "2.0.1"
}
JSONEOF
  GEN=$((GEN+1))
fi

echo -e "\n  ${GREEN}✓ Generated $GEN files${NC}$([ $SKIP -gt 0 ] && echo " (${YELLOW}$SKIP skipped${NC})")\n"

if $INTERACTIVE; then
  echo -e "${CYAN}Files created:${NC}"
  echo "  shipkit.json      ← Config for your AI agent"
  echo "  AGENTS.md         ← AI agent protocol"
  echo "  ROADMAP.md        ← Feature tracker"
  echo "  BUGS.md           ← Bug tracker"
  echo "  LAST_SESSION.md   ← Session continuity"
  echo "  shipkit/          ← AI agent prompts"
  echo "  .github/          ← CI/CD + Security"
  [ -n "$AGENT_CFG" ] && echo "  $AGENT_CFG        ← $SELECTED_AGENT config"
  echo -e "\n${YELLOW}Next:${NC} git init && git add -A && git commit -m \"init\""
fi
