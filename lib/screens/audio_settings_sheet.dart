import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/player_provider.dart';

class AudioSettingsSheet extends StatefulWidget {
  const AudioSettingsSheet({super.key});

  @override
  State<AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<AudioSettingsSheet> {
  String _audioQuality = 'Hi-Fi 24-bit';
  double _crossfade = 6.0;
  bool _gapless = true;
  bool _normalization = false;

  final List<String> _qualityTiers = ['Standard (96k)', 'High (160k)', 'Ultra (320k)', 'Hi-Fi 24-bit'];
  final List<String> _eqLabels = ['60Hz', '230Hz', '910Hz', '4KHz', '14KHz'];

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
            
            // Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Audio Settings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable Panel content
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 1. Audio Quality Select
                  const Text('Streaming Audio Quality', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _audioQuality,
                    dropdownColor: RythemeTheme.secondaryBlack,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _audioQuality = val);
                    },
                    items: _qualityTiers.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 2. 5-Band Equalizer
                  const Text('5-Band Equalizer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText)),
                  const SizedBox(height: 12),
                  GlassContainer(
                    level: GlassLevel.soft,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(5, (index) {
                            final bandVal = playerProvider.equalizerBands[index];
                            return Column(
                              children: [
                                SizedBox(
                                  height: 110,
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 2,
                                        activeTrackColor: RythemeTheme.brightRed,
                                        inactiveTrackColor: Colors.white.withOpacity(0.06),
                                        thumbColor: RythemeTheme.brightRed,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      ),
                                      child: Slider(
                                        value: bandVal,
                                        min: -10.0,
                                        max: 10.0,
                                        onChanged: (val) => playerProvider.setEqualizerBand(index, val),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _eqLabels[index],
                                  style: const TextStyle(fontSize: 9, color: RythemeTheme.disabledText, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        // Reset action
                        TextButton(
                          onPressed: () {
                            for (int i = 0; i < 5; i++) {
                              playerProvider.setEqualizerBand(i, 0.0);
                            }
                          },
                          child: const Text('Reset Equalizer', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Crossfade settings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Crossfade Tracks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText)),
                      Text('${_crossfade.toInt()}s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RythemeTheme.brightRed)),
                    ],
                  ),
                  Slider(
                    value: _crossfade,
                    min: 0.0,
                    max: 12.0,
                    divisions: 12,
                    activeColor: RythemeTheme.brightRed,
                    inactiveColor: Colors.white.withOpacity(0.06),
                    onChanged: (val) => setState(() => _crossfade = val),
                  ),

                  const SizedBox(height: 12),

                  // 4. Custom Switch Tiles
                  _buildSwitchTile('Gapless Playback', 'Removes silent space between consecutive tracks.', _gapless, (val) => setState(() => _gapless = val)),
                  _buildSwitchTile('Volume Normalization', 'Stabilize decibel frequencies to equal values.', _normalization, (val) => setState(() => _normalization = val)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String desc, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 10, color: RythemeTheme.disabledText)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RythemeTheme.brightRed,
          ),
        ],
      ),
    );
  }
}
