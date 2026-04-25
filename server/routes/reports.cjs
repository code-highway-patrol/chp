const express = require('express');
const path = require('path');
const fs = require('fs');

const REPORT_DIR = '.chp';

const router = express.Router();

// GET /api/reports - List reports
router.get('/', (req, res) => {
  const reportPath = path.join(process.cwd(), REPORT_DIR, 'report.json');

  if (!fs.existsSync(reportPath)) {
    return res.json([]);
  }

  try {
    const report = JSON.parse(fs.readFileSync(reportPath, 'utf-8'));
    res.json([report]);
  } catch {
    res.json([]);
  }
});

// GET /api/reports/latest - Get latest report
router.get('/latest', (req, res) => {
  const reportPath = path.join(process.cwd(), REPORT_DIR, 'report.json');

  if (!fs.existsSync(reportPath)) {
    return res.status(404).json({ error: 'No reports found' });
  }

  try {
    const report = JSON.parse(fs.readFileSync(reportPath, 'utf-8'));
    res.json(report);
  } catch {
    res.status(500).json({ error: 'Failed to read report' });
  }
});

module.exports = router;