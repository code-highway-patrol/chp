const express = require('express');
const fs = require('fs');
const { execScan } = require('../utils/exec.cjs');

const router = express.Router();

// POST /api/scan - Trigger a scan
router.post('/', (req, res) => {
  const result = execScan();

  const reportPath = '.chp/report.json';

  if (fs.existsSync(reportPath)) {
    try {
      const report = JSON.parse(fs.readFileSync(reportPath, 'utf-8'));
      return res.json(report);
    } catch {
      // fall through
    }
  }

  if (result.success) {
    res.json({ success: true, output: result.output });
  } else {
    res.status(500).json({ error: result.output });
  }
});

module.exports = router;