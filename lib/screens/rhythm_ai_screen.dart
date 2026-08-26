import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/player_provider.dart';

class RhythmAiScreen extends StatefulWidget {
  const RhythmAiScreen({super.key});

  @override
  State<RhythmAiScreen> createState() => _RhythmAiScreenState();
}

class _RhythmAiScreenState extends State<RhythmAiScreen> {
  final _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    'Play chill songs for coding.',
    'Make a rainy evening playlist.',
    'Find songs like this.',
    'Vibe: Cyberpunk Night Drive',
  ];

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitQuery(PlayerProvider provider, String query) {
    if (query.trim().isEmpty) return;
    provider.askRhythmAI(query);
    _chatController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: GlassContainer(
        level: GlassLevel.elevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
        child: Column(
          children: [
            // Slide indicator
            Container(
              height: 5,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: RythemeTheme.brightRed, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RHYTHM AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text('Your Android Conversational Music Assistant', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Messages chat viewport
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: playerProvider.aiMessages.length,
                itemBuilder: (context, index) {
                  final msg = playerProvider.aiMessages[index];
                  final isUser = msg['role'] == 'user';
                  final List<dynamic>? recs = msg['recommendations'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.85,
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            GlassContainer(
                              level: isUser ? GlassLevel.standard : GlassLevel.soft,
                              hasRedGlow: !isUser,
                              glowColor: RythemeTheme.primaryRed.withOpacity(0.5),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isUser ? const Radius.circular(16) : Radius.circular(0),
                                bottomRight: isUser ? Radius.circular(0) : const Radius.circular(16),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                msg['text'],
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isUser ? Colors.white : Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ),
                            
                            // Recommended song cards returned by AI
                            if (recs != null && recs.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...recs.map((song) {
                                final track = Map<String, dynamic>.from(song);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: GlassContainer(
                                    level: GlassLevel.soft,
                                    padding: const EdgeInsets.all(10),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            track['image_url'],
                                            height: 36,
                                            width: 36,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                track['title'],
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                track['artist'],
                                                style: const TextStyle(color: RythemeTheme.secondaryText, fontSize: 9),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.play_circle_fill, color: RythemeTheme.brightRed, size: 28),
                                          onPressed: () {
                                            playerProvider.playTrack(track);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Playing AI choice: ${track['title']}'),
                                                backgroundColor: RythemeTheme.crimson,
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Prompt suggestions Row
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final sug = _suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _submitQuery(playerProvider, sug),
                      child: GlassContainer(
                        level: GlassLevel.soft,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        borderRadius: BorderRadius.circular(10),
                        child: Text(
                          sug,
                          style: const TextStyle(fontSize: 11, color: RythemeTheme.secondaryText),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),

            // Chat Input Bar (Elevated Glass)
            GlassContainer(
              level: GlassLevel.standard,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              borderRadius: BorderRadius.circular(18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Request a customized lofi beat, study vibe...',
                        hintStyle: TextStyle(color: RythemeTheme.disabledText, fontSize: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (v) => _submitQuery(playerProvider, v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: RythemeTheme.brightRed, size: 20),
                    onPressed: () => _submitQuery(playerProvider, _chatController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
