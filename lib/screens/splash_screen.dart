import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../components/visualizer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Route transitions after 1.5 seconds
    Timer(const Duration(milliseconds: 1500), _checkSessionAndNavigate);
  }

  void _checkSessionAndNavigate() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RythemeTheme.background,
      body: Stack(
        children: [
          // Ambient Dark Crimson glow at the bottom center
          Positioned(
            bottom: -150,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: RythemeTheme.darkCrimson.withOpacity(0.35),
                    blurRadius: 150,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Main Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Stylized logo symbol
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: RythemeTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: RythemeTheme.glassBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: RythemeTheme.primaryRed.withOpacity(0.18),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      'RYTHEME',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                        letterSpacing: 8,
                        color: RythemeTheme.primaryText,
                        shadows: [
                          Shadow(
                            color: RythemeTheme.brightRed.withOpacity(0.8),
                            blurRadius: 12,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Pulsing red waveform underneath the logo
                SizedBox(
                  width: 140,
                  height: 35,
                  child: const AudioVisualizer(
                    isPlaying: true,
                    type: VisualizerType.waveform,
                    height: 35,
                  ),
                ),
                
                const Spacer(),
                
                // Tagline at the bottom
                Text(
                  'FIND YOUR SOUND. FEEL YOUR MOMENT.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: RythemeTheme.secondaryText.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
