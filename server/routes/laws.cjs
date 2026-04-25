const express = require('express');
const path = require('path');
const fs = require('fs');
const { exec, execLaw } = require('../utils/exec.cjs');

const router = express.Router();
const LAWS_DIR = path.join(process.env.CHPT_ROOT || process.cwd(), 'docs/chp/laws');

function getLawMeta(name, field) {
  try {
    const lawJson = path.join(LAWS_DIR, name, 'law.json');
    if (!fs.existsSync(lawJson)) return null;
    const data = JSON.parse(fs.readFileSync(lawJson, 'utf-8'));
    return field ? data[field] : data;
  } catch {
    return null;
  }
}

function listLaws() {
  const laws = [];
  if (!fs.existsSync(LAWS_DIR)) return laws;

  const dirs = fs.readdirSync(LAWS_DIR).filter(f => {
    return fs.statSync(path.join(LAWS_DIR, f)).isDirectory();
  });

  for (const name of dirs) {
    const meta = getLawMeta(name);
    if (meta) {
      laws.push(meta);
    }
  }
  return laws;
}

// GET /api/laws - List all laws
router.get('/', (req, res) => {
  const laws = listLaws();
  res.json(laws);
});

// GET /api/laws/:name - Get law details
router.get('/:name', (req, res) => {
  const { name } = req.params;
  const meta = getLawMeta(name);
  if (!meta) {
    return res.status(404).json({ error: 'Law not found' });
  }

  const guidancePath = path.join(LAWS_DIR, name, 'guidance.md');
  const verifyPath = path.join(LAWS_DIR, name, 'verify.sh');

  res.json({
    ...meta,
    guidance: fs.existsSync(guidancePath) ? fs.readFileSync(guidancePath, 'utf-8') : null,
    verifyScript: fs.existsSync(verifyPath) ? fs.readFileSync(verifyPath, 'utf-8') : null
  });
});

// POST /api/laws - Create new law
router.post('/', (req, res) => {
  const { name, hooks, severity } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'Law name is required' });
  }

  const result = execLaw('create', name, `--hooks=${hooks || ''}`);
  if (result.success) {
    const meta = getLawMeta(name);
    res.json(meta);
  } else {
    res.status(500).json({ error: result.output });
  }
});

// PUT /api/laws/:name - Update law
router.put('/:name', (req, res) => {
  const { name } = req.params;
  const meta = getLawMeta(name);

  if (!meta) {
    return res.status(404).json({ error: 'Law not found' });
  }

  const lawPath = path.join(LAWS_DIR, name, 'law.json');
  const { severity, hooks, enabled } = req.body;

  const updated = { ...meta };
  if (severity !== undefined) updated.severity = severity;
  if (hooks !== undefined) updated.hooks = hooks;
  if (enabled !== undefined) updated.enabled = enabled;

  fs.writeFileSync(lawPath, JSON.stringify(updated, null, 2));
  res.json(updated);
});

// DELETE /api/laws/:name - Delete law
router.delete('/:name', (req, res) => {
  const { name } = req.params;
  const result = execLaw('delete', name);
  if (result.success) {
    res.json({ success: true });
  } else {
    res.status(500).json({ error: result.output });
  }
});

// POST /api/laws/:name/disable - Disable law
router.post('/:name/disable', (req, res) => {
  const { name } = req.params;
  const result = execLaw('disable', name);
  if (result.success) {
    res.json(getLawMeta(name));
  } else {
    res.status(500).json({ error: result.output });
  }
});

// POST /api/laws/:name/enable - Enable law
router.post('/:name/enable', (req, res) => {
  const { name } = req.params;
  const result = execLaw('enable', name);
  if (result.success) {
    res.json(getLawMeta(name));
  } else {
    res.status(500).json({ error: result.output });
  }
});

module.exports = router;