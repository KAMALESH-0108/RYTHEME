import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/player_provider.dart';

class JamsScreen extends StatefulWidget {
  const JamsScreen({super.key});

  @override
  State<JamsScreen> createState() => _JamsScreenState();
}

class _JamsScreenState extends State<JamsScreen> {
  Map<String, dynamic>? _activeRoom; // If joined, this contains the room data
  final _messageController = TextEditingController();
  final List<Map<String, String>> _roomChat = [
    {'user': 'Sarah K.', 'text': 'This beat is incredible! Bass line is so smooth.'},
    {'user': 'Alex P.', 'text': 'Loving the transitions. Put next track in queue!'},
    {'user': 'Kamlesh (Host)', 'text': 'Welcome to the Late Night Vibes room. Feel free to request songs.'}
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _joinRoom(Map<String, dynamic> room) {
    setState(() {
      _activeRoom = room;
    });
  }

  void _leaveRoom() {
    setState(() {
      _activeRoom = null;
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _roomChat.add({'user': 'Kamlesh (You)', 'text': text});
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _activeRoom != null
            ? _buildJamRoom(playerProvider)
            : _buildJamsDashboard(playerProvider),
      ),
    );
  }

  // --- JAMS LIST DASHBOARD ---
  Widget _buildJamsDashboard(PlayerProvider playerProvider) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RYTHEME JAMS',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                
                // Create Room Button
                GestureDetector(
                  onTap: () => _showCreateJamSheet(context, playerProvider),
                  child: GlassContainer(
                    level: GlassLevel.soft,
                    padding: const EdgeInsets.all(10),
                    borderRadius: BorderRadius.circular(12),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 18, color: RythemeTheme.brightRed),
                        SizedBox(width: 4),
                        Text('Create', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Live Listening Rooms',
              style: TextStyle(fontSize: 14, color: RythemeTheme.secondaryText),
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 140),
              itemCount: playerProvider.activeJams.length,
              itemBuilder: (context, index) {
                final room = playerProvider.activeJams[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GlassContainer(
                    level: GlassLevel.standard,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              room['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            
                            // Pulse Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: RythemeTheme.darkCrimson.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: RythemeTheme.primaryRed.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const _PulsingDot(),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${room['listeners_count']} Listening',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RythemeTheme.brightRed),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(room['host_avatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Host: ${room['host_name']}',
                              style: const TextStyle(fontSize: 11, color: RythemeTheme.secondaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Current Song detail
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('CURRENTLY PLAYING', style: TextStyle(fontSize: 9, color: RythemeTheme.disabledText, letterSpacing: 0.5)),
                                  Text(
                                    '${room['current_song']} — ${room['current_artist']}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Join Action
                            ElevatedButton(
                              onPressed: () => _joinRoom(room),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RythemeTheme.primaryRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // --- IMMERSIVE LIVE ROOM ---
  Widget _buildJamRoom(PlayerProvider playerProvider) {
    final room = _activeRoom!;
    return Stack(
      children: [
        // Background blurred art
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.85),
            ),
          ),
        ),

        // Live JAMS UI Layout
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _leaveRoom,
                    ),
                    Column(
                      children: [
                        Text(room['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('🔴 LIVE ROOM', style: TextStyle(fontSize: 10, color: RythemeTheme.brightRed, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.exit_to_app, color: RythemeTheme.brightRed),
                      onPressed: _leaveRoom,
                    ),
                  ],
                ),
              ),

              // Avatars cloud (floating listeners)
              const SizedBox(height: 12),
              Container(
                height: 70,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Simulated avatars clustered together
                    Positioned(
                      left: 60,
                      child: _buildFloatingAvatar('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80', 'Sarah'),
                    ),
                    Positioned(
                      left: 110,
                      child: _buildFloatingAvatar('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80', 'Alex'),
                    ),
                    Positioned(
                      right: 110,
                      child: _buildFloatingAvatar('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80', 'Vector'),
                    ),
                    Positioned(
                      right: 60,
                      child: _buildFloatingAvatar('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80', 'Jess'),
                    ),
                    // Host Center
                    Center(
                      child: _buildFloatingAvatar(room['host_avatar'], 'Host', isHost: true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Main player panel card (Glass Level 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassContainer(
                  level: GlassLevel.elevated,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=150',
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room['current_song'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                            ),
                            Text(
                              room['current_artist'],
                              style: const TextStyle(color: RythemeTheme.secondaryText, fontSize: 12),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      
                      // Upvote button
                      IconButton(
                        icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Chat Log Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text('Room Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText)),
              ),
              const SizedBox(height: 8),

              // Scrollable chat view
              Expanded(
                child: GlassContainer(
                  level: GlassLevel.soft,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: _roomChat.length,
                    itemBuilder: (context, index) {
                      final chat = _roomChat[index];
                      final isMe = chat['user']!.contains('Kamlesh');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat['user']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe ? RythemeTheme.brightRed : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chat['text']!,
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Chat Input Bar (Soft Glass overlay)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: GlassContainer(
                  level: GlassLevel.soft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Type something to JAMS...',
                            hintStyle: TextStyle(color: RythemeTheme.disabledText, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (v) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: RythemeTheme.brightRed, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingAvatar(String url, String name, {bool isHost = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isHost)
              Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  color: RythemeTheme.brightRed,
                  shape: BoxShape.circle,
                ),
              ),
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(url),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            fontSize: 9,
            color: isHost ? RythemeTheme.brightRed : RythemeTheme.secondaryText,
            fontWeight: isHost ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Bottom sheet to configure new JAMS room
  void _showCreateJamSheet(BuildContext context, PlayerProvider playerProvider) {
    final nameCont = TextEditingController(text: 'Kamlesh\'s Chill Session');
    bool isPublic = true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => GlassContainer(
          level: GlassLevel.elevated,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create JAMS Room', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              
              // Name Input
              GlassContainer(
                level: GlassLevel.soft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: nameCont,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter room name',
                  ),
                ),
              ),
              
              const SizedBox(height: 18),
              
              // Visibility Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Public Jam Room', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('Allows anyone nearby or searchers to join.', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                  Switch(
                    value: isPublic,
                    onChanged: (v) => setSheetState(() => isPublic = v),
                    activeColor: RythemeTheme.brightRed,
                  )
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        playerProvider.createNewJam(nameCont.text, isPublic);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RythemeTheme.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Create Jam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(_anim),
      child: Container(
        height: 6,
        width: 6,
        decoration: const BoxDecoration(
          color: RythemeTheme.brightRed,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
