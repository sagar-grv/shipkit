# ShipKit Roadmap

## [v2.0.1] — ✅ Shipped (2026-05-25)
- [x] npm publish: `shipkit-pipe@2.0.0` live on npm
- [x] Fix setup.ps1: here-string parser, -or syntax, encoding bugs
- [x] Fix setup.sh: `has_git` variable without `$` prefix bug
- [x] Fix setup.sh: CRLF heredoc corruption (cross-platform clones)
- [x] .gitattributes: LF line ending enforcement for all code files
- [x] GitHub Pages: landing page, og:image, .nojekyll (default URL)
- [x] npm packaging: package.json, bin/, .npmignore
- [x] CI/CD: playwright.yml, FUNDING.yml, ISSUE_TEMPLATE
- [x] **Remove Python dependency**: `template/render.js` (Node.js) replaces fragile Python heredoc
- [x] **Simplify UX**: `npx shipkit-pipe` — no subcommand, no prompts by default
- [x] **No-project guard**: clear error when run in empty directory
- [x] **`-i` / `--interactive`**: optional prompt mode instead of default
- [x] **Custom domain dropped**: Use GitHub Pages default URL (no free domain)

## [v2.1.0] — Next
- [ ] **Republish v2.0.1 to npm**: `npm version patch && npm publish`
- [ ] **Verify Ubuntu**: `git pull && bash setup.sh`
- [ ] **Post-launch analytics**: download counter badge in README
- [ ] **Homebrew tap** (optional): `brew install shipkit`

## [v2.2.0] — Future
- [ ] Python CLI (`shipkit-pipe` as pip package)
- [ ] Docker image for CI-less environments
- [ ] VS Code extension (GUI for setup)
- [ ] Community template marketplace
