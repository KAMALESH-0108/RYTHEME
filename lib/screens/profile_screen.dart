import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/player_provider.dart';
import '../services/customization_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _journalNoteController = TextEditingController();
  String _selectedMood = 'Focus 💻';

  final List<String> _journalMoods = [
    'Focus 💻',
    'Chill 🌧️',
    'Energy ⚡',
    'Experimental 🧪'
  ];

  @override
  void dispose() {
    _journalNoteController.dispose();
    super.dispose();
  }

  void _submitJournal(PlayerProvider playerProvider) {
    final note = _journalNoteController.text.trim();
    if (note.isEmpty) return;

    final song = playerProvider.currentTrack?['title'] ?? 'Starlight Echoes';
    final artist = playerProvider.currentTrack?['artist'] ?? 'Ethereal Wave';

    playerProvider.addJournalEntry(note, song, artist, _selectedMood);
    _journalNoteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to your Sound Journal.'),
        backgroundColor: RythemeTheme.success,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final customProvider = Provider.of<CustomizationProvider>(context);
    final themeAccent = customProvider.accentColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(customProvider),
              
              const SizedBox(height: 24),
              
              // Rhythm DNA Visualization
              _buildRhythmDnaSection(themeAccent),
              
              const SizedBox(height: 28),

              // Time Capsules Memory Cards
              _buildTimeCapsulesSection(),

              const SizedBox(height: 28),

              // Sound Journal
              _buildSoundJournalSection(playerProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(CustomizationProvider customProvider) {
    final accent = customProvider.accentColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GlassContainer(
        level: GlassLevel.standard,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
            ),
            const SizedBox(width: 20),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Kamlesh',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      // Custom Theme Accent Tag (unlocked styling)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: accent.withOpacity(0.5)),
                        ),
                        child: Text(
                          customProvider.currentAccentName.toUpperCase(),
                          style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: accent),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Building code and tuning frequencies.',
                    style: TextStyle(fontSize: 12, color: RythemeTheme.secondaryText),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildHeaderStat('148 hrs', 'Listen time'),
                      const SizedBox(width: 16),
                      _buildHeaderStat('45', 'Loved songs'),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 9, color: RythemeTheme.disabledText)),
      ],
    );
  }

  // --- RHYTHM DNA RADIAL CHART ---
  Widget _buildRhythmDnaSection(Color themeAccent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR RHYTHM DNA',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          
          GlassContainer(
            level: GlassLevel.standard,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  child: CustomPaint(
                    painter: _RhythmDnaPainter(themeAccent),
                  ),
                ),
                const SizedBox(width: 24),
                
                Expanded(
                  child: Column(
                    children: [
                      _buildDnaLegend('42% Chill', themeAccent),
                      _buildDnaLegend('31% Melodic', themeAccent.withOpacity(0.75)),
                      _buildDnaLegend('17% Energetic', themeAccent.withOpacity(0.50)),
                      _buildDnaLegend('10% Experimental', themeAccent.withOpacity(0.25)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDnaLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- TIME CAPSULES ---
  Widget _buildTimeCapsulesSection() {
    final capsules = [
      {'title': 'August 2026', 'desc': 'Your Late Night Era', 'art': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300'},
      {'title': 'Autumn Coding', 'desc': 'Focus loops', 'art': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300'},
      {'title': 'Underground Gems', 'desc': '10% Experimental era', 'art': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=300'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'TIME CAPSULES',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: capsules.length,
            itemBuilder: (context, index) {
              final cap = capsules[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(cap['art']!, fit: BoxFit.cover),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: RythemeTheme.redOverlayGradient,
                          ),
                        ),
                        GlassContainer(
                          level: GlassLevel.soft,
                          borderRadius: BorderRadius.circular(20),
                          padding: const EdgeInsets.all(14),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(cap['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(cap['desc']!, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- SOUND JOURNAL ---
  Widget _buildSoundJournalSection(PlayerProvider playerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOUND JOURNAL',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          
          GlassContainer(
            level: GlassLevel.standard,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                
                GlassContainer(
                  level: GlassLevel.soft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _journalNoteController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Attach a thought to this track...',
                      hintStyle: TextStyle(color: RythemeTheme.disabledText),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: _selectedMood,
                      dropdownColor: RythemeTheme.secondaryBlack,
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMood = val);
                      },
                      items: _journalMoods.map((String mood) {
                        return DropdownMenuItem<String>(
                          value: mood,
                          child: Text(mood),
                        );
                      }).toList(),
                    ),
                    
                    ElevatedButton(
                      onPressed: () => _submitJournal(playerProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RythemeTheme.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Note', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          ...playerProvider.journalEntries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassContainer(
                level: GlassLevel.soft,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(entry['mood'] ?? 'Music', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Text('Just now', style: TextStyle(fontSize: 10, color: RythemeTheme.disabledText)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      entry['note'] ?? '',
                      style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.music_note_outlined, size: 12, color: RythemeTheme.brightRed),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${entry['song_title']} — ${entry['artist']}',
                            style: const TextStyle(fontSize: 10, color: RythemeTheme.secondaryText, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Custom Painter for Rhythm DNA radial bands
class _RhythmDnaPainter extends CustomPainter {
  final Color baseColor;

  _RhythmDnaPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Chill circle (42%)
    paint.color = baseColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 40),
      -math.pi / 2,
      2 * math.pi * 0.42,
      false,
      paint,
    );

    // Melodic circle (31%)
    paint.color = baseColor.withOpacity(0.75);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 30),
      -math.pi / 2,
      2 * math.pi * 0.31,
      false,
      paint,
    );

    // Energetic circle (17%)
    paint.color = baseColor.withOpacity(0.50);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 20),
      -math.pi / 2,
      2 * math.pi * 0.17,
      false,
      paint,
    );

    // Experimental circle (10%)
    paint.color = baseColor.withOpacity(0.25);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 10),
      -math.pi / 2,
      2 * math.pi * 0.10,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RhythmDnaPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor;
  }
}
