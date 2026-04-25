const express = require('express');
const path = require('path');
const fs = require('fs');

const lawsRouter = require('./routes/laws-api.cjs');
const reportsRouter = require('./routes/reports.cjs');
const scanRouter = require('./routes/scan.cjs');

const PORT = process.env.PORT || 3000;

const app = express();

app.use(express.json());

// API routes
app.use('/api/laws', lawsRouter);
app.use('/api/reports', reportsRouter);
app.use('/api/scan', scanRouter);

// Serve UI static files in production
const uiDistPath = path.join(__dirname, '../ui/dist');
if (fs.existsSync(uiDistPath)) {
  app.use(express.static(uiDistPath));
  app.use((req, res, next) => {
    if (!req.path.startsWith('/api/')) {
      res.sendFile(path.join(uiDistPath, 'index.html'));
    } else {
      next();
    }
  });
} else {
  // In development, show message
  app.get('/health', (req, res) => {
    res.json({ status: 'ok', mode: fs.existsSync(uiDistPath) ? 'production' : 'api-only' });
  });
}

app.listen(PORT, () => {
  console.log(`CHP UI running at http://localhost:${PORT}`);
});