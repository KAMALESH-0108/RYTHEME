import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/player_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final isOffline = playerProvider.isOfflineMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Library', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  // Offline Toggle Switch directly in header
                  Row(
                    children: [
                      Icon(
                        isOffline ? Icons.cloud_off : Icons.cloud_done,
                        size: 18,
                        color: isOffline ? RythemeTheme.brightRed : RythemeTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOffline ? 'Offline' : 'Online',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          color: isOffline ? RythemeTheme.brightRed : RythemeTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: isOffline,
                        onChanged: (val) => playerProvider.toggleOfflineMode(val),
                        activeColor: RythemeTheme.brightRed,
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Offline Subtle Banner
            if (isOffline)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                child: GlassContainer(
                  level: GlassLevel.elevated,
                  hasRedGlow: true,
                  glowColor: RythemeTheme.brightRed,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: BorderRadius.circular(12),
                  child: const Row(
                    children: [
                      Icon(Icons.offline_pin, color: RythemeTheme.brightRed, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "You're offline — your downloads are ready.",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: TabBar(
                controller: _tabController,
                indicatorColor: RythemeTheme.brightRed,
                labelColor: Colors.white,
                unselectedLabelColor: RythemeTheme.secondaryText,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Downloads'),
                  Tab(text: 'Liked Songs'),
                  Tab(text: 'Storage'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Downloads
                  _buildDownloadsTab(playerProvider),
                  // Tab 2: Liked Songs
                  _buildLikedTab(playerProvider),
                  // Tab 3: Storage
                  _buildStorageTab(playerProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DOWNLOADS VIEW ---
  Widget _buildDownloadsTab(PlayerProvider playerProvider) {
    final downloads = playerProvider.downloadedSongs;
    final progressMap = playerProvider.downloadProgress;

    if (downloads.isEmpty && progressMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_for_offline, size: 48, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 12),
            const Text('No downloaded tracks yet.', style: TextStyle(color: RythemeTheme.secondaryText)),
            const SizedBox(height: 4),
            Text('Go to Discover to save tracks offline.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 140),
      children: [
        // Action controllers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${downloads.length} tracks offline',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RythemeTheme.secondaryText),
            ),
            if (downloads.isNotEmpty)
              TextButton(
                onPressed: () => playerProvider.clearAllDownloads(),
                child: const Text('Clear All', style: TextStyle(color: RythemeTheme.brightRed, fontSize: 12)),
              )
          ],
        ),
        
        // Active downloading list
        if (progressMap.isNotEmpty) ...[
          const Text('Downloading...', style: TextStyle(fontSize: 11, color: RythemeTheme.disabledText, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...progressMap.entries.map((entry) {
            final trackId = entry.key;
            final progress = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GlassContainer(
                level: GlassLevel.soft,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.downloading, color: RythemeTheme.brightRed, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Track ID: $trackId', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation(RythemeTheme.brightRed),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],

        // Completed downloads list
        ...downloads.map((track) {
          final isPlayingThis = playerProvider.currentTrack?['id'] == track['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () => playerProvider.playTrack(track, newQueue: downloads),
              child: GlassContainer(
                level: GlassLevel.soft,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        track['image_url'],
                        height: 44,
                        width: 44,
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
                          ),
                          Text(
                            track['artist'],
                            style: const TextStyle(color: RythemeTheme.secondaryText, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.offline_pin, color: RythemeTheme.success, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // --- LIKED SONGS VIEW ---
  Widget _buildLikedTab(PlayerProvider playerProvider) {
    final liked = playerProvider.likedSongs;

    if (liked.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 48, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 12),
            const Text('Your favorites will appear here.', style: TextStyle(color: RythemeTheme.secondaryText)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 140),
      itemCount: liked.length,
      itemBuilder: (context, index) {
        final track = liked[index];
        final isPlayingThis = playerProvider.currentTrack?['id'] == track['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => playerProvider.playTrack(track, newQueue: liked),
            child: GlassContainer(
              level: GlassLevel.soft,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      track['image_url'] ?? 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=100',
                      height: 44,
                      width: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track['title'] ?? 'Title',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isPlayingThis ? RythemeTheme.brightRed : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          track['artist'] ?? 'Artist',
                          style: const TextStyle(color: RythemeTheme.secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: RythemeTheme.brightRed, size: 20),
                    onPressed: () => playerProvider.toggleLike(track),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- STORAGE VIEW ---
  Widget _buildStorageTab(PlayerProvider playerProvider) {
    final usedGb = playerProvider.storageUsedGb;
    final totalGb = usedGb + playerProvider.storageAvailableGb;
    final percent = usedGb / totalGb;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Usage details card
        GlassContainer(
          level: GlassLevel.standard,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Device Storage Space', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 18),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${usedGb.toStringAsFixed(2)} GB Used', style: const TextStyle(fontSize: 12, color: RythemeTheme.brightRed)),
                  Text('${playerProvider.storageAvailableGb.toStringAsFixed(2)} GB Free', style: const TextStyle(fontSize: 12, color: RythemeTheme.secondaryText)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation(RythemeTheme.brightRed),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // Settings toggles
        const Text('Download Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText)),
        const SizedBox(height: 12),

        _buildPreferenceTile(
          title: 'Wi-Fi Only Downloads',
          desc: 'Save cellular data. Only cache files when connected to Wi-Fi.',
          value: playerProvider.wifiOnly,
          onChanged: (val) => playerProvider.setWifiOnly(val),
          icon: Icons.wifi,
        ),
        
        _buildPreferenceTile(
          title: 'Smart Downloads',
          desc: 'Automatically download recommended songs based on your Rhythm DNA.',
          value: true,
          onChanged: (val) {},
          icon: Icons.offline_bolt,
        ),
      ],
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        level: GlassLevel.soft,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 10, color: RythemeTheme.disabledText, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: RythemeTheme.brightRed,
            )
          ],
        ),
      ),
    );
  }
}
