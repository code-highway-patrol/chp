# CHP - Code Highway Patrol

Define and enforce code laws in your Claude Code projects. CHP uses regex-based rules with self-improving exclusion patterns to catch violations and guide code generation.

## How It Works

1. Define laws in `laws/chp-laws.txt` — simple regex rules with intent and reaction types
2. CHP checks generated code against your laws
3. If a violation is found, it adds an exclusion and regenerates (up to 3 attempts)
4. If all attempts fail, you're notified to adjust the law

## Installation

Add CHP as a Claude Code plugin. The `laws/chp-laws.txt` file and skills are all you need.

## Law Format

```
# === Law: no-api-keys ===
intent: No hardcoded API keys in source code
violation: (api[_-]?key|apikey)\s*[=:]\s*['"][A-Za-z0-9]{20,}['"]
reaction: block
```

| Field | Purpose |
|-------|---------|
| `intent` | What the law protects against |
| `violation` | Regex matching bad code |
| `exclusion` | Optional regex for false positives (can have multiple) |
| `reaction` | `block`, `warn`, or `auto_fix` |

## Skills

| Skill | Purpose |
|-------|---------|
| `chp:scan-repo` | Scan codebase for violations |
| `chp:write-laws` | Create new laws |
| `chp:refine-laws` | Adjust existing laws |
| `chp:onboard` | Understand project guardrails |

## Project Structure

```
chp/
├── .claude-plugin/plugin.json   # Plugin manifest
├── skills/                      # Skill definitions
│   ├── scan-repo/skill.md
│   ├── write-laws/skill.md
│   ├── refine-laws/skill.md
│   └── onboard/skill.md
├── laws/chp-laws.txt            # Your law definitions
├── CLAUDE.md                    # Project context
└── README.md
```

## License

MIT
