# CHP - Code Highway Patrol

A static analysis framework for enforcing rules, standards, and best practices across your codebase.

## Overview

CHP provides a flexible, rule-based system for analyzing code and enforcing organizational standards. Think of it as a programmable linting and analysis framework that can be extended to enforce any rule or "law" your team needs.

## Features

- **Rule Engine** - Define custom rules for code quality, security, and style
- **Multi-Language Support** - Analyze code across different programming languages
- **Agent-Based Analysis** - Deploy specialized agents for different analysis tasks
- **Extensible Skills** - Add new analysis capabilities through a modular skill system
- **Integration Ready** - Works with CI/CD pipelines and existing development workflows

## Project Structure

```
chp/
├── agents/           # Analysis agents (rule enforcers)
├── skills/           # Reusable analysis skills and detectors
├── scripts/          # Setup and utility scripts
├── docs/             # Rule documentation and guides
├── assets/           # Configuration files and rule definitions
├── tests/            # Test cases and rule validation
├── .claude-plugin/   # Claude Code integration
├── .codex-plugin/    # Codex integration
├── .cursor-plugin/   # Cursor integration
├── .windsurf-plugin/ # Windsurf IDE integration
└── .opencode/        # OpenCode integration
```

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/chp.git
cd chp

# Install dependencies
npm install
```

## Usage

### Run a Full Analysis

```bash
npm run analyze
```

### Run Specific Rules

```bash
npm run analyze -- --rule security --rule style
```

### Create a Custom Rule

```typescript
// Define your rule in the rules directory
export const myRule = {
  name: 'my-custom-rule',
  check: (node, context) => {
    // Your analysis logic here
    return { pass: true, message: '' };
  }
};
```

## Configuration

Rules are configured in your project's `.chprc` or `chp.config.js`:

```javascript
module.exports = {
  rules: {
    'no-console': 'error',
    'max-line-length': ['warn', 120],
    'enforce-async-await': 'error'
  },
  ignore: ['node_modules/**', 'dist/**']
};
```

## Development

```bash
# Run tests
npm test

# Watch mode during development
npm run dev

# Lint the codebase
npm run lint
```

## Contributing

Contributions are welcome! Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new rules
5. Submit a pull request

## Documentation

- [CLAUDE.md](CLAUDE.md) - Claude-specific setup
- [AGENTS.md](AGENTS.md) - Agent development guide
- [docs/](docs/) - Detailed documentation

## Law Enforcement System

CHP includes a two-layer law enforcement system:

### Quick Start

```bash
# Create a new law
./commands/chp-law create my-law --hooks=pre-commit

# List all laws
./commands/chp-law list

# Check system status
./commands/chp-status
```

### How It Works

1. **Suggestive Layer** - Context files in `docs/chp/` guide agents to follow rules
2. **Verification Layer** - Scripts in `docs/chp/laws/` check for violations
3. **Auto-Tightening** - Failed verifications strengthen guidance automatically

### Creating Laws

See the [chp:write-laws](skills/write-laws/skill.md) skill for detailed guidance.

```bash
# Create a law
./commands/chp-law create no-secrets --hooks=pre-commit,pre-push

# Edit the verification script
vim docs/chp/laws/no-secrets/verify.sh

# Edit the guidance
vim docs/chp/no-secrets.md

# Test it
./commands/chp-law test no-secrets
```

### Example Laws

- **no-console-log** - Prevents console.log commits (included)
- **no-api-keys** - Detects API key patterns (create with chp-law)

## Universal Hook System

CHP now supports 25+ hook types across Git, AI/Agent, and CI/CD operations:

### Quick Start

```bash
# Detect available hooks
./commands/chp-hooks detect

# Create a law for multiple hook types
./commands/chp-law create no-secrets --hooks=pre-commit,pre-push,pre-tool

# Manage hooks
./commands/chp-hooks list
./commands/chp-hooks enable pre-commit
./commands/chp-hooks install pre-commit
```

### Hook Types

- **Git Hooks (15):** pre-commit, post-commit, pre-push, post-merge, commit-msg, prepare-commit-msg, pre-rebase, post-checkout, post-rewrite, applypatch-msg, pre-applypatch, post-applypatch, update, pre-auto-gc, post-update
- **AI/Agent Hooks (6):** pre-prompt, post-prompt, pre-tool, post-tool, pre-response, post-response
- **CI/CD Hooks (4):** pre-build, post-build, pre-deploy, post-deploy

### Documentation

See [docs/chp/HOOKS.md](docs/chp/HOOKS.md) for complete hook system documentation.

## License

MIT - See [LICENSE](LICENSE) for details.
# Test change
