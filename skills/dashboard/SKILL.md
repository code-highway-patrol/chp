---
name: dashboard
description: Launch the CHP Dashboard — a web UI for managing laws, running scans, and viewing reports
---

# Launch CHP Dashboard

## When to Use

- User asks to open the dashboard, UI, or web interface
- User wants a visual way to manage laws, run scans, or view reports
- User says "dashboard", "ui", "interface", or "open chp"

## Process

1. Launch the dashboard server:
   ```bash
   python "${CLAUDE_PLUGIN_ROOT}/bin/chp-server"
   ```
   This starts a local server on port 5177 and opens `http://localhost:5177` in the browser.

2. Tell the user the dashboard is running and they can:
   - **View Laws** — see all active laws with their type (AUTO/REVIEW) and reaction
   - **Create Law** — add new laws with optional regex patterns
   - **Run Scan** — trigger a full codebase scan from the browser
   - **View Report** — see all violations grouped by law

3. To stop, press Ctrl+C in the terminal.

## Notes

- The server runs on `localhost:5177` by default. Pass a custom port: `python bin/chp-server 8080`
- All changes to laws are written directly to `laws/chp-laws.txt`
- Scans invoke `bin/chp-check` and results are stored in `.chp/report.json`
