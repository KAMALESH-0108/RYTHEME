import 'package:flutter/material.dart';
import '../theme.dart';
import '../components/glass_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Find Your Sound',
      'subtitle': 'A futuristic music universe built around your moods, moments, and energy flows.',
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600',
    },
    {
      'title': 'Feel Your JAMS',
      'subtitle': 'Enter premium social music rooms. Host live listening rooms, vote on queues, and react in real-time.',
      'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600',
    },
    {
      'title': 'Rhythm DNA & AI',
      'subtitle': 'An Android-first conversational AI and dynamic graphs visualising your exact acoustic fingerprint.',
      'image': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600',
    }
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: RythemeTheme.background,
      body: Stack(
        children: [
          // Background Art Slider with Overlay
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Container(
              key: ValueKey<int>(_currentPage),
              height: size.height * 0.65,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_onboardingData[_currentPage]['image']!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RythemeTheme.redOverlayGradient,
                ),
              ),
            ),
          ),

          // Top Branding
          Positioned(
            top: 60,
            left: 24,
            child: Text(
              'RYTHEME',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 4,
                color: RythemeTheme.primaryText,
                shadows: [
                  Shadow(color: RythemeTheme.brightRed.withOpacity(0.5), blurRadius: 8),
                ],
              ),
            ),
          ),

          // Transparent Slide Gesture Detector (placed behind UI cards)
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) => Container(color: Colors.transparent),
            ),
          ),

          // Slide Info Overlay Cards (Elevated Glass)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassContainer(
                  level: GlassLevel.elevated,
                  padding: const EdgeInsets.all(24.0),
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Counter Indicator
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 6,
                            width: _currentPage == index ? 24 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? RythemeTheme.brightRed
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        _onboardingData[_currentPage]['title']!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        _onboardingData[_currentPage]['subtitle']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: RythemeTheme.secondaryText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation Actions
                Row(
                  children: [
                    // Sign In / Login Button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: RythemeTheme.secondaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Next / Get Started Button
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: RythemeTheme.primaryRed.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _onboardingData.length - 1) {
                              Navigator.pushReplacementNamed(context, '/login');
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RythemeTheme.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            _currentPage == _onboardingData.length - 1
                                ? 'Get Started 🎵'
                                : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Guest Explore Quick Link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text(
                      '⚡ Quick Explore as Guest',
                      style: TextStyle(
                        color: RythemeTheme.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
