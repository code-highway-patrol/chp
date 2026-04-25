# CHP - Code Highway Patrol

A self-improving code law enforcement plugin for Claude Code. Define laws as plain-language intents and CHP enforces them through subjective AI judgment — not regex. Laws get stricter over time as violations are caught.

## How It Works

1. Define laws in `laws/chp-laws.txt` in your project root
2. An agent hook fires after every file write (`PostToolUse` on `Write|Edit`)
3. A subagent reads your laws and subjectively judges whether the code violates any intent
4. If violated: the code is rewritten and the law is tightened to be more explicit
5. Laws sharpen with every violation — they evolve from general rules into precise guardrails

## Installation

```bash
claude plugin add chp
```

Then create `laws/chp-laws.txt` in your project root (or use `/chp:write-laws`).

## Law Format

```
# === Law: no-hardcoded-secrets ===
intent: No hardcoded API keys, passwords, tokens, or secrets in source code. All sensitive values must come from environment variables or a secrets manager.
reaction: block
```

| Field | Purpose |
|-------|---------|
| `intent` | Plain-language rule the agent evaluates against — be specific |
| `reaction` | `block` (must fix) or `warn` (flag but allow) |

## Skills

| Skill | Purpose |
|-------|---------|
| `chp:scan-repo` | Scan full codebase for violations |
| `chp:write-laws` | Create new laws |
| `chp:refine-laws` | Adjust existing laws |
| `chp:onboard` | Understand project guardrails |

## Plugin Structure

```
chp/
├── .claude-plugin/plugin.json   # Plugin manifest
├── hooks/hooks.json             # PostToolUse agent hook
├── skills/                      # Skill definitions
│   ├── scan-repo/skill.md
│   ├── write-laws/skill.md
│   ├── refine-laws/skill.md
│   └── onboard/skill.md
├── laws/chp-laws.txt            # Example law definitions
├── CLAUDE.md
└── README.md
```

## License

MIT
