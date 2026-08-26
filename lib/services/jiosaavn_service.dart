import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config.dart';

/// Service for communicating with the JioSaavn Open-Source API
/// Compatible with public instances (e.g., https://saavn.dev) and self-hosted instances.
class JioSaavnService {
  static String get _baseUrl => RythemeConfig.jioSaavnApiUrl;
  static Map<String, String> get _headers => RythemeConfig.getSaavnHeaders();
  static Duration get _timeout => Duration(seconds: RythemeConfig.requestTimeoutSeconds);

  // ===========================================================================
  // 1. SONG SEARCH & DETAILS
  // ===========================================================================

  /// Search songs by query string with pagination support
  static Future<List<Map<String, dynamic>>> searchSongs(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/search/songs?query=${Uri.encodeComponent(query)}&page=$page&limit=$limit',
      );

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> results = body['data']['results'] ?? [];
          return _parseSongsList(results);
        }
      }
      return _getFallbackSongs(query);
    } catch (e) {
      debugPrint('JioSaavn searchSongs error: $e. Using offline catalog.');
      return _getFallbackSongs(query);
    }
  }

  /// Fetch full metadata & 320kbps audio link for a specific song ID
  static Future<Map<String, dynamic>?> getSongDetails(String songId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/songs?id=$songId');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> results = body['data'] is List ? body['data'] : [body['data']];
          if (results.isNotEmpty) {
            return _parseSongItem(results.first);
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('JioSaavn getSongDetails error: $e');
      return null;
    }
  }

  /// Fetch trending songs for the Home screen
  static Future<List<Map<String, dynamic>>> getTrendingSongs() async {
    try {
      // Query trending / global chart endpoint
      final uri = Uri.parse('$_baseUrl/api/search/songs?query=trending&limit=20');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> results = body['data']['results'] ?? [];
          if (results.isNotEmpty) {
            return _parseSongsList(results);
          }
        }
      }
      return _getTrendingFallback();
    } catch (e) {
      debugPrint('JioSaavn getTrendingSongs error: $e. Using local catalog.');
      return _getTrendingFallback();
    }
  }

  /// Fetch song recommendations / related tracks based on a given song ID
  static Future<List<Map<String, dynamic>>> getSongRecommendations(String songId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/songs/$songId/suggestions?limit=10');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> results = body['data'] ?? [];
          return _parseSongsList(results);
        }
      }
      return _getTrendingFallback().reversed.toList();
    } catch (e) {
      debugPrint('JioSaavn recommendations error: $e');
      return _getTrendingFallback().reversed.toList();
    }
  }

  // ===========================================================================
  // 2. ALBUMS, PLAYLISTS & ARTISTS
  // ===========================================================================

  /// Search albums
  static Future<List<Map<String, dynamic>>> searchAlbums(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/search/albums?query=${Uri.encodeComponent(query)}');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> results = body['data']['results'] ?? [];
          return results.map((a) => {
            'id': a['id']?.toString() ?? '',
            'title': a['name'] ?? a['title'] ?? '',
            'artist': a['primaryArtists'] ?? a['artist'] ?? '',
            'year': a['year']?.toString() ?? '',
            'image_url': _extractBestImage(a['image']),
            'song_count': a['songCount'] ?? 0,
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('JioSaavn searchAlbums error: $e');
      return [];
    }
  }

  /// Get album details with tracklist
  static Future<Map<String, dynamic>?> getAlbumDetails(String albumId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/albums?id=$albumId');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final List<dynamic> songsRaw = data['songs'] ?? [];
          return {
            'id': data['id']?.toString() ?? '',
            'title': data['name'] ?? data['title'] ?? '',
            'artist': data['primaryArtists'] ?? '',
            'year': data['year']?.toString() ?? '',
            'image_url': _extractBestImage(data['image']),
            'songs': _parseSongsList(songsRaw),
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('JioSaavn getAlbumDetails error: $e');
      return null;
    }
  }

  /// Search playlists
  static Future<List<Map<String, dynamic>>> searchPlaylists(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/search/playlists?query=${Uri.encodeComponent(query)}');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> results = body['data']['results'] ?? [];
          return results.map((p) => {
            'id': p['id']?.toString() ?? '',
            'title': p['name'] ?? p['title'] ?? '',
            'subtitle': p['subtitle'] ?? '',
            'song_count': p['songCount'] ?? 0,
            'image_url': _extractBestImage(p['image']),
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('JioSaavn searchPlaylists error: $e');
      return [];
    }
  }

  /// Get playlist details and tracks
  static Future<Map<String, dynamic>?> getPlaylistDetails(String playlistId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/playlists?id=$playlistId');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final List<dynamic> songsRaw = data['songs'] ?? [];
          return {
            'id': data['id']?.toString() ?? '',
            'title': data['name'] ?? data['title'] ?? '',
            'subtitle': data['subtitle'] ?? '',
            'image_url': _extractBestImage(data['image']),
            'songs': _parseSongsList(songsRaw),
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('JioSaavn getPlaylistDetails error: $e');
      return null;
    }
  }

  // ===========================================================================
  // 3. LYRICS & PARSING HELPERS
  // ===========================================================================

  /// Fetch lyrics text for a song ID
  static Future<String> getSongLyrics(String songId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/songs/$songId/lyrics');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final lyrics = body['data']['lyrics'];
          if (lyrics != null && lyrics.toString().trim().isNotEmpty) {
            return lyrics.toString();
          }
        }
      }
      return _getFallbackLyrics(songId);
    } catch (e) {
      debugPrint('JioSaavn lyrics error: $e. Using fallback lyrics.');
      return _getFallbackLyrics(songId);
    }
  }

  /// Parser helper for list of raw API song objects
  static List<Map<String, dynamic>> _parseSongsList(List<dynamic> rawList) {
    return rawList.map((item) => _parseSongItem(item)).toList();
  }

  /// Parses an individual song object with standard Rytheme attributes
  static Map<String, dynamic> _parseSongItem(dynamic item) {
    final String highResImage = _extractBestImage(item['image']);
    final String streamUrl = _extractBestStreamUrl(item['downloadUrl']);

    String artistName = item['primaryArtists'] ?? item['subtitle'] ?? '';
    if (artistName.isEmpty && item['artists'] != null) {
      final artistsMap = item['artists'];
      if (artistsMap is Map) {
        final primaryList = artistsMap['primary'];
        if (primaryList is List && primaryList.isNotEmpty) {
          artistName = primaryList.map((a) => a['name']?.toString() ?? '').where((n) => n.isNotEmpty).join(', ');
        } else {
          final allList = artistsMap['all'];
          if (allList is List && allList.isNotEmpty) {
            artistName = allList.map((a) => a['name']?.toString() ?? '').where((n) => n.isNotEmpty).join(', ');
          }
        }
      }
    }
    if (artistName.isEmpty) artistName = 'Unknown Artist';

    return {
      'id': item['id']?.toString() ?? '',
      'title': _decodeHtmlEntities(item['name'] ?? item['title'] ?? 'Unknown Track'),
      'artist': _decodeHtmlEntities(artistName),
      'album': _decodeHtmlEntities(item['album'] is Map ? item['album']['name'] ?? 'Single' : (item['album']?.toString() ?? 'Single')),
      'image_url': highResImage,
      'stream_url': streamUrl,
      'duration': item['duration'] != null ? int.tryParse(item['duration'].toString()) ?? 180 : 180,
      'year': item['year']?.toString() ?? '',
      'language': item['language'] ?? 'English',
      'has_lyrics': item['hasLyrics'] == 'true' || item['hasLyrics'] == true,
    };
  }

  /// Helper: Extracts the highest resolution image available (e.g. 500x500)
  static String _extractBestImage(dynamic images) {
    const defaultImage = 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500';
    if (images is List && images.isNotEmpty) {
      // JioSaavn API usually orders images 50x50 -> 150x150 -> 500x500
      final last = images.last;
      if (last is Map) {
        return last['url'] ?? last['link'] ?? defaultImage;
      }
      if (last is String) return last;
      final first = images.first;
      if (first is Map) {
        return first['url'] ?? first['link'] ?? defaultImage;
      }
      if (first is String) return first;
    } else if (images is String && images.isNotEmpty) {
      return images;
    }
    return defaultImage;
  }

  /// Helper: Extracts the highest bitrate stream URL (e.g. 320kbps / 160kbps)
  static String _extractBestStreamUrl(dynamic downloadUrls) {
    const defaultStream = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    if (downloadUrls is List && downloadUrls.isNotEmpty) {
      // 320kbps is typically at the end of the array
      final last = downloadUrls.last;
      if (last is Map) {
        return last['url'] ?? last['link'] ?? defaultStream;
      }
      if (last is String) return last;
      final first = downloadUrls.first;
      if (first is Map) {
        return first['url'] ?? first['link'] ?? defaultStream;
      }
      if (first is String) return first;
    } else if (downloadUrls is String && downloadUrls.isNotEmpty) {
      return downloadUrls;
    }
    return defaultStream;
  }

  /// Clean HTML entities like &quot;, &amp;, &#039;
  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  // ===========================================================================
  // 4. OFFLINE FALLBACK CATALOG
  // ===========================================================================
  static List<Map<String, dynamic>> _getTrendingFallback() {
    return [
      {
        'id': 'trend_1',
        'title': 'Aesthetic Frequency',
        'artist': 'Kamlesh & The Rhythms',
        'album': 'Design DNA',
        'image_url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
        'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        'duration': 372,
        'year': '2026',
        'language': 'Instrumental',
        'has_lyrics': true,
      },
      {
        'id': 'trend_2',
        'title': 'Silicon Valley Dreams',
        'artist': 'Antigravity Ensemble',
        'album': 'Deep Coding Waves',
        'image_url': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=500',
        'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        'duration': 423,
        'year': '2026',
        'language': 'Synthwave',
        'has_lyrics': true,
      },
      {
        'id': 'trend_3',
        'title': 'Red Energy Pulse',
        'artist': 'Glassmorphism Project',
        'album': 'Dark Translucence',
        'image_url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
        'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        'duration': 302,
        'year': '2026',
        'language': 'Electronic',
        'has_lyrics': true,
      },
      {
        'id': 'trend_4',
        'title': 'Neon Raindust',
        'artist': 'Lofi Sleepers',
        'album': 'Quiet Hours Vol. 4',
        'image_url': 'https://images.unsplash.com/photo-1483412033650-1015ddeb83d1?w=500',
        'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        'duration': 288,
        'year': '2026',
        'language': 'Lofi',
        'has_lyrics': true,
      }
    ];
  }

  static List<Map<String, dynamic>> _getFallbackSongs(String query) {
    final lowerQ = query.toLowerCase();
    final all = _getTrendingFallback() + [
      {
        'id': 'search_1',
        'title': 'Chill Lofi Session',
        'artist': 'Mellow Keys',
        'album': 'Study Beats',
        'image_url': 'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=500',
        'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        'duration': 240,
        'year': '2026',
        'language': 'Lofi',
        'has_lyrics': true,
      },
      {
        'id': 'search_2',
        'title': 'Aggressive Workout Beats',
        'artist': 'Viper Core',
        'album': 'Maximum Heartrate',
        'image_url': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500',
        'stream_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        'duration': 310,
        'year': '2026',
        'language': 'EDM',
        'has_lyrics': true,
      }
    ];

    final matched = all.where((song) =>
      song['title'].toLowerCase().contains(lowerQ) ||
      song['artist'].toLowerCase().contains(lowerQ) ||
      song['album'].toLowerCase().contains(lowerQ)
    ).toList();

    return matched.isNotEmpty ? matched : all;
  }

  static String _getFallbackLyrics(String id) {
    return '''
[00:00.00] Find your sound. Feel your moment.
[00:08.00] Welcome to the RYTHEME universe...
[00:15.00] Driving through the neon shadows,
[00:22.00] With red lights painting all the lines.
[00:30.00] Translucent sheets of glass reflect,
[00:38.00] The rhythm pulsing through our eyes.
[00:46.00] (Bridge - Glass Layers Humming)
[00:58.00] Do you hear the code of the frequency?
[01:05.00] Floating above the silent base.
[01:12.00] It's where your rhythm lives tonight,
[01:20.00] Frozen in this glassmorphic space.
[01:32.00] Turn it up, feel the crimson heat,
[01:40.00] There is no yesterday, no tomorrow...
[01:48.00] Just this moment, looping on and on.
[02:00.00] (Outro - Echoes Fade Out)
''';
  }
}
