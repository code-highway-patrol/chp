---
name: marketplace
description: Search and install CHP laws from the marketplace. Triggers on "install law", "search marketplace", "find laws", "chp install", "marketplace", "what laws are available".
---

# CHP Marketplace

Search, discover, and install CHP laws from the community marketplace.

## When to Invoke

Invoke this skill when:
- User wants to find laws to enforce rules
- User asks "what laws are available", "search marketplace", "find laws"
- User wants to install a law pack or single law
- User says "install [law-name]" or "chp install [something]"
- User needs to discover what enforcement options exist

## Available Commands

### Search the Marketplace

```bash
# Search for laws by keyword
chp search "console"
chp search "security"
chp search "typescript"

# List all available laws
chp list
```

### Install Laws

```bash
# Install a single law by slug
chp install no-console-log

# Install multiple laws at once
chp install no-console-log no-api-keys no-alerts

# Install a law pack
chp install javascript-best-practices
```

### Marketplace Subcommands

```bash
# Using the marketplace namespace explicitly
chp marketplace list
chp marketplace search "query"
chp marketplace install <slug>
chp marketplace show <slug> [--full]
```

### Inspect Laws Before Installing

```bash
# Show law preview (first 8 lines of guidance.md)
chp show no-console-log

# Show complete file contents (guidance.md, law.json, verify.sh)
chp show no-console-log --full
```

## How It Works

1. **Search** — Queries the marketplace API at pinkdonut.work
2. **Preview** — Shows law title, slug, stars, description, and tags
3. **Install** — Downloads law files to `docs/chp/laws/<name>/`
4. **Activate** — Laws are automatically registered to their declared hooks

## Law Types

The marketplace contains:

| Type | Icon | Description |
|------|------|-------------|
| Single Law | 📄 | Individual law with law.json + verify.sh + guidance.md |
| Collection | 📁 | Law pack with multiple related laws bundled together |

## After Installation

Once installed, laws are available in your codebase:

```bash
# See what laws are installed
chp laws

# Test a specific law
chp-law test <law-name>

# Disable a law you don't want
chp-law disable <law-name>
```

## Marketplace API

The marketplace API is at `https://pinkdonut.work/api`:

- `GET /api/statues` — List all laws
- `POST /api/statues/search` — Search by query
- `GET /api/statues/{slug}` — Get law details

## Example Workflow

```bash
# 1. Search for relevant laws
chp search "console"

# Output shows:
# 📄 No Console Logging (Slug: no-console-log | ★ 42)
#    Prevents console.log in production code

# 2. Inspect the law before installing (optional)
chp show no-console-log --full

# 3. Install the law
chp install no-console-log

# 4. Verify it works
echo 'console.log("test")' | bash docs/chp/laws/no-console-log/verify.sh
# Expected: exit 1 (violation detected)

# 5. Check it's registered
chp laws
```

## Troubleshooting

**Law not found:**
- Check the slug exactly matches the marketplace listing
- Use `chp list` to see all available slugs

**Install fails:**
- Ensure `docs/chp/laws/` directory is writable
- Check network connectivity to pinkdonut.work

**Law not enforcing:**
- Verify hooks are installed: `chp-hooks list`
- Check law is enabled: `chp-law status <name>`

## Contributing Laws

To publish your own laws to the marketplace:

1. Create law following CHP law structure
2. Submit to marketplace via API or PR
3. Include clear title, description, and tags
4. Set appropriate severity and hooks
