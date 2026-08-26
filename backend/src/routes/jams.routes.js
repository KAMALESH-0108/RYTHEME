const express = require('express');
const router = express.Router();
const SupabaseService = require('../services/supabase.service');
const { requireAuth } = require('../middlewares/auth.middleware');

// GET /api/jams/active
router.get('/active', async (req, res) => {
  try {
    const jams = await SupabaseService.getActiveJams();
    res.json({ success: true, data: jams });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/jams/create
router.post('/create', requireAuth, async (req, res) => {
  try {
    const { name, hostName, hostAvatar, isPublic } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'Jam room name is required' });

    const jam = await SupabaseService.createJam(req.user.id, {
      name,
      hostName: hostName || req.user.username,
      hostAvatar,
      isPublic
    });
    res.json({ success: true, data: jam });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
