# CHP - Code Highway Patrol

A hybrid code law enforcement plugin for Claude Code. Deterministic laws are checked automatically via regex. Subjective laws are reviewed by an AI agent. All violations are collected into a report.

## Installation

### Option A: Install from a GitHub marketplace

If CHP is hosted in a GitHub repository (e.g. `your-org/chp`):

```shell
# 1. Add the marketplace
/plugin marketplace add your-org/chp

# 2. Install the plugin
/plugin install chp@your-org-chp
```

Or from the CLI outside a session:

```bash
claude plugin install chp@your-org-chp
```

### Option B: Install from a local directory

If you have the CHP source locally:

```shell
# 1. Add the local marketplace
/plugin marketplace add ./path/to/chp

# 2. Install the plugin
/plugin install chp@chp-marketplace
```

### Option C: Test during development

Load the plugin directly without installing:

```bash
claude --plugin-dir ./path/to/chp
```

### Choose an installation scope

By default, plugins install to **user scope** (available in all your projects). You can also install to:

- **Project scope** — shared with all collaborators via `.claude/settings.json`:
  ```shell
  /plugin install chp@your-org-chp --scope project
  ```
- **Local scope** — just for you in this repo (gitignored):
  ```shell
  /plugin install chp@your-org-chp --scope local
  ```

### Verify it's working

Start a Claude Code session. On the first tool use you should see:

```
CHP: loading active laws...
```

After the write:

```
CHP: running deterministic checks...
CHP: agent reviewing subjective laws...
```

Before **any** tool use (Read, Bash, Write, Edit, etc.), active laws are injected into the agent's context.

### Set up laws for your project

CHP looks for laws at `laws/chp-laws.txt` in your project root. Create this file manually or use the `chp:write-laws` skill to add laws interactively. See **Law Format** below.

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
| `chp:onboard` | Explain the project's guardrails to a new contributor |
| `chp:setup` | Configure real-time law enforcement hook |

## How It Works

1. **Define** laws in `laws/chp-laws.txt` — each has an intent, optional regex, and a reaction level
2. **Before every tool use**, a PreToolUse hook fires:
   - **Context injection** (`bin/chp-context`) — reads all laws and injects them into the agent's context as `additionalContext`, so the agent sees the rules before Read, Bash, Write, Edit, and every other tool
3. **After every file write/edit**, two PostToolUse hooks fire:
   - **Deterministic hook** (`bin/chp-check`) — scans the changed file against all `check:` regex patterns
   - **Agent hook** — a subagent reviews the file against all subjective law intents
4. **Violations** are written to `.chp/report.json` and surfaced in the session

### Prevention vs. Detection

CHP works on two levels:

- **Prevention**: A PreToolUse hook (`bin/chp-context`) injects all active laws before **every** tool call. If the model answers with text only and no tools, no hook runs (Claude Code does not expose a hook for that).
- **Detection**: PostToolUse hooks run after every write to catch anything that slipped through — regex for deterministic laws, agent judgment for subjective ones.

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
│   └── chp-context              # Injects laws into agent context (PreToolUse)
├── skills/
│   ├── scan-repo/               # Full codebase scan
│   ├── write-laws/              # Create new laws
│   ├── refine-laws/             # Edit/delete laws
│   ├── onboard/                 # Explain guardrails
│   └── setup/                   # Configure real-time enforcement hook
├── laws/
│   └── chp-laws.txt             # Law definitions (your rules go here)
├── .chp/                        # Runtime output (gitignored)
│   └── report.json              # Violation data
├── CLAUDE.md                    # Context for developing CHP itself
└── README.md
```

## Requirements

- **Python 3.8+** (for `chp-check` and `chp-context`)
- **Claude Code** (the CLI agent that supports plugins, hooks, and skills)

No additional Python packages are required — all scripts use the standard library.

## License

MIT