# Security Policy

## Reporting a Vulnerability

ShipKit takes security seriously. If you discover a security vulnerability in ShipKit itself (not your project using ShipKit), please report it privately.

**Do not** report security vulnerabilities through public GitHub issues.

Instead, please email: *(coming soon)*

You should receive a response within 48 hours. If you don't, follow up to ensure your message was received.

## What to Include

- Type of issue (e.g., command injection, secret exposure)
- Full paths of source file(s) related to the issue
- Any special configuration required to reproduce
- Step-by-step instructions to reproduce
- Proof-of-concept or exploit code (if possible)
- Impact of the issue

## What ShipKit Protects

ShipKit templates include security gates at multiple levels:

| Layer | What It Guards |
|---|---|
| `security-reviewer.md` | AI-powered security review of every PR |
| `codeql.yml` | GitHub CodeQL automated vulnerability scanning |
| `husky/pre-commit` | Pre-commit hook scanning for secrets |
| `dependabot.yml` | Automated dependency vulnerability updates |

## Supported Versions

| Version | Supported |
|---|---|
| 1.x (latest) | ✅ |
| Older | ❌ |

## Bug Bounty

At this time, ShipKit does not offer a bug bounty program. We are a small open-source project. We will gratefully acknowledge security researchers in our release notes.
