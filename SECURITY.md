# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in ShipKit, please do NOT open a public issue.

Instead, report it privately via GitHub's security advisory system:

https://github.com/sagar-grv/shipkit/security/advisories/new

You can also email `hello@sagargiri.com`. We aim to respond within 48 hours.

## What to expect

- Acknowledgment within 2 business days
- Regular updates on progress
- Coordinated disclosure once fixed

## Scope

This policy covers the `shipkit-pipe` npm package, its source code, and the generated CI/CD templates.

Out of scope:
- Projects that use ShipKit-generated templates (report those to the project maintainer)
- Third-party dependencies (report to their respective maintainers)

## Security features

ShipKit generated pipelines include:

- **CodeQL scanning**: Automatic security analysis on every PR and push
- **Supply chain security**: `npm audit` runs in CI to catch dependency vulnerabilities
- **Dependabot**: Weekly automated dependency update PRs
- **Health monitoring**: Periodic uptime checks with automatic issue creation

## Supported versions

| Version | Supported |
|---------|-----------|
| 3.x     | ✅        |
| < 3.0   | ❌        |
