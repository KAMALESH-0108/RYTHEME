const { createClient } = require('@supabase/supabase-js');
const config = require('../config');

// Initialize Supabase Client
let supabaseClient = null;
if (config.supabase.isConfigured()) {
  supabaseClient = createClient(
    config.supabase.url,
    config.supabase.serviceRoleKey || config.supabase.anonKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  );
  console.log(`[Supabase] Connected to project: ${config.supabase.url}`);
} else {
  console.log('[Supabase] Running in sandbox simulation mode (credentials are placeholders).');
}

// In-Memory fallback store when credentials are in mock mode
const mockDb = {
  profiles: {
    'usr_mock_01': {
      id: 'usr_mock_01',
      username: 'Kamlesh',
      email: 'kamlesh@rytheme.app',
      avatar_url: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      listening_hours: 148.5,
      rhythm_dna: { chill: 42, melodic: 31, energetic: 17, experimental: 10 }
    }
  },
  likedSongs: [
    {
      id: '101',
      user_id: 'usr_mock_01',
      song_id: '101',
      title: 'Starlight Echoes',
      artist: 'Ethereal Wave',
      image_url: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=350',
      stream_url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      liked_at: new Date().toISOString()
    }
  ],
  playlists: [
    {
      id: 'pl_01',
      user_id: 'usr_mock_01',
      name: 'Deep Focus Sessions 🎧',
      description: 'Atmospheric synthwave and coding tracks.',
      cover_url: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=350',
      is_public: true,
      playlist_tracks: []
    }
  ],
  jams: [
    {
      id: 'jam_01',
      name: 'Late Night Vibes 🔴',
      host_id: 'host_01',
      host_name: 'Sarah K.',
      host_avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      listeners_count: 14,
      is_live: true,
      current_song: 'Slow Burn Synth',
      current_artist: 'RetroFuture'
    },
    {
      id: 'jam_02',
      name: 'Coding Focus Room 💻',
      host_id: 'usr_mock_01',
      host_name: 'Kamlesh',
      host_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      listeners_count: 48,
      is_live: true,
      current_song: 'Low Pass Chill Lofi',
      current_artist: 'Mellow Beats'
    }
  ],
  journal: [
    {
      id: 'jn_01',
      user_id: 'usr_mock_01',
      note: 'Coding this app while listening to synthwave. Perfect atmosphere.',
      song_title: 'Midnight Neon',
      artist: 'CyberRider',
      mood: 'Focus 💻',
      created_at: new Date().toISOString()
    }
  ]
};

class SupabaseService {
  // Validate Supabase JWT token and extract user
  static async verifyUserToken(token) {
    if (!supabaseClient) {
      return { id: 'usr_mock_01', email: 'kamlesh@rytheme.app', username: 'Kamlesh' };
    }

    try {
      const { data: { user }, error } = await supabaseClient.auth.getUser(token);
      if (error || !user) throw new Error(error?.message || 'Invalid token');
      return user;
    } catch (err) {
      throw new Error(`Auth verification failed: ${err.message}`);
    }
  }

  // Get user profile (with auto-provisioning)
  static async getProfile(userId, defaultEmail = '') {
    if (!supabaseClient) {
      return mockDb.profiles[userId] || mockDb.profiles['usr_mock_01'];
    }

    let { data, error } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (!data) {
      const username = defaultEmail ? defaultEmail.split('@')[0] : `User_${userId.slice(0, 6)}`;
      const { data: newProfile, error: insertError } = await supabaseClient
        .from('profiles')
        .upsert({
          id: userId,
          username,
          email: defaultEmail,
          avatar_url: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
          listening_hours: 0.0,
          rhythm_dna: { chill: 40, melodic: 30, energetic: 20, experimental: 10 },
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select()
        .maybeSingle();
      if (!insertError && newProfile) return newProfile;
    }

    if (error) throw error;
    return data;
  }

  // Update user profile
  static async updateProfile(userId, updates) {
    if (!supabaseClient) {
      const existing = mockDb.profiles[userId] || mockDb.profiles['usr_mock_01'];
      Object.assign(existing, updates);
      return existing;
    }

    const { data, error } = await supabaseClient
      .from('profiles')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  // Liked Songs
  static async getLikedSongs(userId) {
    if (!supabaseClient) {
      return mockDb.likedSongs.filter(s => s.user_id === userId || userId === 'usr_mock_01');
    }

    const { data, error } = await supabaseClient
      .from('liked_songs')
      .select('*')
      .eq('user_id', userId)
      .order('liked_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  static async toggleLikeSong(userId, song) {
    const songId = song.id || song.song_id;
    if (!supabaseClient) {
      const idx = mockDb.likedSongs.findIndex(s => s.song_id === songId);
      if (idx >= 0) {
        mockDb.likedSongs.splice(idx, 1);
        return { liked: false, songId };
      } else {
        const newLike = {
          id: `like_${Date.now()}`,
          user_id: userId,
          song_id: songId,
          title: song.title || song.name || 'Track',
          artist: song.artist || song.subtitle || 'Artist',
          image_url: song.image_url || '',
          stream_url: song.stream_url || '',
          liked_at: new Date().toISOString()
        };
        mockDb.likedSongs.unshift(newLike);
        return { liked: true, song: newLike };
      }
    }

    // Check existing
    const { data: existing } = await supabaseClient
      .from('liked_songs')
      .select('id')
      .eq('user_id', userId)
      .eq('song_id', songId);

    if (existing && existing.length > 0) {
      await supabaseClient
        .from('liked_songs')
        .delete()
        .eq('user_id', userId)
        .eq('song_id', songId);
      return { liked: false, songId };
    } else {
      const { data: inserted, error } = await supabaseClient
        .from('liked_songs')
        .insert({
          user_id: userId,
          song_id: songId,
          title: song.title || song.name || 'Unknown',
          artist: song.artist || song.subtitle || 'Unknown',
          image_url: song.image_url || '',
          stream_url: song.stream_url || '',
          liked_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;
      return { liked: true, song: inserted };
    }
  }

  // Playlists
  static async getPlaylists(userId) {
    if (!supabaseClient) return mockDb.playlists;

    const { data, error } = await supabaseClient
      .from('playlists')
      .select('*, playlist_tracks(*)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  static async createPlaylist(userId, { name, description, isPublic = true }) {
    if (!supabaseClient) {
      const newPl = {
        id: `pl_${Date.now()}`,
        user_id: userId,
        name,
        description: description || '',
        is_public: isPublic,
        cover_url: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=350',
        playlist_tracks: [],
        created_at: new Date().toISOString()
      };
      mockDb.playlists.unshift(newPl);
      return newPl;
    }

    const { data, error } = await supabaseClient
      .from('playlists')
      .insert({
        user_id: userId,
        name,
        description,
        is_public: isPublic,
        cover_url: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=350'
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  // Live Jams
  static async getActiveJams() {
    if (!supabaseClient) return mockDb.jams;

    const { data, error } = await supabaseClient
      .from('jams')
      .select('*')
      .eq('is_live', true)
      .order('listeners_count', { ascending: false });

    if (error) throw error;
    return data;
  }

  static async createJam(userId, { name, hostName, hostAvatar, isPublic = true }) {
    const newJam = {
      name,
      host_id: userId,
      host_name: hostName || 'Kamlesh',
      host_avatar: hostAvatar || 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      listeners_count: 1,
      is_live: true,
      is_public: isPublic,
      current_song: 'Rytheme Jam Opener',
      current_artist: 'JAMS Host',
      created_at: new Date().toISOString()
    };

    if (!supabaseClient) {
      newJam.id = `jam_${Date.now()}`;
      mockDb.jams.unshift(newJam);
      return newJam;
    }

    const { data, error } = await supabaseClient
      .from('jams')
      .insert(newJam)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  // Sound Journal
  static async getJournal(userId) {
    if (!supabaseClient) return mockDb.journal;

    const { data, error } = await supabaseClient
      .from('sound_journal')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  static async saveJournalEntry(userId, { note, songTitle, artist, mood, imageUrl }) {
    const entry = {
      user_id: userId,
      note,
      song_title: songTitle,
      artist,
      mood,
      image_url: imageUrl || '',
      created_at: new Date().toISOString()
    };

    if (!supabaseClient) {
      entry.id = `jn_${Date.now()}`;
      mockDb.journal.unshift(entry);
      return entry;
    }

    const { data, error } = await supabaseClient
      .from('sound_journal')
      .insert(entry)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
}

module.exports = SupabaseService;
