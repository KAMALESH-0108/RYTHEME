import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/player_provider.dart';
import '../services/jiosaavn_service.dart';
import 'notifications_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMood = 'Coding';
  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;

  final List<String> _moods = [
    'Chill',
    'Focus',
    'Workout',
    'Coding',
    'Night Drive',
    'Study',
    'Sleep',
    'Party'
  ];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    // Dynamic query based on mood selection
    final results = await JioSaavnService.searchSongs(_selectedMood);
    setState(() {
      _songs = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final size = MediaQuery.of(context).size;

    // Featured song (first from list)
    final Map<String, dynamic>? heroSong = _songs.isNotEmpty ? _songs.first : null;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background managed by AppShell
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 140), // clear navigation capsules
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (Greet + Notification Badge)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good evening,',
                          style: TextStyle(color: RythemeTheme.secondaryText.withOpacity(0.6), fontSize: 14),
                        ),
                        const Text(
                          'Kamlesh',
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    
                    // Notification Icon with Glass base
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => const NotificationsSheet(),
                        );
                      },
                      child: GlassContainer(
                        level: GlassLevel.soft,
                        padding: const EdgeInsets.all(10),
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                height: 8,
                                width: 8,
                                decoration: const BoxDecoration(
                                  color: RythemeTheme.brightRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mood chips ("Your Moment")
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  'Your Moment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: _moods.length,
                  itemBuilder: (context, index) {
                    final mood = _moods[index];
                    final isSelected = mood == _selectedMood;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMood = mood;
                          });
                          _loadSongs();
                        },
                        child: GlassContainer(
                          level: isSelected ? GlassLevel.elevated : GlassLevel.soft,
                          hasRedGlow: isSelected,
                          glowColor: RythemeTheme.primaryRed,
                          borderWidth: isSelected ? 1.5 : 1.0,
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Text(
                            mood,
                            style: TextStyle(
                              color: isSelected ? Colors.white : RythemeTheme.secondaryText,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Hero Music Card
              if (heroSong != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: RythemeTheme.primaryRed.withOpacity(0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Album Artwork Background
                            Image.network(
                              heroSong['image_url'],
                              fit: BoxFit.cover,
                            ),
                            // Black translucent cinematic overlay gradient
                            Container(
                              decoration: const BoxDecoration(
                                gradient: RythemeTheme.redOverlayGradient,
                              ),
                            ),
                            
                            // Hero overlay text & play actions
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: RythemeTheme.primaryRed.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'HOT TODAY',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    heroSong['title'],
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    heroSong['artist'],
                                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      // Play Featured
                                      ElevatedButton.icon(
                                        onPressed: () => playerProvider.playTrack(heroSong, newQueue: _songs),
                                        icon: const Icon(Icons.play_arrow, size: 18),
                                        label: const Text('Play Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Like Button
                                      _buildHeroIcon(
                                        icon: playerProvider.likedSongs.any((s) => s['id'] == heroSong['id'])
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        iconColor: playerProvider.likedSongs.any((s) => s['id'] == heroSong['id'])
                                            ? RythemeTheme.brightRed
                                            : Colors.white,
                                        onTap: () => playerProvider.toggleLike(heroSong),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Download Button
                                      _buildHeroIcon(
                                        icon: playerProvider.downloadedSongs.any((s) => s['id'] == heroSong['id'])
                                            ? Icons.check_circle_outline
                                            : Icons.download_for_offline_outlined,
                                        iconColor: playerProvider.downloadedSongs.any((s) => s['id'] == heroSong['id'])
                                            ? RythemeTheme.success
                                            : Colors.white,
                                        onTap: () {
                                          playerProvider.downloadTrack(heroSong);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Downloading: ${heroSong['title']}'),
                                              backgroundColor: RythemeTheme.darkCrimson,
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Fresh Drops
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Fresh Drops',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 12),
              
              _isLoading
                  ? _buildSkeletonLoader()
                  : SizedBox(
                      height: 175,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final track = _songs[index];
                          // Skip hero song in list
                          if (index == 0) return const SizedBox.shrink();
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => playerProvider.playTrack(track, newQueue: _songs),
                              child: Container(
                                width: 120,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        track['image_url'],
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      track['title'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      track['artist'],
                                      style: const TextStyle(color: RythemeTheme.secondaryText, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              
              const SizedBox(height: 16),
              
              // Because You Loved This
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Because You Loved This',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 12),

              _isLoading
                  ? _buildListSkeleton()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _songs.length > 5 ? 4 : _songs.length,
                      itemBuilder: (context, index) {
                        final track = _songs[index];
                        final isPlayingThis = playerProvider.currentTrack?['id'] == track['id'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => playerProvider.playTrack(track, newQueue: _songs),
                            child: GlassContainer(
                              level: GlassLevel.soft,
                              borderRadius: BorderRadius.circular(16),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      track['image_url'],
                                      height: 48,
                                      width: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track['title'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isPlayingThis ? RythemeTheme.brightRed : Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          track['artist'],
                                          style: const TextStyle(color: RythemeTheme.secondaryText, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      playerProvider.likedSongs.any((s) => s['id'] == track['id'])
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: playerProvider.likedSongs.any((s) => s['id'] == track['id'])
                                          ? RythemeTheme.brightRed
                                          : RythemeTheme.secondaryText,
                                      size: 20,
                                    ),
                                    onPressed: () => playerProvider.toggleLike(track),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon({required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 10, width: 80, color: Colors.white.withOpacity(0.04)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
