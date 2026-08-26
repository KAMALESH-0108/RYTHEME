import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../components/visualizer.dart';
import '../services/player_provider.dart';
import '../services/customization_provider.dart';
import '../services/jiosaavn_service.dart';
import 'audio_settings_sheet.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  bool _showLyrics = false;
  String _lyricsText = '';
  List<Map<String, dynamic>> _parsedLyrics = [];
  final ScrollController _lyricsScrollController = ScrollController();
  int _activeLyricIndex = -1;

  // 3D Tilt Coordinates
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _shineOffsetX = 0.0;
  double _shineOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final trackId = playerProvider.currentTrack?['id'] ?? '';
    final rawLyrics = await JioSaavnService.getSongLyrics(trackId);
    
    setState(() {
      _lyricsText = rawLyrics;
      _parsedLyrics = _parseLyrics(rawLyrics);
    });
  }

  List<Map<String, dynamic>> _parseLyrics(String raw) {
    final lines = raw.split('\n');
    final List<Map<String, dynamic>> result = [];
    final regExp = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');

    for (var line in lines) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final milli = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        final totalDuration = Duration(minutes: min, seconds: sec, milliseconds: milli * 10);
        result.add({
          'time': totalDuration,
          'text': text,
        });
      }
    }
    return result;
  }

  void _syncLyrics(Duration currentPos) {
    if (_parsedLyrics.isEmpty || !_showLyrics) return;

    int activeIndex = -1;
    for (int i = 0; i < _parsedLyrics.length; i++) {
      if (currentPos >= _parsedLyrics[i]['time']) {
        activeIndex = i;
      } else {
        break;
      }
    }

    if (activeIndex != -1 && activeIndex != _activeLyricIndex) {
      setState(() {
        _activeLyricIndex = activeIndex;
      });
      
      if (_lyricsScrollController.hasClients) {
        _lyricsScrollController.animateTo(
          activeIndex * 45.0 - 150.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final customProvider = Provider.of<CustomizationProvider>(context);
    final track = playerProvider.currentTrack;

    if (track == null) return const SizedBox.shrink();

    _syncLyrics(playerProvider.position);

    final progressRatio = playerProvider.duration.inSeconds > 0
        ? playerProvider.position.inSeconds / playerProvider.duration.inSeconds
        : 0.0;

    final isLiked = playerProvider.likedSongs.any((s) => s['id'] == track['id']);
    final isDownloaded = playerProvider.downloadedSongs.any((s) => s['id'] == track['id']);
    final activeThemeAccent = customProvider.accentColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background blurred duplicate
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(track['image_url']),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  color: Colors.black.withOpacity(0.82),
                ),
              ),
            ),
          ),
          
          // Ambient theme glow behind artwork
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: MediaQuery.of(context).size.width * 0.15,
            right: MediaQuery.of(context).size.width * 0.15,
            height: MediaQuery.of(context).size.width * 0.7,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeThemeAccent.withOpacity(0.18),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Column(
                        children: [
                          Text('PLAYING FROM PLAYLIST', style: TextStyle(fontSize: 9, color: RythemeTheme.disabledText, letterSpacing: 1.0)),
                          Text('Personal Moment Feed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Center Content (Lyrics or 3D Artwork Card)
                AnimatedCrossFade(
                  firstChild: _build3DArtworkWidget(context, track),
                  secondChild: _buildLyricsWidget(context),
                  crossFadeState: _showLyrics ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 400),
                ),

                const Spacer(),

                // Metadata Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track['title'],
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              track['artist'],
                              style: const TextStyle(fontSize: 15, color: RythemeTheme.secondaryText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? activeThemeAccent : Colors.white,
                          size: 26,
                        ),
                        onPressed: () => playerProvider.toggleLike(track),
                      ),
                      IconButton(
                        icon: Icon(
                          isDownloaded ? Icons.offline_pin : Icons.download_for_offline_outlined,
                          color: isDownloaded ? RythemeTheme.success : Colors.white,
                          size: 26,
                        ),
                        onPressed: () => playerProvider.downloadTrack(track),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Waveform Visualizer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: AudioVisualizer(
                    isPlaying: playerProvider.isPlaying,
                    type: VisualizerType.waveform,
                    height: 40,
                  ),
                ),

                // Progress Bar Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: activeThemeAccent,
                      inactiveTrackColor: Colors.white.withOpacity(0.08),
                      thumbColor: activeThemeAccent,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayColor: activeThemeAccent.withOpacity(0.2),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: progressRatio.clamp(0.0, 1.0),
                      onChanged: (val) {
                        final seconds = (val * playerProvider.duration.inSeconds).toInt();
                        playerProvider.seek(Duration(seconds: seconds));
                      },
                    ),
                  ),
                ),

                // Timers Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(playerProvider.position),
                        style: const TextStyle(fontSize: 11, color: RythemeTheme.disabledText),
                      ),
                      Text(
                        _formatTime(playerProvider.duration),
                        style: const TextStyle(fontSize: 11, color: RythemeTheme.disabledText),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: Colors.white70),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                        onPressed: () => playerProvider.prevTrack(),
                      ),
                      
                      // Play Circular Button
                      GestureDetector(
                        onTap: () => playerProvider.togglePlay(),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 16,
                              )
                            ],
                          ),
                          child: Icon(
                            playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                        onPressed: () => playerProvider.nextTrack(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white70),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const AudioSettingsSheet(),
                          );
                        },
                      ),
                      
                      // Lyrics Switch
                      GestureDetector(
                        onTap: () => setState(() => _showLyrics = !_showLyrics),
                        child: GlassContainer(
                          level: _showLyrics ? GlassLevel.elevated : GlassLevel.soft,
                          hasRedGlow: _showLyrics,
                          glowColor: activeThemeAccent,
                          borderWidth: _showLyrics ? 1.5 : 1.0,
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_outlined,
                                size: 14,
                                color: _showLyrics ? Colors.white : RythemeTheme.secondaryText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lyrics',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _showLyrics ? Colors.white : RythemeTheme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.queue_music, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- 3D TILT GLASS CARD ARTWORK ---
  Widget _build3DArtworkWidget(BuildContext context, Map<String, dynamic> track) {
    final width = MediaQuery.of(context).size.width * 0.76;

    return Center(
      child: GestureDetector(
        onPanUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox;
          final localPos = renderBox.globalToLocal(details.globalPosition);
          final cardCenterWidth = width / 2;
          final cardCenterHeight = width / 2;

          // Compute offsets relative to center (-1.0 to 1.0)
          final normX = ((localPos.dx - cardCenterWidth) / cardCenterWidth).clamp(-1.0, 1.0);
          final normY = ((localPos.dy - cardCenterHeight) / cardCenterHeight).clamp(-1.0, 1.0);

          setState(() {
            // Apply maximum rotation angles (roughly ~15 degrees or 0.26 radians)
            _tiltX = -normY * 0.26;
            _tiltY = normX * 0.26;
            
            // Specular sheen alignment coordinates
            _shineOffsetX = normX;
            _shineOffsetY = normY;
          });
        },
        onPanEnd: (details) {
          // Reset card rotation smoothly
          setState(() {
            _tiltX = 0.0;
            _tiltY = 0.0;
            _shineOffsetX = 0.0;
            _shineOffsetY = 0.0;
          });
        },
        child: Hero(
          tag: 'player_artwork_hero',
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective factor
              ..rotateX(_tiltX)
              ..rotateY(_tiltY),
            alignment: FractionalOffset.center,
            child: Container(
              height: width,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 32,
                    offset: Offset(-_tiltY * 50, _tiltX * 50 + 15), // Shifting shadow direction
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Artwork image
                    Image.network(
                      track['image_url'],
                      fit: BoxFit.cover,
                    ),

                    // speculr reflection sheen overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.0),
                            ],
                            begin: Alignment(_shineOffsetX - 1.5, _shineOffsetY - 1.5),
                            end: Alignment(_shineOffsetX + 1.5, _shineOffsetY + 1.5),
                            stops: const [0.35, 0.5, 0.65],
                          ),
                        ),
                      ),
                    ),

                    // Translucent glass border overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsWidget(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.84;
    final height = MediaQuery.of(context).size.height * 0.40;

    return Center(
      child: GlassContainer(
        level: GlassLevel.elevated,
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: _parsedLyrics.isEmpty
            ? const Center(
                child: Text('Loading synced lyrics...', style: TextStyle(color: RythemeTheme.secondaryText)),
              )
            : ListView.builder(
                controller: _lyricsScrollController,
                itemCount: _parsedLyrics.length,
                itemBuilder: (context, index) {
                  final item = _parsedLyrics[index];
                  final isActive = index == _activeLyricIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      item['text'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isActive ? 17 : 14,
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                        color: isActive ? Colors.white : RythemeTheme.disabledText,
                        shadows: [
                          if (isActive)
                            Shadow(
                              color: RythemeTheme.primaryRed.withOpacity(0.8),
                              blurRadius: 10,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatTime(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
