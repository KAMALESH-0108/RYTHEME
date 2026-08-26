import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';

/// Supabase Backend Service managing Auth, PostgreSQL DB, Realtime Channels & Sync
class SupabaseService {
  // Check if Supabase client is initialized
  static bool get isInitialized {
    try {
      return Supabase.instance.client.auth.currentSession != null || 
             RythemeConfig.isSupabaseConfigured;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // 1. AUTHENTICATION & SESSIONS
  // ===========================================================================

  User? get currentUser => _client?.auth.currentUser;
  Session? get currentSession => _client?.auth.currentSession;
  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  /// Sign Up with Email, Password and Username
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final client = _client;
    if (client == null || !RythemeConfig.isSupabaseConfigured) {
      debugPrint('Supabase offline: simulated sign-up.');
      _mockProfile['username'] = username;
      _mockProfile['email'] = email;
      return null;
    }

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        await _createProfile(response.user!.id, username, email);
      }
      return response;
    } catch (e) {
      debugPrint('Supabase signUp error: $e');
      rethrow;
    }
  }

  /// Sign In with Email and Password
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null || !RythemeConfig.isSupabaseConfigured) {
      debugPrint('Supabase offline: simulated sign-in.');
      _mockProfile['email'] = email;
      return null;
    }

    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Supabase signIn error: $e');
      rethrow;
    }
  }

  /// Sign In with Google OAuth (Supabase Authentication)
  Future<bool> signInWithGoogle({String? redirectTo}) async {
    final client = _client;
    if (client == null || !RythemeConfig.isSupabaseConfigured) {
      debugPrint('Supabase offline: simulated Google sign-in.');
      _mockProfile['username'] = 'Google User';
      _mockProfile['email'] = 'google_user@rytheme.app';
      return true;
    }

    try {
      final success = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo ?? (kIsWeb ? Uri.base.origin : 'io.supabase.rytheme://login-callback'),
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      return success;
    } catch (e) {
      debugPrint('Supabase Google OAuth error: $e');
      rethrow;
    }
  }

  /// Ensure user profile exists in Supabase public.profiles table
  Future<void> ensureUserProfile() async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) return;

    try {
      final existing = await client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        final meta = user.userMetadata ?? {};
        final rawName = meta['full_name'] ?? meta['name'] ?? meta['user_name'] ?? meta['username'];
        final username = (rawName != null && rawName.toString().isNotEmpty)
            ? rawName.toString()
            : (user.email != null ? user.email!.split('@').first : 'Rytheme User');
        final avatar = meta['avatar_url'] ?? meta['picture'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

        await client.from('profiles').upsert({
          'id': user.id,
          'username': username,
          'email': user.email ?? '',
          'avatar_url': avatar,
          'listening_hours': 0.0,
          'rhythm_dna': {
            'chill': 40,
            'melodic': 30,
            'energetic': 20,
            'experimental': 10
          },
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('[Supabase] Created new profile entry for user ${user.id} ($username)');
      }
    } catch (e) {
      debugPrint('[Supabase] Error ensuring user profile: $e');
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;

    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
    }
  }

  // ===========================================================================
  // 2. USER PROFILES & RHYTHM DNA
  // ===========================================================================

  Future<void> _createProfile(String userId, String username, String email) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.from('profiles').upsert({
        'id': userId,
        'username': username,
        'email': email,
        'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        'listening_hours': 0.0,
        'rhythm_dna': {
          'chill': 40,
          'melodic': 30,
          'energetic': 20,
          'experimental': 10
        },
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating DB profile: $e');
    }
  }

  /// Fetch user profile from Supabase
  Future<Map<String, dynamic>> getUserProfile() async {
    final client = _client;
    final user = currentUser;

    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) {
      return _mockProfile;
    }

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data ?? _mockProfile;
    } catch (e) {
      debugPrint('Error fetching user profile: $e. Falling back to local data.');
      return _mockProfile;
    }
  }

  /// Update Profile Details (Username, Avatar, Rhythm DNA, Hours)
  Future<void> updateUserProfile({
    String? username,
    String? avatarUrl,
    Map<String, dynamic>? rhythmDna,
    double? listeningHours,
  }) async {
    final client = _client;
    final user = currentUser;

    if (username != null) _mockProfile['username'] = username;
    if (avatarUrl != null) _mockProfile['avatar_url'] = avatarUrl;
    if (rhythmDna != null) _mockProfile['rhythm_dna'] = rhythmDna;
    if (listeningHours != null) _mockProfile['listening_hours'] = listeningHours;

    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) return;

    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (rhythmDna != null) updates['rhythm_dna'] = rhythmDna;
      if (listeningHours != null) updates['listening_hours'] = listeningHours;

      await client.from('profiles').update(updates).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating profile in Supabase: $e');
    }
  }

  // ===========================================================================
  // 3. LIKED SONGS & FAVORITES
  // ===========================================================================

  /// Fetch liked songs for the current user
  Future<List<Map<String, dynamic>>> getLikedSongs() async {
    final client = _client;
    final user = currentUser;

    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) {
      return _mockLikedSongs;
    }

    try {
      final List<dynamic> response = await client
          .from('liked_songs')
          .select()
          .eq('user_id', user.id)
          .order('liked_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching liked songs: $e. Using local data.');
      return _mockLikedSongs;
    }
  }

  /// Toggle liked status for a song in Supabase
  Future<bool> toggleLikeSong(Map<String, dynamic> track) async {
    final client = _client;
    final user = currentUser;
    final String songId = track['id']?.toString() ?? '';

    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) {
      // Local toggling simulation
      final isLiked = _mockLikedSongs.any((s) => s['id']?.toString() == songId);
      if (isLiked) {
        _mockLikedSongs.removeWhere((s) => s['id']?.toString() == songId);
        return false;
      } else {
        _mockLikedSongs.add({
          'id': songId,
          'song_id': songId,
          'title': track['title'] ?? track['name'] ?? 'Track',
          'artist': track['artist'] ?? track['subtitle'] ?? 'Artist',
          'image_url': track['image_url'] ?? '',
          'stream_url': track['stream_url'] ?? '',
          'liked_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    }

    try {
      final existing = await client
          .from('liked_songs')
          .select()
          .eq('user_id', user.id)
          .eq('song_id', songId);

      if (existing.isNotEmpty) {
        await client
            .from('liked_songs')
            .delete()
            .eq('user_id', user.id)
            .eq('song_id', songId);
        return false;
      } else {
        await client.from('liked_songs').insert({
          'user_id': user.id,
          'song_id': songId,
          'title': track['title'] ?? track['name'] ?? 'Unknown',
          'artist': track['artist'] ?? track['subtitle'] ?? 'Unknown Artist',
          'image_url': track['image_url'] ?? '',
          'stream_url': track['stream_url'] ?? '',
          'liked_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling like in Supabase: $e');
      return false;
    }
  }

  // ===========================================================================
  // 4. USER PLAYLISTS
  // ===========================================================================

  /// Get user created playlists
  Future<List<Map<String, dynamic>>> getUserPlaylists() async {
    final client = _client;
    final user = currentUser;

    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) {
      return _mockPlaylists;
    }

    try {
      final List<dynamic> response = await client
          .from('playlists')
          .select('*, playlist_tracks(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching playlists: $e');
      return _mockPlaylists;
    }
  }

  /// Create a new playlist
  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    final client = _client;
    final user = currentUser;

    final newPlaylist = {
      'id': 'pl_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'description': description ?? 'Rytheme Custom Playlist',
      'user_id': user?.id ?? 'guest_user',
      'is_public': isPublic,
      'cover_url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=350',
      'created_at': DateTime.now().toIso8601String(),
      'playlist_tracks': [],
    };

    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) {
      _mockPlaylists.insert(0, newPlaylist);
      return newPlaylist;
    }

    try {
      final response = await client.from('playlists').insert({
        'name': name,
        'description': description ?? '',
        'user_id': user.id,
        'is_public': isPublic,
        'cover_url': newPlaylist['cover_url'],
      }).select().single();
      return response;
    } catch (e) {
      debugPrint('Error creating playlist in Supabase: $e');
      _mockPlaylists.insert(0, newPlaylist);
      return newPlaylist;
    }
  }

  /// Add a track to a playlist
  Future<void> addSongToPlaylist(String playlistId, Map<String, dynamic> song) async {
    final client = _client;
    if (client == null || !RythemeConfig.isSupabaseConfigured) {
      final playlist = _mockPlaylists.firstWhere(
        (p) => p['id'] == playlistId,
        orElse: () => {},
      );
      if (playlist.isNotEmpty) {
        playlist['playlist_tracks'] = (playlist['playlist_tracks'] as List? ?? [])..add(song);
      }
      return;
    }

    try {
      await client.from('playlist_tracks').insert({
        'playlist_id': playlistId,
        'song_id': song['id']?.toString() ?? '',
        'title': song['title'] ?? song['name'] ?? '',
        'artist': song['artist'] ?? song['subtitle'] ?? '',
        'image_url': song['image_url'] ?? '',
        'stream_url': song['stream_url'] ?? '',
        'added_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding song to playlist: $e');
    }
  }

  // ===========================================================================
  // 5. LIVE JAMS & REALTIME SESSIONS
  // ===========================================================================

  /// Fetch active live JAMS
  Future<List<Map<String, dynamic>>> getActiveJams() async {
    final client = _client;
    if (client == null || !RythemeConfig.isSupabaseConfigured) {
      return _mockJams;
    }

    try {
      final List<dynamic> response = await client
          .from('jams')
          .select()
          .eq('is_live', true)
          .order('listeners_count', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching JAMS: $e. Using local simulated JAMS.');
      return _mockJams;
    }
  }

  /// Create a Live JAM in Supabase
  Future<Map<String, dynamic>> createJam({
    required String name,
    required bool isPublic,
    required String hostAvatar,
  }) async {
    final client = _client;
    final user = currentUser;
    final hostName = user?.userMetadata?['username'] ?? _mockProfile['username'] ?? 'Kamlesh';
    final hostId = user?.id ?? 'guest-id';

    final newJam = {
      'name': name,
      'host_id': hostId,
      'host_name': hostName,
      'host_avatar': hostAvatar,
      'listeners_count': 1,
      'is_live': true,
      'is_public': isPublic,
      'current_song': 'Rytheme Jam Opener',
      'current_artist': 'JAMS Host',
      'created_at': DateTime.now().toIso8601String(),
    };

    if (client == null || !RythemeConfig.isSupabaseConfigured) {
      _mockJams.insert(0, newJam);
      return newJam;
    }

    try {
      final response = await client.from('jams').insert(newJam).select().single();
      return response;
    } catch (e) {
      debugPrint('Error creating JAM in Supabase: $e');
      _mockJams.insert(0, newJam);
      return newJam;
    }
  }

  /// Subscribe to Realtime JAM updates
  RealtimeChannel? subscribeToJams(void Function() onUpdate) {
    final client = _client;
    if (client == null || !RythemeConfig.isSupabaseConfigured) return null;

    try {
      final channel = client.channel('public:jams');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'jams',
            callback: (payload) => onUpdate(),
          )
          .subscribe();
      return channel;
    } catch (e) {
      debugPrint('Error subscribing to JAMS realtime: $e');
      return null;
    }
  }

  // ===========================================================================
  // 6. SOUND JOURNAL
  // ===========================================================================

  /// Get Personal Sound Journal Entries
  Future<List<Map<String, dynamic>>> getSoundJournal() async {
    final client = _client;
    final user = currentUser;

    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) {
      return _mockJournal;
    }

    try {
      final List<dynamic> response = await client
          .from('sound_journal')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching journal: $e. Falling back to local entries.');
      return _mockJournal;
    }
  }

  /// Save Sound Journal entry
  Future<void> saveJournalEntry({
    required String note,
    required String songTitle,
    required String artist,
    required String mood,
    String? imageUrl,
  }) async {
    final client = _client;
    final user = currentUser;

    final entry = {
      'id': 'jn_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': user?.id ?? 'guest',
      'note': note,
      'song_title': songTitle,
      'artist': artist,
      'mood': mood,
      'image_url': imageUrl ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };

    if (client == null || user == null || !RythemeConfig.isSupabaseConfigured) {
      _mockJournal.insert(0, entry);
      return;
    }

    try {
      await client.from('sound_journal').insert({
        'user_id': user.id,
        'note': note,
        'song_title': songTitle,
        'artist': artist,
        'mood': mood,
        'image_url': imageUrl ?? '',
      });
    } catch (e) {
      debugPrint('Error saving journal: $e');
      _mockJournal.insert(0, entry);
    }
  }

  // ===========================================================================
  // 7. OFFLINE FALLBACK MOCK DATA
  // ===========================================================================
  static final Map<String, dynamic> _mockProfile = {
    'id': 'usr_mock_01',
    'username': 'Kamlesh',
    'email': 'kamlesh@rytheme.app',
    'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    'listening_hours': 148.5,
    'rhythm_dna': {
      'chill': 42,
      'melodic': 31,
      'energetic': 17,
      'experimental': 10
    }
  };

  static final List<Map<String, dynamic>> _mockLikedSongs = [
    {
      'id': '101',
      'song_id': '101',
      'title': 'Starlight Echoes',
      'artist': 'Ethereal Wave',
      'image_url': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=350',
      'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
    },
    {
      'id': '102',
      'song_id': '102',
      'title': 'Midnight Neon',
      'artist': 'CyberRider',
      'image_url': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=350',
      'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'
    },
    {
      'id': '103',
      'song_id': '103',
      'title': 'Deep Code',
      'artist': 'Synthesized Dreamer',
      'image_url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=350',
      'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'
    }
  ];

  static final List<Map<String, dynamic>> _mockPlaylists = [
    {
      'id': 'pl_1',
      'name': 'Deep Focus Sessions 🎧',
      'description': 'Atmospheric electronic and synthwave for coding.',
      'cover_url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=350',
      'playlist_tracks': []
    },
    {
      'id': 'pl_2',
      'name': 'Midnight Drive 🚗',
      'description': 'Smooth low-tempo lofi and dark synth.',
      'cover_url': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=350',
      'playlist_tracks': []
    }
  ];

  static final List<Map<String, dynamic>> _mockJams = [
    {
      'id': 'jam_1',
      'name': 'Late Night Vibes 🔴',
      'host_name': 'Sarah K.',
      'host_avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      'listeners_count': 12,
      'is_live': true,
      'current_song': 'Slow Burn Synth',
      'current_artist': 'RetroFuture'
    },
    {
      'id': 'jam_2',
      'name': 'Coding Focus Room 💻',
      'host_name': 'Kamlesh (You)',
      'host_avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'listeners_count': 45,
      'is_live': true,
      'current_song': 'Low Pass Chill Lofi',
      'current_artist': 'Mellow Beats'
    },
    {
      'id': 'jam_3',
      'name': 'Techno Odyssey ⚡',
      'host_name': 'DJ Vector',
      'host_avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
      'listeners_count': 89,
      'is_live': true,
      'current_song': 'Frequency Control',
      'current_artist': 'Acid Pulse'
    }
  ];

  static final List<Map<String, dynamic>> _mockJournal = [
    {
      'note': 'Coding this app while listening to synthwave. Perfect atmosphere.',
      'song_title': 'Midnight Neon',
      'artist': 'CyberRider',
      'mood': 'Focus 💻',
      'created_at': '2026-08-25T20:30:00Z'
    },
    {
      'note': 'Rainy night driving music. Makes everything feel like a cinematic movie.',
      'song_title': 'Deep Code',
      'artist': 'Synthesized Dreamer',
      'mood': 'Chill 🌧️',
      'created_at': '2026-08-24T22:15:00Z'
    }
  ];
}
