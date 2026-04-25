# CHP - Code Highway Patrol

A hybrid code law enforcement plugin for Claude Code. Deterministic laws are checked automatically via regex. Subjective laws are reviewed by an AI agent. All violations are collected into a clean HTML report.

## How It Works

1. Define laws in `laws/chp-laws.txt` with an intent and optional `check:` regex
2. After every file write, two hooks fire in parallel:
   - **Deterministic hook**: runs a script that greps for `check:` patterns — fast, zero inference cost
   - **Agent hook**: a subagent reviews code against subjective law intents — catches what regex can't
3. Violations are flagged (not auto-fixed) and written to `.chp/report.json`
4. Run `/chp:scan-repo` for a full codebase scan and HTML dashboard

## Law Format

```
# === Law: no-console-log ===
intent: No console.log statements in production code
check: console\.log\(
reaction: block

# === Law: no-hardcoded-secrets ===
intent: No hardcoded API keys, passwords, tokens, or secrets
reaction: block
```

- Laws with `check:` are **deterministic** — detected by regex, tagged AUTO in reports
- Laws without `check:` are **subjective** — reviewed by agent, tagged REVIEW in reports

## Skills

| Skill | Purpose |
|-------|---------|
| `chp:scan-repo` | Full scan with HTML report at `.chp/report.html` |
| `chp:write-laws` | Create new laws |
| `chp:refine-laws` | Adjust existing laws |
| `chp:onboard` | Understand project guardrails |

## Plugin Structure

```
chp/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace listing
├── hooks/hooks.json             # Dual PostToolUse hooks
├── bin/
│   ├── chp-check                # Deterministic enforcement script
│   └── chp-report               # HTML report generator
├── skills/                      # Skill definitions
├── laws/chp-laws.txt            # Example law definitions
├── CLAUDE.md
└── README.md
```

## License

MIT
