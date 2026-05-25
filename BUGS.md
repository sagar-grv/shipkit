# ShipKit — Known Bugs & Issues

**Status:** No known bugs.

## Resolved in v3.0.4
- [x] CI validate.yml checks 8 removed template files — always fails
- [x] actions/checkout@v4 uses deprecated Node.js 20
- [x] setup.sh references removed templates (agents/*, playwright.yml, etc.)
- [x] setup.sh no git platform detection (always GitHub)
- [x] setup.sh hardcoded scripts instead of reading package.json
- [x] setup.ps1 same issues as setup.sh
- [x] README.md entirely v2-based (incorrect commands, files, project structure)
- [x] ROADMAP.md, BUGS.md, CHANGELOG.md, LAST_SESSION.md out of sync
- [x] package.json test script only runs --help + --version
- [x] .gitattributes duplicate *.json text entry

## To Verify
- [ ] setup.sh on Ubuntu (no Linux/macOS available for testing)
- [ ] GitLab/Bitbucket platform detection
