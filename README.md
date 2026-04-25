# CHP - Code Highway Patrol

A hybrid code law enforcement plugin for Claude Code. Deterministic laws are checked automatically via regex. Subjective laws are reviewed by an AI agent. All violations are collected into a clean HTML report.

## Installation

### Install from the Claude Marketplace

```bash
claude install chp
```

That's it. CHP is now active in your project.

### Verify it's working

Start a Claude Code session. On the first tool use you should see:

```
CHP: ensuring dashboard is running...
```

After any file write or edit:

```
CHP: running deterministic checks...
CHP: agent reviewing subjective laws...
```

The dashboard opens automatically at **http://localhost:5177**.

## Quick Start

### Define your laws

Edit `laws/chp-laws.txt` (or use the `chp:write-laws` skill) to add rules:

```
# === Law: no-console-log ===
intent: No console.log statements in production code
check: console\.log\(
reaction: block

# === Law: no-hardcoded-secrets ===
intent: No hardcoded API keys, passwords, tokens, or secrets
reaction: block
```

- Laws with `check:` are **deterministic** — detected by regex, tagged AUTO in reports. Fast, zero inference cost.
- Laws without `check:` are **subjective** — reviewed by an AI agent, tagged REVIEW in reports. Catches what regex can't.

### Run a full scan

Use the `chp:scan-repo` skill to scan every file in the codebase and generate an HTML report at `.chp/report.html`.

### Use skills

| Skill | What it does |
|-------|-------------|
| `chp:scan-repo` | Full codebase scan with HTML report |
| `chp:write-laws` | Create a new law (auto-classifies as deterministic or subjective) |
| `chp:refine-laws` | Edit, delete, or tune existing laws |
| `chp:dashboard` | Launch the web dashboard |
| `chp:onboard` | Explain the project's guardrails to a new contributor |

## How It Works

1. **Define** laws in `laws/chp-laws.txt` — each has an intent, optional regex, and a reaction level
2. **On every file write/edit**, two PostToolUse hooks fire:
   - **Deterministic hook** (`bin/chp-check`) — scans the changed file against all `check:` regex patterns
   - **Agent hook** — a subagent reviews the file against all subjective law intents
3. **Violations** are written to `.chp/report.json` and surfaced in the session
4. **Laws as context** — `CLAUDE.md` inlines the active laws so the agent avoids violations at authoring time, not just post-hoc
5. **Dashboard** at `http://localhost:5177` — view laws, trigger scans, browse reports

### Prevention vs. Detection

CHP works on two levels:

- **Prevention**: The laws are embedded in `CLAUDE.md`, which Claude Code reads before writing any code. The agent knows the rules and avoids violations proactively.
- **Detection**: Hooks run after every write to catch anything that slipped through — regex for deterministic laws, agent judgment for subjective ones.

## Law Format

```
# === Law: <id> ===
intent: <plain-language description of what's banned and why>
check: <optional regex pattern — if present, law is deterministic>
reaction: block|warn
```

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique, lowercase kebab-case identifier |
| `intent` | Yes | What the law enforces, in plain language |
| `check` | No | Regex pattern for automatic detection. Omit for subjective laws. |
| `reaction` | Yes | `block` (must fix) or `warn` (flag but allow) |

## Plugin Structure

```
chp/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace listing
├── hooks/
│   └── hooks.json               # PreToolUse + PostToolUse hooks
├── bin/
│   ├── chp-check                # Deterministic regex scanner (PostToolUse)
│   ├── chp-context              # Injects laws into agent context (PreToolUse)
│   ├── chp-server               # Dashboard web server (port 5177)
│   ├── chp-dashboard            # Ensures server is running
│   └── chp-report               # HTML report generator
├── skills/
│   ├── dashboard/               # Launch the web UI
│   ├── scan-repo/               # Full codebase scan
│   ├── write-laws/              # Create new laws
│   ├── refine-laws/             # Edit/delete laws
│   └── onboard/                 # Explain guardrails
├── laws/
│   └── chp-laws.txt             # Law definitions (your rules go here)
├── .chp/                        # Runtime output (gitignored)
│   ├── report.json              # Violation data
│   └── report.html              # Static HTML report
├── CLAUDE.md                    # Agent context — inlines active laws
└── README.md
```

## Requirements

- **Python 3.8+** (for `chp-check`, `chp-server`, `chp-report`, `chp-dashboard`)
- **Claude Code** (the CLI agent that supports plugins, hooks, and skills)

No additional Python packages are required — all scripts use the standard library.

## License

MIT
