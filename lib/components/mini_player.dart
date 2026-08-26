import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/player_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final track = playerProvider.currentTrack;

    if (track == null) return const SizedBox.shrink();

    final progress = playerProvider.duration.inSeconds > 0
        ? playerProvider.position.inSeconds / playerProvider.duration.inSeconds
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: GlassContainer(
        level: GlassLevel.standard,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    track['image_url'] ?? 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=100',
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Title/Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        track['title'] ?? 'Unknown Track',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track['artist'] ?? 'Unknown Artist',
                        style: const TextStyle(color: RythemeTheme.secondaryText, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Play / Pause Action
                IconButton(
                  icon: Icon(
                    playerProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: RythemeTheme.brightRed,
                    size: 32,
                  ),
                  onPressed: () => playerProvider.togglePlay(),
                ),
                
                // Next Action
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => playerProvider.nextTrack(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Progress Bar (Thin red active progress indicator)
            ClipRRect(
              borderRadius: BorderRadius.circular(1.5),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: const AlwaysStoppedAnimation(RythemeTheme.brightRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
