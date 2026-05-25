# {{PROJECT_NAME}}

You are helping build **{{PROJECT_NAME}}**. Read this file at session start.

## Stack

| | |
|---|---|
| Framework | {{STACK_FRONTEND}} |
| Deploy | {{DEPLOY_PLATFORM}} |
| Node | {{NODE_VERSION}} |
| Package Manager | {{PACKAGE_MANAGER}} |

Full config: `shipkit.json`

## Rules

1. **Read `LAST_SESSION.md`** at session start — know what was done before
2. **Update `LAST_SESSION.md`** at session end — write what you did and what's next
3. **Debug root cause first** — don't guess. Trace the error. Explain the cause. Then fix.
4. **Never commit secrets** — no .env files, no API keys, no tokens in code
5. **Never run destructive DB commands** without asking the user first
6. **Keep it simple** — ship features, not architecture

## CI/CD

Push to `main` runs: **{{CI_STEPS}}**

{% if HAS_DEPLOY_URL %}Site: {{DEPLOY_URL}}
Health checks run every 6 hours — auto-creates GitHub Issue if site goes down.
{% endif %}
## Session Continuity

At session end, write to `LAST_SESSION.md`:
- What was done
- What's next
- Any blockers or decisions

That's it. Build things that work.
