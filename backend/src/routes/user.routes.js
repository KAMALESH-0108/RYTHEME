const express = require('express');
const router = express.Router();
const SupabaseService = require('../services/supabase.service');
const { requireAuth } = require('../middlewares/auth.middleware');

// GET /api/user/profile
router.get('/profile', requireAuth, async (req, res) => {
  try {
    const profile = await SupabaseService.getProfile(req.user.id);
    res.json({ success: true, data: profile });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// PUT /api/user/profile
router.put('/profile', requireAuth, async (req, res) => {
  try {
    const updated = await SupabaseService.updateProfile(req.user.id, req.body);
    res.json({ success: true, data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/user/likes
router.get('/likes', requireAuth, async (req, res) => {
  try {
    const likes = await SupabaseService.getLikedSongs(req.user.id);
    res.json({ success: true, data: likes });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/user/likes/toggle
router.post('/likes/toggle', requireAuth, async (req, res) => {
  try {
    const result = await SupabaseService.toggleLikeSong(req.user.id, req.body);
    res.json({ success: true, data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/user/playlists
router.get('/playlists', requireAuth, async (req, res) => {
  try {
    const playlists = await SupabaseService.getPlaylists(req.user.id);
    res.json({ success: true, data: playlists });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/user/playlists
router.post('/playlists', requireAuth, async (req, res) => {
  try {
    const { name, description, isPublic } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'Name is required' });
    const playlist = await SupabaseService.createPlaylist(req.user.id, { name, description, isPublic });
    res.json({ success: true, data: playlist });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/user/journal
router.get('/journal', requireAuth, async (req, res) => {
  try {
    const entries = await SupabaseService.getJournal(req.user.id);
    res.json({ success: true, data: entries });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/user/journal
router.post('/journal', requireAuth, async (req, res) => {
  try {
    const { note, songTitle, artist, mood, imageUrl } = req.body;
    if (!note || !songTitle) {
      return res.status(400).json({ success: false, message: 'Note and songTitle are required' });
    }
    const entry = await SupabaseService.saveJournalEntry(req.user.id, { note, songTitle, artist, mood, imageUrl });
    res.json({ success: true, data: entry });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
