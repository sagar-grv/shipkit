#!/usr/bin/env bash
# ShipKit — Your Automated Dev Team
# Usage:
#   bash setup.sh              Auto-detect & generate (no prompts)
#   bash setup.sh -i           Interactive mode (asks questions)
#   bash setup.sh --dry-run    Preview without writing files
#   bash setup.sh --help       Show help

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

INTERACTIVE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interactive) INTERACTIVE=true; shift ;;
    --dry-run|--preview) DRY_RUN=true; shift ;;
    --help|-h) echo "Usage: bash setup.sh [-i] [--dry-run]"; echo "  -i, --interactive  Ask questions instead of auto-detect"; echo "  --dry-run          Preview without writing files"; exit 0 ;;
    *) echo "Usage: bash setup.sh [-i] [--dry-run]"; exit 1 ;;
  esac
done

# Check Node.js
if ! command -v node &>/dev/null; then
  echo -e "${RED}Node.js is required.${NC} Install: ${CYAN}https://nodejs.org${NC}"; exit 1
fi

# ─── Detect ──────────────────────────────────────────────────────────────────
detect() {
  local n d f pm gr gp gh_owner gh_repo nv has_lint has_test has_build has_typecheck is_mono subs

  # Read package.json if exists
  if [ -f "package.json" ]; then
    n=$(node -e "try{console.log(require('./package.json').name||'')}catch(e){}" 2>/dev/null || true)
    d=$(node -e "try{console.log(require('./package.json').description||'')}catch(e){}" 2>/dev/null || true)

    # Framework detection
    node -e "try{require('next/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Next.js"
    [ -z "$f" ] && node -e "try{require('nuxt/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Nuxt"
    [ -z "$f" ] && node -e "try{require('astro/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Astro"
    [ -z "$f" ] && node -e "try{require('react/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="React"
    [ -z "$f" ] && node -e "try{require('vue/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Vue"
    [ -z "$f" ] && node -e "try{require('svelte/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Svelte"
    [ -z "$f" ] && node -e "try{require('express/package.json');process.exit(0)}catch(e){process.exit(1)}" 2>/dev/null && f="Express"

    # Scripts detection
    has_lint=$(node -e "try{const p=require('./package.json');process.exit(p.scripts&&p.scripts.lint?0:1)}catch(e){process.exit(1)}" 2>/dev/null && echo "true" || echo "false")
    has_test=$(node -e "try{const p=require('./package.json');process.exit(p.scripts&&(p.scripts.test||p.scripts.test)?0:1)}catch(e){process.exit(1)}" 2>/dev/null && echo "true" || echo "false")
    has_build=$(node -e "try{const p=require('./package.json');process.exit(p.scripts&&p.scripts.build?0:1)}catch(e){process.exit(1)}" 2>/dev/null && echo "true" || echo "false")
    has_typecheck=$(node -e "try{const p=require('./package.json');process.exit(p.scripts&&(p.scripts.typecheck||p.scripts['type-check']||p.scripts['tsc'])?0:1)}catch(e){process.exit(1)}" 2>/dev/null && echo "true" || echo "false")

    # Node version
    if [ -f ".nvmrc" ]; then nv=$(cat .nvmrc | tr -d 'v\n'); fi
    if [ -z "$nv" ] && [ -f ".node-version" ]; then nv=$(cat .node-version | tr -d 'v\n'); fi
    if [ -z "$nv" ]; then nv=$(node -e "try{const p=require('./package.json');const m=(p.engines&&p.engines.node||'').match(/(\\d+)/);console.log(m?m[1]:'')}catch(e){}" 2>/dev/null || true); fi
    [ -z "$nv" ] && nv="20"

    # Monorepo check
    if [ ! -f "package.json" ] || [ -z "$n" ] || [ -z "$(node -e "try{const p=require('./package.json');console.log(p.scripts?Object.keys(p.scripts).length:0)}catch(e){console.log(0)}" 2>/dev/null)" ]; then
      is_mono="true"
      for dir in frontend backend web app api server client; do
        [ -f "$dir/package.json" ] && subs="$subs $dir"
      done
      subs=$(echo "$subs" | xargs)
    fi
  else
    # No package.json — check for other project types
    [ -f "pyproject.toml" ] && f="Python"
    [ -f "go.mod" ] && f="Go"
    [ -f "Cargo.toml" ] && f="Rust"
    [ -f "docker-compose.yml" ] && f="Docker"
    # Monorepo check — look for subdirectories with package.json
    is_mono="true"
    for dir in frontend backend web app api server client; do
      [ -f "$dir/package.json" ] && subs="$subs $dir"
    done
    subs=$(echo "$subs" | xargs)
  fi

  # Package manager
  if [ -f "pnpm-lock.yaml" ]; then pm="pnpm"
  elif [ -f "yarn.lock" ]; then pm="yarn"
  elif [ -f "bun.lockb" ]; then pm="bun"
  else pm="npm"
  fi

  # Git
  if [ -d ".git" ]; then
    gr=$(git config --get remote.origin.url 2>/dev/null || true)
    if [ -n "$gr" ]; then
      gh_owner=$(echo "$gr" | sed -E 's/.*[:/]([^/]+)\/.*/\1/')
      gh_repo=$(echo "$gr" | sed -E 's/.*[:/][^/]+\/([^/.]+)(\.git)?$/\1/')
      if echo "$gr" | grep -qi "gitlab"; then gp="gitlab"
      elif echo "$gr" | grep -qi "bitbucket"; then gp="bitbucket"
      else gp="github"
      fi
    fi
  fi
  [ -z "$gp" ] && gp="github"

  # Deploy URL
  local deploy_url=""
  [ -f "vercel.json" ] && deploy_url="https://${gh_repo}.vercel.app"
  [ -z "$deploy_url" ] && [ -f "fly.toml" ] && deploy_url=$(grep -E '^app\s*=' fly.toml 2>/dev/null | sed -E 's/.*=\s*"([^"]+)".*/https:\/\/\1.fly.dev/')

  echo "{\"name\":\"$n\",\"desc\":\"$d\",\"frontend\":\"$f\",\"pm\":\"$pm\",\"gitRemote\":\"$gr\",\"gitPlatform\":\"$gp\",\"ghOwner\":\"$gh_owner\",\"ghRepo\":\"$gh_repo\",\"nodeVer\":\"$nv\",\"hasLint\":$has_lint,\"hasTest\":$has_test,\"hasBuild\":$has_build,\"hasTypecheck\":$has_typecheck,\"isMonorepo\":$is_mono,\"subProjects\":\"$subs\",\"deployUrl\":\"$deploy_url\"}"
}

DETECTED=$(detect)

get_val() { echo "$DETECTED" | node -e "process.stdin.on('data',d=>{try{console.log(JSON.parse(d)['$1']||'')}catch(e){console.log('')}})" 2>/dev/null; }

NAME=$(get_val "name")
DESC=$(get_val "desc")
FRONTEND=$(get_val "frontend")
PM=$(get_val "pm")
GIT_PLATFORM=$(get_val "gitPlatform")
GH_OWNER=$(get_val "ghOwner")
GH_REPO=$(get_val "ghRepo")
NODE_VER=$(get_val "nodeVer")
HAS_LINT=$(get_val "hasLint")
HAS_TEST=$(get_val "hasTest")
HAS_BUILD=$(get_val "hasBuild")
HAS_TYPECHECK=$(get_val "hasTypecheck")
IS_MONO=$(get_val "isMonorepo")
SUBS=$(get_val "subProjects")
DEPLOY_URL=$(get_val "deployUrl")

[ -z "$NAME" ] && NAME=$(basename "$(pwd)")
[ -z "$DESC" ] && DESC="A web application"

# ─── Interactive mode ────────────────────────────────────────────────────────
if $INTERACTIVE; then
  echo -e "\n  ${BOLD}${CYAN}⚓ ShipKit${NC} — interactive setup\n"
  read -r -p "  Project name [$NAME]: " INPUT
  NAME="${INPUT:-$NAME}"
  read -r -p "  Description [$DESC]: " INPUT
  DESC="${INPUT:-$DESC}"
  read -r -p "  GitHub owner [$GH_OWNER]: " INPUT
  GH_OWNER="${INPUT:-$GH_OWNER}"
  read -r -p "  GitHub repo [$GH_REPO]: " INPUT
  GH_REPO="${INPUT:-$GH_REPO}"
fi

[ -z "$GH_OWNER" ] && GH_OWNER="your-username"
[ -z "$GH_REPO" ] && GH_REPO=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')

# ─── Render t̀emplate ─────────────────────────────────────────────────────────

TEMPLATE_DIR="$(dirname "$0")/template"
RENDERER="$(dirname "$0")/template/render.js"

export SK_PROJECT_NAME="$NAME"
export SK_PROJECT_DESCRIPTION="$DESC"
export SK_NODE_VERSION="$NODE_VER"
export SK_PACKAGE_MANAGER="$PM"
export SK_GITHUB_OWNER="$GH_OWNER"
export SK_GITHUB_REPO="$GH_REPO"
export SK_GIT_PLATFORM="$GIT_PLATFORM"
export SK_DEPLOY_URL="$DEPLOY_URL"
export SK_HAS_LINT="$HAS_LINT"
export SK_HAS_TEST="$HAS_TEST"
export SK_HAS_BUILD="$HAS_BUILD"
export SK_HAS_TYPECHECK="$HAS_TYPECHECK"
export SK_IS_MONOREPO="$IS_MONO"
export SK_SUB_PROJECTS="$SUBS"
export SK_FRONTEND="$FRONTEND"
export SK_DATE="$(date +%Y-%m-%d)"

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
  $DRY_RUN && { echo "  would write: $dst"; GEN=$((GEN+1)); return; }
  render "$tmpl" "$dst" && GEN=$((GEN+1))
}

# Generate platform-specific CI
case "$GIT_PLATFORM" in
  gitlab)
    write "gitlab/gitlab-ci.yml" ".gitlab-ci.yml"
    ;;
  bitbucket)
    write "bitbucket/bitbucket-pipelines.yml" "bitbucket-pipelines.yml"
    ;;
  *)
    # GitHub (default)
    write "github/workflows/ci.yml" ".github/workflows/ci.yml"
    write "github/dependabot.yml" ".github/dependabot.yml"
    write "github/workflows/codeql.yml" ".github/workflows/codeql.yml"
    if [ -n "$DEPLOY_URL" ]; then
      write "github/workflows/health.yml" ".github/workflows/health.yml"
    fi
    ;;
esac

# Common files (all platforms)
write "docs/AGENTS.md" "AGENTS.md"
write "docs/LAST_SESSION.md" "LAST_SESSION.md"

# shipkit.json
SHIPKIT_JSON="shipkit.json"
if [ ! -f "$SHIPKIT_JSON" ]; then
  if $DRY_RUN; then
    echo "  would write: shipkit.json"
    GEN=$((GEN+1))
  else
    cat > "$SHIPKIT_JSON" << JSONEOF
{
  "project": { "name": "$NAME", "description": "$DESC" },
  "ci": { "nodeVersion": "$NODE_VER", "packageManager": "$PM" },
  "github": { "owner": "$GH_OWNER", "repo": "$GH_REPO", "platform": "$GIT_PLATFORM" },
  "deploy": { "url": "$DEPLOY_URL" },
  "version": "3.0.4"
}
JSONEOF
    GEN=$((GEN+1))
  fi
fi

$DRY_RUN && echo -e "\n  ${YELLOW}Dry run — no files written. Run without --dry-run to generate.${NC}" && exit 0

echo -e "\n  ${GREEN}✓ Generated $GEN files${NC}$([ $SKIP -gt 0 ] && echo " (${YELLOW}$SKIP already exist${NC})")\n"