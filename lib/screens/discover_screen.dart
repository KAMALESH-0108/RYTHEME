import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/player_provider.dart';
import '../services/jiosaavn_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  final List<String> _trendingSearches = [
    'Synthwave',
    'Lofi Beats',
    'Coding Flow',
    'Rain ambient',
    'JioSaavn Hits'
  ];

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Trending', 'color': RythemeTheme.crimson},
    {'title': 'New Releases', 'color': RythemeTheme.darkCrimson},
    {'title': 'Hidden Gems', 'color': Colors.deepPurple},
    {'title': 'Acoustic DNA', 'color': Colors.blueGrey},
    {'title': 'Moods & Vibes', 'color': RythemeTheme.primaryRed},
    {'title': 'Global Charts', 'color': Colors.indigo},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _executeSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    final results = await JioSaavnService.searchSongs(query);
    
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            const Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0),
              child: Text(
                'Discover',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 12),

            // Floating Search Input Capsule (Glass Level 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassContainer(
                level: GlassLevel.standard,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    if (val.trim().isEmpty) {
                      setState(() => _isSearching = false);
                    }
                  },
                  onSubmitted: _executeSearch,
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, moods...',
                    hintStyle: const TextStyle(color: RythemeTheme.disabledText),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _isSearching = false;
                                _searchResults.clear();
                              });
                            },
                          )
                        : const Icon(Icons.mic, color: Colors.white70),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search Content / Categories
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSearching 
                    ? _buildSearchResults(playerProvider)
                    : _buildDefaultDiscoverView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(PlayerProvider playerProvider) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: RythemeTheme.brightRed),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            const Text('No tracks found.', style: TextStyle(color: RythemeTheme.secondaryText)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 140),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        final isPlayingThis = playerProvider.currentTrack?['id'] == track['id'];
        final isDownloaded = playerProvider.downloadedSongs.any((s) => s['id'] == track['id']);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => playerProvider.playTrack(track, newQueue: _searchResults),
            child: GlassContainer(
              level: GlassLevel.soft,
              padding: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(width: 14),
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
                  // Play indicator
                  if (isPlayingThis && playerProvider.isPlaying)
                    const Icon(Icons.volume_up, color: RythemeTheme.brightRed, size: 20)
                  else
                    const Icon(Icons.play_arrow, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  
                  // Download button
                  IconButton(
                    icon: Icon(
                      isDownloaded
                          ? Icons.check_circle
                          : Icons.download_for_offline_outlined,
                      color: isDownloaded ? RythemeTheme.success : Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => playerProvider.downloadTrack(track),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultDiscoverView() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        // Trending Searches
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Trending Searches',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RythemeTheme.secondaryText),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _trendingSearches.length,
            itemBuilder: (context, index) {
              final term = _trendingSearches[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    _searchController.text = term;
                    _executeSearch(term);
                  },
                  child: GlassContainer(
                    level: GlassLevel.soft,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      term,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Grid of categories
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Explore Vibe Categories',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return GestureDetector(
              onTap: () {
                _searchController.text = cat['title'];
                _executeSearch(cat['title']);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      cat['color'].withOpacity(0.55),
                      cat['color'].withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: GlassContainer(
                  level: GlassLevel.soft,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    cat['title'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
