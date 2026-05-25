# Contributing to ShipKit

Thanks for your interest in contributing! ShipKit is an open-source project that helps solo developers ship faster.

## Ways to contribute

- **Bug reports**: Open an issue with reproduction steps
- **Feature requests**: Describe the problem you're solving
- **Documentation**: Improve README, templates, or the landing page
- **Code**: Fix bugs, add features, improve CLI or templates
- **Templates**: Add CI templates for other platforms (Jenkins, CircleCI, etc.)

## Development setup

```bash
git clone https://github.com/sagar-grv/shipkit.git
cd shipkit
npm link   # makes `shipkit-pipe` available globally
```

## Making changes

1. Create a branch: `git checkout -b feat/your-feature`
2. Make your changes
3. Run tests: `npm test`
4. Commit: `git commit -m "feat: your change"`
5. Push: `git push -u origin feat/your-feature`
6. Open a pull request

## Code style

- Keep zero npm dependencies in `bin/shipkit-pipe.js`
- Use `'use strict'` and Node.js built-ins only
- Templates use `{{VARIABLE}}` syntax (see template/render.js)

## Adding a template

1. Add the file under `template/` (e.g., `template/github/workflows/new-thing.yml`)
2. Add it to the `files` array in `bin/shipkit-pipe.js` generate()
3. Add it to the template smoke test in `.github/workflows/validate.yml`
4. Update `template/docs/AGENTS.md` if the template affects AI agent behavior

## Testing

- `npm test` runs the CLI through its commands
- `.github/workflows/validate.yml` runs template smoke tests in CI
- Always run `npm test` before pushing

## Pull request guidelines

- Keep PRs focused — one change per PR
- Include a clear description of what and why
- Update tests if needed
- Update docs (README, template docs) if the change affects users
- Make sure CI passes
