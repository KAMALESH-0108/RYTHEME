import 'package:flutter/material.dart';
import '../theme.dart';
import '../components/glass_container.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> premiumFeatures = [
      'Ad-free uninterrupted streaming',
      'Unlimited skips & catalog access',
      'Lossless Hi-Fi 24-bit audio resolution',
      'Offline Smart Downloads cache',
      'Live synced lyrics scroll translation',
      'Unlimited RHYTHM AI prompt suggestions',
      'Host real-time Premium social JAMS',
      'Detailed Rhythm DNA charts & statistics'
    ];

    return Scaffold(
      backgroundColor: RythemeTheme.background,
      body: Stack(
        children: [
          // Background Gradient (Deep Crimson luxury gradient)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RythemeTheme.premiumGradient,
              ),
            ),
          ),
          
          // Subtle radial glows
          Positioned(
            top: -100,
            left: -100,
            height: 350,
            width: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: RythemeTheme.brightRed.withOpacity(0.12),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Back + title)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'RYTHEME PREMIUM',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Colors.white70),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40), // spacer balance
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // Cinematic Icon branding
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            shape: BoxShape.circle,
                            border: Border.all(color: RythemeTheme.glassBorder),
                            boxShadow: [
                              BoxShadow(
                                color: RythemeTheme.brightRed.withOpacity(0.2),
                                blurRadius: 28,
                              )
                            ]
                          ),
                          child: const Icon(Icons.star, color: RythemeTheme.brightRed, size: 36),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Text description
                        const Text(
                          'Unlock Your Complete Rhythm',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Step beyond limits. Step into premium acoustics.',
                          style: TextStyle(fontSize: 14, color: RythemeTheme.secondaryText),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Central Premium Card (Level 3 Glass)
                        GlassContainer(
                          level: GlassLevel.elevated,
                          hasRedGlow: true,
                          glowColor: RythemeTheme.brightRed,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PREMIUM MEMBERSHIP',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0, color: RythemeTheme.brightRed),
                              ),
                              const SizedBox(height: 6),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('\$9.99', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                                  SizedBox(width: 6),
                                  Text('/ month', style: TextStyle(fontSize: 12, color: RythemeTheme.secondaryText)),
                                ],
                              ),
                              const Divider(height: 24, color: Colors.white10),
                              
                              // Features list
                              ...premiumFeatures.map((feat) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: RythemeTheme.brightRed, size: 16),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          feat,
                                          style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // CTA Buttons
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: RythemeTheme.brightRed.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )
                            ]
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Premium active! Welcome to the elite tier.'),
                                  backgroundColor: RythemeTheme.success,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RythemeTheme.brightRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Upgrade to Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View other plans (Family, Student)',
                            style: TextStyle(color: RythemeTheme.secondaryText, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
