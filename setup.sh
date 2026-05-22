#!/usr/bin/env bash
#
# ShipKit Setup — Linux / macOS
# Generates all pipeline files for YOUR project.
# Run from your project root: ./shipkit/setup.sh
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

echo ""
echo -e "${BOLD}${CYAN}ShipKit Setup — Production Pipeline Generator${NC}"
echo ""

# Helper functions
prompt() {
  local prompt="$1"
  local default="$2"
  local val
  if [ -n "$default" ]; then
    read -p "$(echo -e "${YELLOW}${prompt}${NC} [$default] ")" val
  else
    read -p "$(echo -e "${YELLOW}${prompt}${NC} ")" val
  fi
  echo "${val:-$default}"
}

choose() {
  local prompt="$1"
  shift
  local options=("$@")
  local default=""
  echo -e "${YELLOW}$prompt${NC}"
  for i in "${!options[@]}"; do
    if [ "$i" -eq 0 ]; then
      echo "  [$((i+1))] ${options[$i]} ${GREEN}(default)${NC}"
      default="${options[$i]}"
    else
      echo "  [$((i+1))] ${options[$i]}"
    fi
  done
  local val
  read -p "Enter number (1-${#options[@]}): " val
  if [ -z "$val" ]; then echo "$default"; return; fi
  if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge 1 ] && [ "$val" -le "${#options[@]}" ]; then
    echo "${options[$((val-1))]}"
  else
    echo "$default"
  fi
}

confirm() {
  local prompt="$1"
  local default="${2:-true}"
  local yn
  if [ "$default" = true ]; then
    read -p "$(echo -e "${YELLOW}${prompt}${NC} (Y/n) ")" yn
  else
    read -p "$(echo -e "${YELLOW}${prompt}${NC} (y/N) ")" yn
  fi
  if [ -z "$yn" ]; then echo "$default"; return; fi
  case "$yn" in
    [Yy]*) echo true ;;
    *) echo false ;;
  esac
}

render_template() {
  local content="$1"
  shift
  local result="$content"
  
  # Replace {{VAR}} placeholders
  while [ $# -gt 0 ]; do
    local key="${1#--}"
    local val="$2"
    result="${result//\{\{$key\}\}/$val}"
    shift 2
  done
  
  echo "$result"
}

# ====== COLLECT CONFIG ======
echo -e "${BOLD}PROJECT INFORMATION${NC}"
PROJ_NAME=$(prompt "Project name" "MyApp")
PROJ_DESC=$(prompt "Project description" "A web application")

echo -e "${BOLD}TECH STACK${NC}"
STACK_FRONTEND=$(choose "Frontend framework" "Next.js 15+" "React + Vite" "Nuxt.js" "SvelteKit" "Remix" "Other")
STACK_DATABASE=$(choose "Database" "Supabase Postgres" "Firebase Firestore" "MongoDB" "PostgreSQL (direct)" "None / SQLite" "Other")
STACK_AUTH=$(choose "Authentication" "Supabase Auth" "Firebase Auth" "Clerk" "Auth0" "NextAuth.js" "Custom / None")

HAS_AI=$(confirm "Does your app use AI/LLM features?" false)
STACK_AI="None"
if [ "$HAS_AI" = true ]; then
  STACK_AI=$(choose "AI provider" "Gemini API" "OpenAI API" "Anthropic Claude" "Hugging Face" "Custom / Local")
fi

STACK_DEPLOY=$(choose "Deploy platform" "Vercel" "Netlify" "Fly.io" "Railway" "Cloudflare Pages" "Self-hosted")
STACK_E2E=$(choose "E2E test framework" "Playwright" "Cypress" "None")

HAS_ANALYTICS=$(confirm "Set up error tracking / analytics?" true)
STACK_ANALYTICS="None"
if [ "$HAS_ANALYTICS" = true ]; then
  STACK_ANALYTICS=$(choose "Error tracking" "Sentry" "LogRocket" "Datadog" "PostHog" "Custom")
fi

# Map database to storage
if [[ "$STACK_DATABASE" == Supabase* ]]; then
  STACK_STORAGE="Supabase Storage"
elif [[ "$STACK_DATABASE" == Firebase* ]]; then
  STACK_STORAGE="Firebase Storage"
else
  STACK_STORAGE="Cloud storage (S3, etc.)"
fi

echo -e "${BOLD}CI/CD CONFIGURATION${NC}"
NODE_VERSION=$(prompt "Node.js version" "20")
PKG_MANAGER=$(choose "Package manager" "npm" "pnpm" "yarn")
BUILD_CMD=$(prompt "Build command" "$PKG_MANAGER run build")
TEST_CMD=$(prompt "Test command" "$PKG_MANAGER test")

echo -e "${BOLD}GITHUB CONFIGURATION${NC}"
GH_OWNER=$(prompt "GitHub username/organization" "your-username")
GH_REPO=$(prompt "GitHub repository name" "$(echo "$PROJ_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')")

# ====== GENERATE FILES ======
echo ""
echo -e "${BOLD}Generating pipeline files...${NC}"

declare -A VARS
VARS[PROJECT_NAME]="$PROJ_NAME"
VARS[PROJECT_DESCRIPTION]="$PROJ_DESC"
VARS[DATE]="$(date +%Y-%m-%d)"
VARS[STACK_FRONTEND]="$STACK_FRONTEND"
VARS[STACK_DATABASE]="$STACK_DATABASE"
VARS[STACK_AUTH]="$STACK_AUTH"
VARS[STACK_AI]="$STACK_AI"
VARS[STACK_DEPLOY]="$STACK_DEPLOY"
VARS[STACK_STORAGE]="$STACK_STORAGE"
VARS[STACK_E2E]="$STACK_E2E"
VARS[STACK_ANALYTICS]="$STACK_ANALYTICS"
VARS[NODE_VERSION]="$NODE_VERSION"
VARS[BUILD_COMMAND]="$BUILD_CMD"
VARS[TEST_COMMAND]="$TEST_CMD"
VARS[LINT_COMMAND]="$PKG_MANAGER run lint"
VARS[TYPECHECK_COMMAND]="npx tsc --noEmit"
VARS[PACKAGE_MANAGER]="$PKG_MANAGER"
VARS[GITHUB_OWNER]="$GH_OWNER"
VARS[GITHUB_REPO]="$GH_REPO"

GENERATED=0
SKIPPED=0

copy_and_render() {
  local src="$1"
  local dst="$2"
  
  if [ -f "$dst" ]; then
    echo -e "  ${YELLOW}SKIP${NC}: $dst (exists)"
    SKIPPED=$((SKIPPED+1))
    return
  fi
  
  mkdir -p "$(dirname "$dst")"
  
  local content
  content=$(<"$src")
  
  # Replace all {{VAR}} placeholders
  for key in "${!VARS[@]}"; do
    content="${content//\{\{$key\}\}/${VARS[$key]}}"
  done
  
  echo "$content" > "$dst"
  echo -e "  ${GREEN}CREATE${NC}: $dst"
  GENERATED=$((GENERATED+1))
}

copy_and_render "$TEMPLATE_DIR/docs/AGENTS.md" "AGENTS.md"
copy_and_render "$TEMPLATE_DIR/docs/ROADMAP.md" "ROADMAP.md"
copy_and_render "$TEMPLATE_DIR/docs/BUGS.md" "BUGS.md"
copy_and_render "$TEMPLATE_DIR/docs/LAST_SESSION.md" "LAST_SESSION.md"
copy_and_render "$TEMPLATE_DIR/agents/co-developer.md" ".opencode/agents/co-developer.md"
copy_and_render "$TEMPLATE_DIR/agents/planner.md" ".opencode/agents/planner.md"
copy_and_render "$TEMPLATE_DIR/agents/security-reviewer.md" ".opencode/agents/security-reviewer.md"
copy_and_render "$TEMPLATE_DIR/agents/monitor.md" ".opencode/agents/monitor.md"
copy_and_render "$TEMPLATE_DIR/github/dependabot.yml" ".github/dependabot.yml"
copy_and_render "$TEMPLATE_DIR/github/workflows/ci.yml" ".github/workflows/ci.yml"
copy_and_render "$TEMPLATE_DIR/github/workflows/codeql.yml" ".github/workflows/codeql.yml"
copy_and_render "$TEMPLATE_DIR/github/workflows/playwright.yml" ".github/workflows/playwright.yml"
copy_and_render "$TEMPLATE_DIR/husky/pre-commit" ".husky/pre-commit"

# Generate pipeline.json
cat > "pipeline.json" << EOF
{
  "project": {
    "name": "$PROJ_NAME",
    "description": "$PROJ_DESC"
  },
  "stack": {
    "frontend": "$STACK_FRONTEND",
    "database": "$STACK_DATABASE",
    "auth": "$STACK_AUTH",
    "ai": "$STACK_AI",
    "deploy": "$STACK_DEPLOY",
    "storage": "$STACK_STORAGE",
    "e2e": "$STACK_E2E",
    "analytics": "$STACK_ANALYTICS"
  },
  "ci": {
    "nodeVersion": "$NODE_VERSION",
    "buildCommand": "$BUILD_CMD",
    "testCommand": "$TEST_CMD",
    "lintCommand": "$PKG_MANAGER run lint",
    "typecheckCommand": "npx tsc --noEmit",
    "packageManager": "$PKG_MANAGER"
  },
  "github": {
    "owner": "$GH_OWNER",
    "repo": "$GH_REPO"
  },
  "version": "1.0.0"
}
EOF
echo -e "  ${GREEN}CREATE${NC}: pipeline.json"
GENERATED=$((GENERATED+1))

# Set up Husky
if command -v npx &> /dev/null; then
  if [ ! -d ".husky" ]; then
    echo ""
    echo "Initializing Husky..."
    npx husky init
  fi
  chmod +x .husky/pre-commit 2>/dev/null || true
  echo -e "  ${GREEN}OK${NC}: Pre-commit hooks ready"
fi

# ====== SUMMARY ======
echo ""
echo -e "${BOLD}${GREEN}SETUP COMPLETE${NC}"
echo -e "  Generated ${GENERATED} files for ${BOLD}${PROJ_NAME}${NC}"
if [ $SKIPPED -gt 0 ]; then
  echo -e "  ${YELLOW}${SKIPPED} files skipped (use -f to overwrite)${NC}"
fi
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Install deps:   npm install --save-dev husky lint-staged prettier"
echo "  2. Init Husky:     npx husky init"
echo "  3. Push to GitHub: git push origin main"
echo "  4. Add GitHub Secrets in Settings > Secrets > Actions"
echo "  5. Start building: Say 'plan: <feature>' to the Planner Agent"
echo ""
echo -e "${BOLD}Remember:${NC}"
echo "  - Run 'review security' before pushing to catch issues early"
echo "  - Run 'check errors' at session start for automated health check"
echo "  - All agent files read pipeline.json to adapt to YOUR stack"
EOF

echo "Created setup.sh"