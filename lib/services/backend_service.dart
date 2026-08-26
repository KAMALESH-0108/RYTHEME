import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'supabase_service.dart';
import 'jiosaavn_service.dart';

// Re-export services & config for clean one-line backend imports
export '../config.dart';
export 'supabase_service.dart';
export 'jiosaavn_service.dart';

/// Unified Backend Controller for Rytheme.
/// Coordinates Cloud Supabase (PostgreSQL, Auth, Realtime) and JioSaavn Music API.
class BackendService {
  // Singleton pattern
  static final BackendService _instance = BackendService._internal();
  static BackendService get instance => _instance;

  BackendService._internal();

  // Core Sub-services
  final SupabaseService supabase = SupabaseService();
  final JioSaavnService saavn = JioSaavnService();

  // Backend state flags
  bool _isInitialized = false;
  bool _supabaseConnected = false;
  bool _saavnConnected = false;

  bool get isInitialized => _isInitialized;
  bool get isSupabaseConnected => _supabaseConnected;
  bool get isSaavnConnected => _saavnConnected;
  bool get isLiveBackend => _supabaseConnected && RythemeConfig.isSupabaseConfigured;

  // ===========================================================================
  // 1. INITIALIZATION & LIFECYCLE
  // ===========================================================================

  /// Initialize the complete backend infrastructure
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('Initializing Rytheme Backend Services...');

    // 1. Initialize Supabase
    try {
      if (RythemeConfig.isSupabaseConfigured) {
        await Supabase.initialize(
          url: RythemeConfig.supabaseUrl,
          anonKey: RythemeConfig.supabaseAnonKey,
          debug: kDebugMode,
        );
        _supabaseConnected = true;
        debugPrint('Supabase connected successfully to: ${RythemeConfig.supabaseUrl}');
      } else {
        debugPrint('Supabase credentials are placeholder tokens. Running in offline sandbox mode.');
        _supabaseConnected = false;
      }
    } catch (e) {
      debugPrint('Supabase initialization failed: $e. Fallback to offline mode enabled.');
      _supabaseConnected = false;
    }

    // 2. Test JioSaavn API Connectivity
    try {
      final ping = await JioSaavnService.getTrendingSongs();
      _saavnConnected = ping.isNotEmpty;
      debugPrint('JioSaavn API connected: $_saavnConnected (URL: ${RythemeConfig.jioSaavnApiUrl})');
    } catch (e) {
      _saavnConnected = false;
      debugPrint('JioSaavn API connection failed: $e. Using local offline music catalog.');
    }

    _isInitialized = true;
  }

  // ===========================================================================
  // 2. HEALTH & DIAGNOSTICS
  // ===========================================================================

  /// Check health of all backend endpoints
  Future<Map<String, dynamic>> checkHealth() async {
    bool saavnOk = false;
    bool supabaseOk = false;

    try {
      final songs = await JioSaavnService.searchSongs('test', limit: 1);
      saavnOk = songs.isNotEmpty;
    } catch (_) {
      saavnOk = false;
    }

    try {
      if (RythemeConfig.isSupabaseConfigured) {
        final profile = await supabase.getUserProfile();
        supabaseOk = profile.isNotEmpty;
      }
    } catch (_) {
      supabaseOk = false;
    }

    return {
      'status': 'healthy',
      'supabase_configured': RythemeConfig.isSupabaseConfigured,
      'supabase_connected': supabaseOk,
      'supabase_url': RythemeConfig.supabaseUrl,
      'saavn_api_url': RythemeConfig.jioSaavnApiUrl,
      'saavn_api_connected': saavnOk,
      'has_saavn_api_key': RythemeConfig.jioSaavnApiKey.isNotEmpty,
      'mode': (supabaseOk && saavnOk) ? 'Live Cloud' : 'Offline / Mock Sandbox',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ===========================================================================
  // 3. UNIFIED HIGH-LEVEL DATA METHODS
  // ===========================================================================

  /// Unified search across songs, albums, and playlists
  Future<Map<String, dynamic>> searchAll(String query) async {
    try {
      final results = await Future.wait([
        JioSaavnService.searchSongs(query, limit: 15),
        JioSaavnService.searchAlbums(query),
        JioSaavnService.searchPlaylists(query),
      ]);

      return {
        'songs': results[0],
        'albums': results[1],
        'playlists': results[2],
      };
    } catch (e) {
      debugPrint('BackendService searchAll error: $e');
      final fallbackSongs = await JioSaavnService.searchSongs(query);
      return {
        'songs': fallbackSongs,
        'albums': [],
        'playlists': [],
      };
    }
  }

  /// Sync all user data in parallel (profile, likes, playlists, journals)
  Future<Map<String, dynamic>> syncUserData() async {
    try {
      final results = await Future.wait([
        supabase.getUserProfile(),
        supabase.getLikedSongs(),
        supabase.getUserPlaylists(),
        supabase.getSoundJournal(),
        supabase.getActiveJams(),
      ]);

      return {
        'profile': results[0] as Map<String, dynamic>,
        'liked_songs': results[1] as List<Map<String, dynamic>>,
        'playlists': results[2] as List<Map<String, dynamic>>,
        'sound_journal': results[3] as List<Map<String, dynamic>>,
        'active_jams': results[4] as List<Map<String, dynamic>>,
      };
    } catch (e) {
      debugPrint('BackendService syncUserData error: $e');
      return {};
    }
  }

  /// Toggle song like status
  Future<bool> toggleLike(Map<String, dynamic> track) async {
    return await supabase.toggleLikeSong(track);
  }

  /// Fetch full track metadata & verified 320kbps stream URL
  Future<Map<String, dynamic>?> resolveTrackAudio(Map<String, dynamic> track) async {
    final String songId = track['id']?.toString() ?? '';
    if (songId.isEmpty) return track;

    // Check if track already has a valid stream URL
    if (track['stream_url'] != null && track['stream_url'].toString().isNotEmpty) {
      return track;
    }

    final fullDetails = await JioSaavnService.getSongDetails(songId);
    return fullDetails ?? track;
  }
}

/// Shorthand alias
final RythemeBackend = BackendService.instance;
