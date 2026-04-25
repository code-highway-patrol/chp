# Installing CHP for Codex

CHP ships as a Codex plugin via a Git-backed marketplace. Every push to `main`
in this repo updates the plugin for users automatically.

## Install

```bash
codex plugin marketplace add code-highway-patrol/chp
```

Then open the Codex plugin directory, select the **Code Highway Patrol**
marketplace, and install **chp**.

## Update

```bash
codex plugin marketplace upgrade chp
```

## Remove

```bash
codex plugin marketplace remove chp
```

## What you get

Six skills for working with CHP laws:

- `audit` — scan codebase for violations and assess code health
- `investigate` — diagnose a specific violation
- `status` — show registered laws, hooks, and recent failures
- `write-laws` — author a new CHP law (verify.sh + guidance.md)
- `review-laws` — review an existing law for correctness and scope
- `decompose-laws` — split a broad law into focused sub-laws

## CLI tools (separate from the plugin)

The CHP CLI (`chp`, `chp-status`, `chp-law`, etc.) is a Node + Bash toolchain.
Install it separately by cloning the repo:

```bash
git clone https://github.com/code-highway-patrol/chp.git ~/src/chp
cd ~/src/chp
npm install
npm link
```

Requires Node.js 18+ and Bash 4+ (on macOS, install via `brew install bash`).
