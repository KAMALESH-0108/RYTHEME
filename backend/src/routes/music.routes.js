const express = require('express');
const router = express.Router();
const JioSaavnService = require('../services/jiosaavn.service');

// GET /api/music/search?query=xxx&page=1&limit=20
router.get('/search', async (req, res) => {
  try {
    const { query = '', page = 1, limit = 20 } = req.query;
    if (!query) {
      return res.status(400).json({ success: false, message: 'Query parameter is required' });
    }
    const songs = await JioSaavnService.searchSongs(query, parseInt(page, 10), parseInt(limit, 10));
    res.json({ success: true, data: songs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/trending
router.get('/trending', async (req, res) => {
  try {
    const songs = await JioSaavnService.getTrendingSongs();
    res.json({ success: true, data: songs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/song/:id
router.get('/song/:id', async (req, res) => {
  try {
    const song = await JioSaavnService.getSongDetails(req.params.id);
    if (!song) {
      return res.status(404).json({ success: false, message: 'Song not found' });
    }
    res.json({ success: true, data: song });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/song/:id/lyrics
router.get('/song/:id/lyrics', async (req, res) => {
  try {
    const lyrics = await JioSaavnService.getSongLyrics(req.params.id);
    res.json({ success: true, data: { lyrics } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/song/:id/recommendations
router.get('/song/:id/recommendations', async (req, res) => {
  try {
    const songs = await JioSaavnService.getRecommendations(req.params.id);
    res.json({ success: true, data: songs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/albums/search?query=xxx
router.get('/albums/search', async (req, res) => {
  try {
    const { query = '' } = req.query;
    const albums = await JioSaavnService.searchAlbums(query);
    res.json({ success: true, data: albums });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/album/:id
router.get('/album/:id', async (req, res) => {
  try {
    const album = await JioSaavnService.getAlbumDetails(req.params.id);
    if (!album) {
      return res.status(404).json({ success: false, message: 'Album not found' });
    }
    res.json({ success: true, data: album });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/playlists/search?query=xxx
router.get('/playlists/search', async (req, res) => {
  try {
    const { query = '' } = req.query;
    const playlists = await JioSaavnService.searchPlaylists(query);
    res.json({ success: true, data: playlists });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/playlist/:id
router.get('/playlist/:id', async (req, res) => {
  try {
    const playlist = await JioSaavnService.getPlaylistDetails(req.params.id);
    if (!playlist) {
      return res.status(404).json({ success: false, message: 'Playlist not found' });
    }
    res.json({ success: true, data: playlist });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/artists/search?query=xxx
router.get('/artists/search', async (req, res) => {
  try {
    const { query = '' } = req.query;
    const artists = await JioSaavnService.searchArtists(query);
    res.json({ success: true, data: artists });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/music/artist/:id
router.get('/artist/:id', async (req, res) => {
  try {
    const artist = await JioSaavnService.getArtistDetails(req.params.id);
    if (!artist) {
      return res.status(404).json({ success: false, message: 'Artist not found' });
    }
    res.json({ success: true, data: artist });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
