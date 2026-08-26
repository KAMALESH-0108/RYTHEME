import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../components/glass_container.dart';
import '../components/mini_player.dart';
import '../services/player_provider.dart';
import '../services/customization_provider.dart';

import 'home_screen.dart';
import 'discover_screen.dart';
import 'jams_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'full_player_screen.dart';
import 'rhythm_ai_screen.dart';
import 'customization_sheet.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const JamsScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final customProvider = Provider.of<CustomizationProvider>(context);
    final accentColor = customProvider.accentColor;

    return Scaffold(
      backgroundColor: RythemeTheme.background,
      body: Stack(
        children: [
          // Ambient back lighting (subtle red canvas glow)
          Positioned(
            top: -100,
            left: -100,
            height: 300,
            width: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -100,
            height: 400,
            width: 400,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.10),
                    blurRadius: 150,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Primary Tab Views
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),

          // Floating Rhythm AI Capsule (Above mini player on the right)
          if (_currentIndex == 0 || _currentIndex == 1)
            Positioned(
              right: 20,
              bottom: playerProvider.currentTrack != null ? 172 : 100,
              child: _buildRhythmAiLauncher(context, accentColor),
            ),

          // Customization Launcher float button (Top Right float when on profile)
          if (_currentIndex == 4)
            Positioned(
              right: 24,
              top: 55,
              child: _buildCustomizationLauncher(context, accentColor),
            ),

          // Floating Mini Player
          if (playerProvider.currentTrack != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 96,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < -8) {
                    _openFullPlayer(context);
                  }
                },
                onTap: () => _openFullPlayer(context),
                child: Hero(
                  tag: 'mini_player_hero',
                  child: const MiniPlayer(),
                ),
              ),
            ),

          // Floating Navigation Capsule (Standard Glass, Level 2)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _buildNavigationCapsule(accentColor),
          ),
        ],
      ),
    );
  }

  // --- FLOATING NAV CAPSULE ---
  Widget _buildNavigationCapsule(Color accentColor) {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_filled, 'label': 'Home'},
      {'icon': Icons.explore_outlined, 'label': 'Discover'},
      {'icon': Icons.radio_outlined, 'label': 'JAMS'},
      {'icon': Icons.library_music_outlined, 'label': 'Library'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return GlassContainer(
      level: GlassLevel.standard,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      borderRadius: BorderRadius.circular(28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final isSelected = _currentIndex == index;
          final item = navItems[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: isSelected
                  ? BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'],
                    color: isSelected ? accentColor : RythemeTheme.secondaryText,
                    size: 24,
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    width: isSelected ? 12 : 0,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: accentColor.withOpacity(0.7),
                            blurRadius: 6,
                          )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- FLOATING AI LAUNCHER ---
  Widget _buildRhythmAiLauncher(BuildContext context, Color accentColor) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const RhythmAiScreen(),
        );
      },
      child: GlassContainer(
        level: GlassLevel.elevated,
        hasRedGlow: true,
        glowColor: accentColor,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'RHYTHM AI',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white, shadows: [
                Shadow(color: accentColor.withOpacity(0.5), blurRadius: 8),
              ]),
            )
          ],
        ),
      ),
    );
  }

  // --- CUSTOMIZATION LAUNCHER ---
  Widget _buildCustomizationLauncher(BuildContext context, Color accentColor) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const CustomizationSheet(),
        );
      },
      child: GlassContainer(
        level: GlassLevel.elevated,
        hasRedGlow: true,
        glowColor: accentColor,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.palette_outlined, color: accentColor, size: 14),
            const SizedBox(width: 6),
            const Text('Vibe Customizer', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => const FullPlayerScreen(),
    );
  }
}
