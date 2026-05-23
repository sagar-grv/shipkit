# ShipKit — Known Bugs & Issues

**Status:** No known bugs at this time.

## Resolved in v2.0.1
- ~~`setup.ps1` here-string parser crash (PowerShell 5.1)~~
- ~~`Test-Path -or` syntax error~~
- ~~UTF-8 arrow character corruption~~
- ~~`setup.sh` shell injection risk in Render template~~
- ~~`setup.sh` missing fields in shipkit.json~~
- ~~GitHub Actions CodeQL `@v3` deprecation~~
- ~~Template file count gaps in validate.yml~~

## To Verify
- [ ] `setup.sh` on Ubuntu (no Linux/macOS available for testing)
- [ ] `npm publish` payload (dry-run passed, real publish untested)
- [ ] GitHub Pages with custom domain (DNS not configured yet)
