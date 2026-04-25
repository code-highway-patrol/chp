const express = require('express');
const path = require('path');
const fs = require('fs');

const router = express.Router();
const LAWS_DIR = path.join(process.env.CHPT_ROOT || process.cwd(), 'docs/chp/laws');

function getLawMeta(name) {
  try {
    const lawJson = path.join(LAWS_DIR, name, 'law.json');
    if (!fs.existsSync(lawJson)) return null;
    return JSON.parse(fs.readFileSync(lawJson, 'utf-8'));
  } catch {
    return null;
  }
}

function listLaws() {
  const laws = [];
  if (!fs.existsSync(LAWS_DIR)) return laws;
  const dirs = fs.readdirSync(LAWS_DIR).filter(f =>
    fs.statSync(path.join(LAWS_DIR, f)).isDirectory()
  );
  for (const name of dirs) {
    const meta = getLawMeta(name);
    if (meta) laws.push(meta);
  }
  return laws;
}

router.get('/', (req, res) => {
  res.json(listLaws());
});

router.get('/:name', (req, res) => {
  const meta = getLawMeta(req.params.name);
  if (!meta) return res.status(404).json({ error: 'Law not found' });
  const guidancePath = path.join(LAWS_DIR, req.params.name, 'guidance.md');
  const verifyPath = path.join(LAWS_DIR, req.params.name, 'verify.sh');
  res.json({
    ...meta,
    guidance: fs.existsSync(guidancePath) ? fs.readFileSync(guidancePath, 'utf-8') : null,
    verifyScript: fs.existsSync(verifyPath) ? fs.readFileSync(verifyPath, 'utf-8') : null
  });
});

router.post('/', (req, res) => {
  const { name, description, pattern, severity, hooks, enabled } = req.body;
  if (!name) return res.status(400).json({ error: 'Law name is required' });

  const lawDir = path.join(LAWS_DIR, name);
  fs.mkdirSync(lawDir, { recursive: true });

  const lawJson = {
    name,
    created: new Date().toISOString(),
    severity: severity || 'error',
    failures: 0,
    tightening_level: 0,
    hooks: hooks || [],
    enabled: enabled !== undefined ? enabled : true,
    description: description || '',
    pattern: pattern || ''
  };
  fs.writeFileSync(path.join(lawDir, 'law.json'), JSON.stringify(lawJson, null, 2));

  const verifyScript = `#!/bin/bash
# Verification script for law: ${name}

LAW_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="\$(cd "\$LAW_DIR/../../../../" && pwd)"
source "\$CHP_BASE/core/common.sh"

verify_law() {
    local law_name="${name}"
    log_info "Verifying law: $law_name"

    local staged_files=\$(git diff --cached --name-only --diff-filter=ACM)
    if [ -z "$staged_files" ]; then
        log_info "No staged files to check"
        return 0
    fi

    local skip_pattern='\\.(md|json|txt|sh|yml|yaml|lock|gitignore)$'
    local violations=0
    local violating_files=()

    while IFS= read -r file; do
        if echo "$file" | grep -qE "$skip_pattern"; then continue; fi
        if [ ! -f "$file" ]; then continue; fi
        if git diff --cached "$file" | grep -qE '${pattern || '.'}'; then
            violations=\$((violations + 1))
            violating_files+=("$file")
        fi
    done <<< "$staged_files"

    if [ $violations -gt 0 ]; then
        log_error "Law violation detected in $violations file(s): ${description || name}"
        for file in "\${violating_files[@]}"; do
            log_error "  - $file"
        done
        return 1
    fi

    log_info "Law verification passed: $law_name"
    return 0
}

verify_law
exit $?
`;
  fs.writeFileSync(path.join(lawDir, 'verify.sh'), verifyScript);

  const guidance = `# Law: ${name}

**Severity:** ${severity || 'error'}
**Created:** ${lawJson.created}
**Failures:** 0

## Purpose

${description || 'Enforces code quality standards.'}

## Violation Pattern

\`\`\`
${pattern || '.*'}
\`\`\`

## Guidance

### Examples

#### Good Practice
\`\`\`
// Compliant code
\`\`\`

#### Bad Practice (will fail verification)
\`\`\`
// Non-compliant code
\`\`\`

## Remediation

1. Identify the violation
2. Fix the issue
3. Re-run verification
4. Commit changes
`;
  fs.writeFileSync(path.join(lawDir, 'guidance.md'), guidance);

  res.json(lawJson);
});

router.put('/:name', (req, res) => {
  const meta = getLawMeta(req.params.name);
  if (!meta) return res.status(404).json({ error: 'Law not found' });
  const lawPath = path.join(LAWS_DIR, req.params.name, 'law.json');
  const { description, pattern, severity, hooks, enabled } = req.body;
  if (severity !== undefined) meta.severity = severity;
  if (hooks !== undefined) meta.hooks = hooks;
  if (enabled !== undefined) meta.enabled = enabled;
  if (description !== undefined) meta.description = description;
  if (pattern !== undefined) meta.pattern = pattern;
  fs.writeFileSync(lawPath, JSON.stringify(meta, null, 2));
  res.json(meta);
});

router.delete('/:name', (req, res) => {
  const name = req.params.name;
  if (!getLawMeta(name)) return res.status(404).json({ error: 'Law not found' });
  const lawDir = path.join(LAWS_DIR, name);
  fs.rmSync(lawDir, { recursive: true, force: true });
  res.json({ success: true });
});

router.post('/:name/disable', (req, res) => {
  const meta = getLawMeta(req.params.name);
  if (!meta) return res.status(404).json({ error: 'Law not found' });
  meta.enabled = false;
  fs.writeFileSync(path.join(LAWS_DIR, req.params.name, 'law.json'), JSON.stringify(meta, null, 2));
  res.json(meta);
});

router.post('/:name/enable', (req, res) => {
  const meta = getLawMeta(req.params.name);
  if (!meta) return res.status(404).json({ error: 'Law not found' });
  meta.enabled = true;
  fs.writeFileSync(path.join(LAWS_DIR, req.params.name, 'law.json'), JSON.stringify(meta, null, 2));
  res.json(meta);
});

module.exports = router;