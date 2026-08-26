const express = require('express');
const router = express.Router();
const config = require('../config');
const JioSaavnService = require('../services/jiosaavn.service');

// GET /api/health
router.get('/', async (req, res) => {
  let saavnHealthy = false;
  try {
    const testSearch = await JioSaavnService.searchSongs('test', 1, 1);
    saavnHealthy = testSearch.length > 0;
  } catch (_) {
    saavnHealthy = false;
  }

  res.json({
    status: 'healthy',
    service: 'Rytheme Node.js Backend',
    version: '1.0.0',
    environment: config.nodeEnv,
    supabase: {
      configured: config.supabase.isConfigured(),
      url: config.supabase.url
    },
    jiosaavn: {
      apiUrl: config.jiosaavn.apiUrl,
      hasApiKey: Boolean(config.jiosaavn.apiKey),
      connected: saavnHealthy
    },
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
