# ShipKit Roadmap — v3

## [v3.0.4] — Current
- [x] Fix CI: validate.yml checks current template files (not removed ones)
- [x] Upgrade actions/checkout from @v4 to @v5 (Node.js 20 deprecation)
- [x] Rewrite setup.sh for v3: platform detection, dynamic scripts, single AGENTS.md, --dry-run
- [x] Rewrite setup.ps1 for v3: same improvements
- [x] Update README.md to v3 (remove all v2 references)
- [x] Update ROADMAP.md, BUGS.md, CHANGELOG.md, LAST_SESSION.md
- [x] Fix package.json test script, .gitattributes duplicate, landing page

## [v3.1.0] — Next
- [ ] **Curl install method**: `curl -fsSL https://shipkit.dev/install.sh | bash` for users without Node.js
- [ ] **--force flag**: overwrite existing files
- [ ] **shipkit.json validation**: `npx shipkit-pipe check` validates shipkit.json
- [ ] **Python CLI**: `pip install shipkit-pipe`

## [v3.2.0] — Future
- [ ] VS Code extension (one-click ShipKit)
- [ ] Docker image for CI-less environments
- [ ] Community template marketplace
