# CHP UI Implementation Plan

## Overview

Build a web UI for CHP (Code Highway Patrol) that allows users to manage laws and view scan reports. The UI will be packaged inside the main `chp` npm package and consist of:
- React SPA frontend (served by Express backend)
- Express.js API server that wraps existing CHP commands
- New `chp ui` command to launch the web interface

## Tech Stack

- **Frontend**: React 18 + Vite, React Router, plain CSS
- **Backend**: Express.js API server (same process)
- **Data Storage**: JSON files (laws in `docs/chp/laws/<name>/`, reports in `.chp/report.json`)
- **State Management**: React Context + hooks

## Package Structure

```
chp/                          # npm package (existing)
├── bin/chp                   # CLI entry
├── lib/
│   ├── cli.js                # CLI logic (existing)
│   └── mcp-server.js         # MCP server (existing)
├── commands/                 # CLI commands (existing)
├── ui/
│   ├── package.json          # Vite React app
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── main.jsx
│       ├── App.jsx
│       ├── index.css
│       ├── context/
│       │   └── AppContext.jsx
│       ├── components/
│       │   ├── Navbar.jsx
│       │   ├── LawForm.jsx
│       │   ├── LawTable.jsx
│       │   ├── ReportCard.jsx
│       │   ├── ViolationList.jsx
│       │   └── ConfirmDialog.jsx
│       └── pages/
│           ├── Dashboard.jsx
│           ├── Laws.jsx
│           ├── LawEdit.jsx
│           ├── Reports.jsx
│           └── ReportDetail.jsx
└── server/
    ├── index.js              # Express server entry
    ├── routes/
    │   ├── laws.js          # Law CRUD endpoints
    │   ├── reports.js       # Report endpoints
    │   └── scan.js          # Scan trigger endpoint
    └── utils/
        └── exec.js           # Wrapper for executing chp commands
```

## New CLI Commands

| Command | Description |
|---------|-------------|
| `chp ui` | Start the web UI server |
| `chp ui --port 3000` | Start on specific port |

## Pages / Routes

| Route | Description |
|-------|-------------|
| `/` | Dashboard - overview stats, recent reports |
| `/laws` | Law list - table of all laws with status |
| `/laws/new` | Create law form |
| `/laws/:id/edit` | Edit law form |
| `/reports` | Scan reports list |
| `/reports/:id` | Individual report detail |

## Features

### 1. Law Management
- **List**: View all laws with name, severity, failure count, enabled status, hooks
- **Create**: Form with name, description, hooks selector (multi-select), severity selector
- **Edit**: Modify law properties (hooks, severity, enabled/disabled toggle)
- **Delete**: Remove law with confirmation dialog

### 2. Scan Reports
- **List**: View historical scan reports with timestamp, violation count, blocked count
- **Detail**: Full breakdown of violations - law name, file, line, snippet, reaction
- **Trigger Scan**: Button to run `chp-scan` and generate a new report

### 3. Dashboard
- Total laws count (enabled/disabled)
- Recent scan results summary
- Quick links to problematic laws

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/laws` | List all laws |
| POST | `/api/laws` | Create new law |
| GET | `/api/laws/:name` | Get law details |
| PUT | `/api/laws/:name` | Update law |
| DELETE | `/api/laws/:name` | Delete law |
| POST | `/api/laws/:name/disable` | Disable law |
| POST | `/api/laws/:name/enable` | Enable law |
| GET | `/api/reports` | List scan reports |
| GET | `/api/reports/latest` | Get most recent report |
| POST | `/api/scan` | Trigger a new scan |
| GET | `/api/stats` | Dashboard statistics |

## Data Model

### Law
```json
{
  "name": "no-console-log",
  "created": "2026-04-25T04:05:10Z",
  "severity": "error",
  "failures": 7,
  "tightening_level": 7,
  "hooks": ["pre-commit"],
  "enabled": true
}
```

### Scan Report
```json
{
  "timestamp": "2026-04-25T18:35:18Z",
  "files_checked": 1,
  "total_violations": 1,
  "total_block": 1,
  "total_warn": 0,
  "violations": [
    {
      "law": "no-console-log",
      "reaction": "block",
      "intent": "No console.log statements...",
      "file": "/path/file.js",
      "line": 1,
      "snippet": "console.log('test')"
    }
  ]
}
```

## Implementation Order

1. Create `server/` directory with Express API
2. Create `ui/` directory with Vite + React app
3. Build Express API endpoints (laws, reports, scan)
4. Create React app structure with routing
5. Build Dashboard page
6. Build Laws pages (list, create, edit)
7. Build Reports pages (list, detail)
8. Add "Run Scan" button
9. Style with plain CSS
10. Add `chp ui` command to CLI

## Notes

- UI runs in browser, Express serves both API and static files
- Use existing `chp-law` and `chp-scan` commands via child_process
- Laws stored in `docs/chp/laws/<name>/law.json`
- Reports stored in `.chp/report.json`
- Keep UI simple — functional over beautiful