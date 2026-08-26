import 'package:flutter/material.dart';
import '../theme.dart';
import '../components/glass_container.dart';

class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  String _notificationMood = 'Balanced';
  bool _newReleases = true;
  bool _jams = true;
  bool _recommendations = false;
  bool _quietHours = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Notification Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Mood Selector Section
                  const Text(
                    'Notification Mood',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Minimal', 'Balanced', 'Everything'].map((mood) {
                      final isSelected = _notificationMood == mood;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _notificationMood = mood),
                            child: GlassContainer(
                              level: isSelected ? GlassLevel.elevated : GlassLevel.soft,
                              borderWidth: isSelected ? 1.5 : 1.0,
                              hasRedGlow: isSelected,
                              glowColor: RythemeTheme.primaryRed,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  mood,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : RythemeTheme.secondaryText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Category Toggles
                  const Text(
                    'Subscribed Channels',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildToggleCard(
                    title: 'New Releases',
                    desc: 'Notify me when artists I follow drop new tracks.',
                    value: _newReleases,
                    onChanged: (val) => setState(() => _newReleases = val),
                  ),
                  
                  _buildToggleCard(
                    title: 'JAMS & Social listening',
                    desc: 'Receive alerts when friends host live rooms or invite me.',
                    value: _jams,
                    onChanged: (val) => setState(() => _jams = val),
                  ),
                  
                  _buildToggleCard(
                    title: 'Acoustic Recommendations',
                    desc: 'Daily prompts matched to your active Rhythm DNA.',
                    value: _recommendations,
                    onChanged: (val) => setState(() => _recommendations = val),
                  ),

                  const SizedBox(height: 16),
                  
                  // Quiet Hours
                  _buildToggleCard(
                    title: 'Quiet Hours',
                    desc: 'Mute push notifications from 22:00 to 07:00.',
                    value: _quietHours,
                    onChanged: (val) => setState(() => _quietHours = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        level: GlassLevel.soft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: RythemeTheme.disabledText, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: RythemeTheme.brightRed,
              activeTrackColor: RythemeTheme.darkCrimson,
              inactiveThumbColor: RythemeTheme.disabledText,
              inactiveTrackColor: Colors.white.withOpacity(0.04),
            ),
          ],
        ),
      ),
    );
  }
}
