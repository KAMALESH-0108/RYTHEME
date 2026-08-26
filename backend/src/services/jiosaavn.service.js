const axios = require('axios');
const config = require('../config');

class JioSaavnService {
  static get client() {
    return axios.create({
      baseURL: config.jiosaavn.apiUrl,
      headers: config.jiosaavn.getHeaders(),
      timeout: config.jiosaavn.timeoutMs
    });
  }

  // ===========================================================================
  // 1. SEARCH & SONGS
  // ===========================================================================

  static async searchSongs(query, page = 1, limit = 20) {
    try {
      const response = await this.client.get('/api/search/songs', {
        params: { query, page, limit }
      });

      if (response.data && response.data.success && response.data.data) {
        const results = response.data.data.results || [];
        return results.map(this._parseSongItem);
      }
      return this._getFallbackSongs(query);
    } catch (error) {
      console.warn(`[JioSaavn API] searchSongs error: ${error.message}. Returning fallback catalog.`);
      return this._getFallbackSongs(query);
    }
  }

  static async getSongDetails(id) {
    try {
      const response = await this.client.get('/api/songs', {
        params: { id }
      });

      if (response.data && response.data.success && response.data.data) {
        const results = Array.isArray(response.data.data) ? response.data.data : [response.data.data];
        if (results.length > 0) {
          return this._parseSongItem(results[0]);
        }
      }
      return null;
    } catch (error) {
      console.warn(`[JioSaavn API] getSongDetails error: ${error.message}`);
      return null;
    }
  }

  static async getTrendingSongs() {
    try {
      const response = await this.client.get('/api/search/songs', {
        params: { query: 'trending', limit: 20 }
      });

      if (response.data && response.data.success && response.data.data) {
        const results = response.data.data.results || [];
        return results.map(this._parseSongItem);
      }
      return this._getTrendingFallback();
    } catch (error) {
      console.warn(`[JioSaavn API] getTrendingSongs error: ${error.message}. Using offline catalog.`);
      return this._getTrendingFallback();
    }
  }

  static async getRecommendations(songId) {
    try {
      const response = await this.client.get(`/api/songs/${songId}/suggestions`, {
        params: { limit: 10 }
      });

      if (response.data && response.data.success && response.data.data) {
        const results = response.data.data || [];
        return results.map(this._parseSongItem);
      }
      return this._getTrendingFallback();
    } catch (error) {
      console.warn(`[JioSaavn API] getRecommendations error: ${error.message}`);
      return this._getTrendingFallback();
    }
  }

  // ===========================================================================
  // 2. ALBUMS & PLAYLISTS
  // ===========================================================================

  static async searchAlbums(query) {
    try {
      const response = await this.client.get('/api/search/albums', {
        params: { query }
      });

      if (response.data && response.data.success && response.data.data) {
        const results = response.data.data.results || [];
        return results.map(a => ({
          id: a.id?.toString() || '',
          title: a.name || a.title || '',
          artist: a.primaryArtists || a.artist || '',
          year: a.year?.toString() || '',
          image_url: JioSaavnService._extractBestImage(a.image),
          song_count: a.songCount || 0
        }));
      }
      return [];
    } catch (error) {
      console.warn(`[JioSaavn API] searchAlbums error: ${error.message}`);
      return [];
    }
  }

  static async getAlbumDetails(id) {
    try {
      const response = await this.client.get('/api/albums', {
        params: { id }
      });

      if (response.data && response.data.success && response.data.data) {
        const d = response.data.data;
        const songs = (d.songs || []).map(this._parseSongItem);
        return {
          id: d.id?.toString() || '',
          title: d.name || d.title || '',
          artist: d.primaryArtists || '',
          year: d.year?.toString() || '',
          image_url: this._extractBestImage(d.image),
          songs
        };
      }
      return null;
    } catch (error) {
      console.warn(`[JioSaavn API] getAlbumDetails error: ${error.message}`);
      return null;
    }
  }

  static async getPlaylistDetails(id) {
    try {
      const response = await this.client.get('/api/playlists', {
        params: { id }
      });

      if (response.data && response.data.success && response.data.data) {
        const d = response.data.data;
        const songs = (d.songs || []).map(this._parseSongItem);
        return {
          id: d.id?.toString() || '',
          title: d.name || d.title || '',
          subtitle: d.subtitle || '',
          image_url: this._extractBestImage(d.image),
          songs
        };
      }
      return null;
    } catch (error) {
      console.warn(`[JioSaavn API] getPlaylistDetails error: ${error.message}`);
      return null;
    }
  }

  static async searchArtists(query) {
    try {
      const response = await this.client.get('/api/search/artists', {
        params: { query }
      });

      if (response.data && response.data.success && response.data.data) {
        const results = response.data.data.results || [];
        return results.map(a => ({
          id: a.id?.toString() || '',
          name: a.name || a.title || '',
          role: a.role || 'Artist',
          image_url: JioSaavnService._extractBestImage(a.image),
        }));
      }
      return [];
    } catch (error) {
      console.warn(`[JioSaavn API] searchArtists error: ${error.message}`);
      return [];
    }
  }

  static async getArtistDetails(id) {
    try {
      const response = await this.client.get('/api/artists', {
        params: { id }
      });

      if (response.data && response.data.success && response.data.data) {
        const d = response.data.data;
        const topSongs = (d.topSongs || []).map(this._parseSongItem);
        return {
          id: d.id?.toString() || '',
          name: d.name || '',
          follower_count: d.followerCount || 0,
          is_verified: Boolean(d.isVerified),
          image_url: this._extractBestImage(d.image),
          top_songs: topSongs,
          albums: d.topAlbums || []
        };
      }
      return null;
    } catch (error) {
      console.warn(`[JioSaavn API] getArtistDetails error: ${error.message}`);
      return null;
    }
  }

  // ===========================================================================
  // 3. LYRICS & PARSING HELPERS
  // ===========================================================================

  static async getSongLyrics(id) {
    try {
      const response = await this.client.get(`/api/songs/${id}/lyrics`);
      if (response.data && response.data.success && response.data.data) {
        return response.data.data.lyrics || 'No lyrics available.';
      }
      return this._getFallbackLyrics(id);
    } catch (error) {
      console.warn(`[JioSaavn API] getSongLyrics error: ${error.message}`);
      return this._getFallbackLyrics(id);
    }
  }

  static _parseSongItem(item) {
    let artistName = item.primaryArtists || item.subtitle || '';
    if (!artistName && item.artists) {
      if (Array.isArray(item.artists.primary) && item.artists.primary.length > 0) {
        artistName = item.artists.primary.map(a => a.name).join(', ');
      } else if (Array.isArray(item.artists.all) && item.artists.all.length > 0) {
        artistName = item.artists.all.map(a => a.name).join(', ');
      }
    }
    if (!artistName) artistName = 'Unknown Artist';

    return {
      id: item.id?.toString() || '',
      title: JioSaavnService._cleanHtml(item.name || item.title || 'Unknown Track'),
      artist: JioSaavnService._cleanHtml(artistName),
      album: JioSaavnService._cleanHtml(typeof item.album === 'object' ? item.album?.name || 'Single' : item.album || 'Single'),
      image_url: JioSaavnService._extractBestImage(item.image),
      stream_url: JioSaavnService._extractBestStreamUrl(item.downloadUrl),
      duration: parseInt(item.duration, 10) || 180,
      year: item.year?.toString() || '2026',
      language: item.language || 'English',
      has_lyrics: Boolean(item.hasLyrics === 'true' || item.hasLyrics === true)
    };
  }

  static _extractBestImage(images) {
    const defaultImage = 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500';
    if (Array.isArray(images) && images.length > 0) {
      const last = images[images.length - 1];
      return last?.url || last?.link || (typeof last === 'string' ? last : defaultImage);
    } else if (typeof images === 'string' && images.length > 0) {
      return images;
    }
    return defaultImage;
  }

  static _extractBestStreamUrl(downloadUrls) {
    const defaultStream = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    if (Array.isArray(downloadUrls) && downloadUrls.length > 0) {
      const last = downloadUrls[downloadUrls.length - 1];
      return last?.url || last?.link || (typeof last === 'string' ? last : defaultStream);
    } else if (typeof downloadUrls === 'string' && downloadUrls.length > 0) {
      return downloadUrls;
    }
    return defaultStream;
  }

  static _cleanHtml(str) {
    if (!str) return '';
    return str
      .replace(/&quot;/g, '"')
      .replace(/&amp;/g, '&')
      .replace(/&#039;/g, "'")
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&nbsp;/g, ' ');
  }

  // ===========================================================================
  // 4. OFFLINE FALLBACKS
  // ===========================================================================
  static _getTrendingFallback() {
    return [
      {
        id: 'trend_1',
        title: 'Aesthetic Frequency',
        artist: 'Kamlesh & The Rhythms',
        album: 'Design DNA',
        image_url: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
        stream_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: 372,
        year: '2026',
        language: 'Instrumental',
        has_lyrics: true
      },
      {
        id: 'trend_2',
        title: 'Silicon Valley Dreams',
        artist: 'Antigravity Ensemble',
        album: 'Deep Coding Waves',
        image_url: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=500',
        stream_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration: 423,
        year: '2026',
        language: 'Synthwave',
        has_lyrics: true
      },
      {
        id: 'trend_3',
        title: 'Red Energy Pulse',
        artist: 'Glassmorphism Project',
        album: 'Dark Translucence',
        image_url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
        stream_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        duration: 302,
        year: '2026',
        language: 'Electronic',
        has_lyrics: true
      }
    ];
  }

  static _getFallbackSongs(query) {
    const q = (query || '').toLowerCase();
    const all = this._getTrendingFallback();
    return all.filter(s => s.title.toLowerCase().includes(q) || s.artist.toLowerCase().includes(q));
  }

  static _getFallbackLyrics(id) {
    return `[00:00.00] Find your sound. Feel your moment.\n[00:08.00] Welcome to the RYTHEME universe...\n[00:15.00] Driving through the neon shadows,\n[00:22.00] With red lights painting all the lines.\n[00:30.00] Translucent sheets of glass reflect,\n[00:38.00] The rhythm pulsing through our eyes.`;
  }
}

module.exports = JioSaavnService;
