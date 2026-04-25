---
name: scan-repo
description: Scan the full repository for CHP law violations and generate a report
---

# Scan Repository for Violations

## When to Use

- User asks to check code quality, scan, or generate a report
- Before a commit, PR, or release
- User says "scan", "check", "report", or "violations"

## Process

1. Run the deterministic checker against the full project:
   ```bash
   python "${CLAUDE_PLUGIN_ROOT}/bin/chp-check"
   ```
   This scans all source files against laws that have a `check:` regex pattern and writes results to `.chp/report.json`.

2. Read `laws/chp-laws.txt` and identify laws WITHOUT a `check:` field — these need subjective review.

3. For each subjective law, scan relevant source files and judge whether the code violates the law's intent. Add any subjective violations to `.chp/report.json` with `"type": "subjective"`.

4. Generate the HTML report:
   ```bash
   python "${CLAUDE_PLUGIN_ROOT}/bin/chp-report"
   ```
   This creates `.chp/report.html` — a clean dashboard showing all violations.

5. Tell the user the report is at `.chp/report.html` and summarize the findings.

## Report Format

The report shows:
- Summary cards: total violations, blocked, warnings, laws violated
- Law-by-law breakdown with expandable sections
- Each violation shows file, line, code snippet
- Tagged as AUTO (deterministic) or REVIEW (subjective)

## Law Types

- **Deterministic** (has `check:` field): Detected automatically via regex. Tagged AUTO in the report.
- **Subjective** (no `check:` field): Requires your judgment against the law's intent. Tagged REVIEW in the report.
