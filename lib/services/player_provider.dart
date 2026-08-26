import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'supabase_service.dart';
import 'jiosaavn_service.dart';

class PlayerProvider with ChangeNotifier {
  // Services
  final SupabaseService _supabase = SupabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Playback States
  Map<String, dynamic>? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 3);
  List<Map<String, dynamic>> _queue = [];
  int _currentIndex = 0;

  // App & Services States
  List<Map<String, dynamic>> _likedSongs = [];
  List<Map<String, dynamic>> _activeJams = [];
  List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _downloadedSongs = [];
  Map<String, double> _downloadProgress = {}; // trackId -> progress (0.0 to 1.0)
  
  // Storage Tracker
  double _storageUsedGb = 1.4;
  final double _storageAvailableGb = 6.2;
  bool _wifiOnly = true;

  // Equalizer Bands (Hz: 60, 230, 910, 4K, 14K)
  List<double> _equalizerBands = [0.0, 0.0, 0.0, 0.0, 0.0];

  // Rhythm AI Chat Logs
  List<Map<String, dynamic>> _aiMessages = [
    {
      'role': 'assistant',
      'text': 'Find your sound, Kamlesh. Ask me to generate any mood, playlist or find a specific vibe for your moment.',
      'time': 'Just now',
    }
  ];

  // Dynamic In-App Notifications Center
  final List<Map<String, dynamic>> _notifications = [
    {
      'category': 'Music',
      'title': 'New Release Drop',
      'desc': 'Your favorite artist CyberRider just dropped a new synthwave track: "Midnight Neon".',
      'time': '10 mins ago',
      'unread': true,
      'icon': Icons.music_note_outlined,
    },
    {
      'category': 'Social',
      'title': 'JAMS Update',
      'desc': 'Host setup checked. Ready for streaming audio.',
      'time': '1 hour ago',
      'unread': false,
      'icon': Icons.group_outlined,
    }
  ];

  // Settings
  bool _isOfflineMode = false;
  bool _hapticsEnabled = true;

  // Timers (for safety fallback / progress checks)
  Timer? _positionTimer;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _compSub;

  // Getters
  Map<String, dynamic>? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  List<Map<String, dynamic>> get queue => _queue;
  List<Map<String, dynamic>> get likedSongs => _likedSongs;
  List<Map<String, dynamic>> get activeJams => _activeJams;
  List<Map<String, dynamic>> get journalEntries => _journalEntries;
  List<Map<String, dynamic>> get downloadedSongs => _downloadedSongs;
  Map<String, double> get downloadProgress => _downloadProgress;
  double get storageUsedGb => _storageUsedGb;
  double get storageAvailableGb => _storageAvailableGb;
  bool get wifiOnly => _wifiOnly;
  List<double> get equalizerBands => _equalizerBands;
  List<Map<String, dynamic>> get aiMessages => _aiMessages;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isOfflineMode => _isOfflineMode;
  bool get hapticsEnabled => _hapticsEnabled;

  PlayerProvider() {
    _initAudioListeners();
    refreshBackendData();
  }

  void _initAudioListeners() {
    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _compSub = _audioPlayer.onPlayerComplete.listen((event) {
      nextTrack();
    });
  }

  // Push notification helper
  void pushNotification({
    required String title,
    required String desc,
    required String category,
    required IconData icon,
  }) {
    _notifications.insert(0, {
      'category': category,
      'title': title,
      'desc': desc,
      'time': 'Just now',
      'unread': true,
      'icon': icon,
    });
    notifyListeners();
  }

  // Clear unread indicator
  void markNotificationsAsRead() {
    for (var n in _notifications) {
      n['unread'] = false;
    }
    notifyListeners();
  }

  Future<void> refreshBackendData() async {
    _likedSongs = await _supabase.getLikedSongs();
    _activeJams = await _supabase.getActiveJams();
    _journalEntries = await _supabase.getSoundJournal();
    notifyListeners();
  }

  // Core Play Controls
  Future<void> playTrack(Map<String, dynamic> track, {List<Map<String, dynamic>>? newQueue}) async {
    _currentTrack = track;
    _isPlaying = true;
    _position = Duration.zero;
    _duration = Duration(seconds: track['duration'] ?? 180);

    if (newQueue != null && newQueue.isNotEmpty) {
      _queue = newQueue;
      _currentIndex = _queue.indexWhere((t) => t['id'] == track['id']);
      if (_currentIndex == -1) _currentIndex = 0;
    } else if (!_queue.any((t) => t['id'] == track['id'])) {
      _queue.insert(0, track);
      _currentIndex = 0;
    }

    notifyListeners();

    try {
      if (_isOfflineMode) {
        _startSimulatedPlayer();
        return;
      }

      await _audioPlayer.stop();
      final streamUrl = track['stream_url'] ?? '';
      if (streamUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(streamUrl));
      } else {
        _startSimulatedPlayer();
      }
    } catch (e) {
      debugPrint('Playback engine error: $e. Falling back to simulation.');
      _startSimulatedPlayer();
    }
  }

  void _startSimulatedPlayer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      if (_position.inSeconds >= _duration.inSeconds) {
        timer.cancel();
        nextTrack();
      } else {
        _position += const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  Future<void> togglePlay() async {
    if (_currentTrack == null) {
      final trending = await JioSaavnService.getTrendingSongs();
      if (trending.isNotEmpty) {
        playTrack(trending.first, newQueue: trending);
      }
      return;
    }

    _isPlaying = !_isPlaying;
    notifyListeners();

    try {
      if (_isPlaying) {
        if (_isOfflineMode || _currentTrack?['stream_url'] == '') {
          _startSimulatedPlayer();
        } else {
          await _audioPlayer.resume();
        }
      } else {
        _positionTimer?.cancel();
        await _audioPlayer.pause();
      }
    } catch (e) {
      debugPrint('Error toggling play: $e');
    }
  }

  void nextTrack() {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    playTrack(_queue[_currentIndex]);
  }

  void prevTrack() {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    playTrack(_queue[_currentIndex]);
  }

  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
    try {
      if (!_isOfflineMode && _currentTrack?['stream_url'] != '') {
        await _audioPlayer.seek(position);
      }
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  // Toggle Song Like status (sync with Supabase)
  Future<void> toggleLike(Map<String, dynamic> track) async {
    final wasLiked = _likedSongs.any((s) => s['id'] == track['id']);
    await _supabase.toggleLikeSong(track);
    await refreshBackendData();
    
    // Push Dynamic Notification
    pushNotification(
      title: wasLiked ? 'Removed from Liked' : 'Song Liked',
      desc: '"${track['title']}" was ${wasLiked ? 'removed from' : 'added to'} your favorites.',
      category: 'Music',
      icon: wasLiked ? Icons.favorite_border : Icons.favorite,
    );
  }

  // Simulate Downloading Track
  Future<void> downloadTrack(Map<String, dynamic> track) async {
    final trackId = track['id'].toString();
    if (_downloadProgress.containsKey(trackId) || _downloadedSongs.any((s) => s['id'] == trackId)) {
      return;
    }

    _downloadProgress[trackId] = 0.0;
    notifyListeners();

    // Push initial downloading notice
    pushNotification(
      title: 'Downloading Cache',
      desc: '"${track['title']}" has started downloading offline.',
      category: 'Personal',
      icon: Icons.downloading,
    );

    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_downloadProgress[trackId]! >= 1.0) {
        timer.cancel();
        _downloadProgress.remove(trackId);
        _downloadedSongs.add(track);
        _storageUsedGb += 0.015;
        notifyListeners();

        // Push completed download notice
        pushNotification(
          title: 'Download Successful',
          desc: '"${track['title']}" was successfully cached and is ready offline.',
          category: 'Personal',
          icon: Icons.download_done,
        );
      } else {
        _downloadProgress[trackId] = _downloadProgress[trackId]! + 0.2; // faster simulation
        notifyListeners();
      }
    });
  }

  // Create active JAM in Supabase
  Future<void> createNewJam(String name, bool isPublic) async {
    final newJam = await _supabase.createJam(
      name: name,
      isPublic: isPublic,
      hostAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
    );
    _activeJams.insert(0, newJam);
    notifyListeners();

    // Push social notice
    pushNotification(
      title: 'JAMS Room Created',
      desc: 'You are now hosting "${newJam['name']}" live with participants.',
      category: 'Social',
      icon: Icons.radio,
    );
  }

  // Send input to Rhythm AI
  Future<void> askRhythmAI(String prompt) async {
    if (prompt.trim().isEmpty) return;

    _aiMessages.add({
      'role': 'user',
      'text': prompt,
      'time': 'Just now',
    });
    notifyListeners();

    pushNotification(
      title: 'Rhythm AI Query',
      desc: 'AI is analyzing your acoustic query: "$prompt".',
      category: 'Personal',
      icon: Icons.auto_awesome,
    );

    Future.delayed(const Duration(seconds: 1), () async {
      String responseText = '';
      List<Map<String, dynamic>> recommendations = [];

      final query = prompt.toLowerCase();
      if (query.contains('chill') || query.contains('sleep') || query.contains('relax')) {
        responseText = 'Generating a soft glass-ambient playlist for relaxing. Enjoy these lofi tunes:';
        recommendations = await JioSaavnService.searchSongs('lofi chill');
      } else if (query.contains('code') || query.contains('study') || query.contains('focus')) {
        responseText = 'Here is your Rhythm Focus DNA playlist. Designed to maximize deep coding flow:';
        recommendations = await JioSaavnService.searchSongs('synthwave');
      } else if (query.contains('workout') || query.contains('energy') || query.contains('run')) {
        responseText = 'Injecting crimson energetic frequencies. Elevate your pulse with:';
        recommendations = await JioSaavnService.searchSongs('workout');
      } else {
        responseText = 'I analyzed your Rhythm DNA. Here is a custom sonic capsule matched to "$prompt":';
        recommendations = await JioSaavnService.getTrendingSongs();
      }

      _aiMessages.add({
        'role': 'assistant',
        'text': responseText,
        'time': 'Just now',
        'recommendations': recommendations.take(3).toList(),
      });
      notifyListeners();

      // Push recommendations ready notice
      pushNotification(
        title: 'Acoustic Matches Ready',
        desc: 'Rhythm AI generated custom suggestions for your moment.',
        category: 'Music',
        icon: Icons.auto_awesome_motion,
      );
    });
  }

  // Write Sound Journal entry
  Future<void> addJournalEntry(String note, String song, String artist, String mood) async {
    await _supabase.saveJournalEntry(
      note: note,
      songTitle: song,
      artist: artist,
      mood: mood,
    );
    await refreshBackendData();

    // Push personal notice
    pushNotification(
      title: 'Sound Journal Written',
      desc: 'Saved new entry for "$song" associated with mood "$mood".',
      category: 'Personal',
      icon: Icons.book,
    );
  }

  // Settings updates
  void setEqualizerBand(int index, double value) {
    if (index >= 0 && index < _equalizerBands.length) {
      _equalizerBands[index] = value;
      notifyListeners();
    }
  }

  void toggleOfflineMode(bool enabled) {
    _isOfflineMode = enabled;
    if (_isOfflineMode && _isPlaying) {
      _audioPlayer.stop();
      _startSimulatedPlayer();
    } else if (!_isOfflineMode && _isPlaying && _currentTrack != null) {
      playTrack(_currentTrack!);
    }
    notifyListeners();

    // Push system notice
    pushNotification(
      title: _isOfflineMode ? 'Entered Offline Mode' : 'Connected to Network',
      desc: _isOfflineMode 
          ? 'Streaming audio is muted. Only cached downloads will play.' 
          : 'Connecting to JioSaavn API database stream.',
      category: 'Personal',
      icon: _isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
    );
  }

  void setWifiOnly(bool enabled) {
    _wifiOnly = enabled;
    notifyListeners();
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
    notifyListeners();
  }

  void clearAllDownloads() {
    _downloadedSongs.clear();
    _storageUsedGb = 0.05;
    notifyListeners();
    
    pushNotification(
      title: 'Downloads Flushed',
      desc: 'All cached audio files were deleted. Storage freed.',
      category: 'Personal',
      icon: Icons.delete_sweep,
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _compSub?.cancel();
    _positionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
