# Installing CHP for Codex

Enable CHP (Codebeat Highway Patrol) in Codex via native skill discovery. Just clone and symlink.

## Prerequisites

- Git
- Node.js (for CHP CLI tools)

## Installation

1. **Clone the CHP repository:**

   ```bash
   git clone https://github.com/yourusername/chp.git ~/.codex/chp
   ```

2. **Create the skills symlink:**

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/chp/skills ~/.agents/skills/chp
   ```

   **Windows (PowerShell):**

   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\chp" "$env:USERPROFILE\.codex\chp\skills"
   ```

3. **Install CHP CLI tools:**

   ```bash
   cd ~/.codex/chp
   npm install
   npm link
   ```

4. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/chp
```

You should see a symlink (or junction on Windows) pointing to your CHP skills directory.

```bash
chp --help
```

Should show the CHP CLI usage.

## Updating

```bash
cd ~/.codex/chp && git pull
npm install
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/chp
npm unlink -g chp
```

Optionally delete the clone: `rm -rf ~/.codex/chp`
