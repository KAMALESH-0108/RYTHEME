import 'package:flutter/material.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import 'notification_settings_sheet.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Standard mock notification list
    final List<Map<String, dynamic>> notifications = [
      {
        'category': 'Music',
        'title': 'New Release Drop',
        'desc': 'Your favorite artist CyberRider just dropped a new synthwave track: "Midnight Neon".',
        'time': '10 mins ago',
        'unread': true,
        'icon': Icons.music_note_outlined,
      },
      {
        'category': 'Social',
        'title': 'JAM Invite',
        'desc': 'Sarah K. invited you to join "Late Night Vibes 🔴". 12 listeners are active.',
        'time': '1 hour ago',
        'unread': true,
        'icon': Icons.group_outlined,
      },
      {
        'category': 'Premium',
        'title': 'Smart Downloads Active',
        'desc': 'Smart downloads generated your weekly acoustic cache. 14 songs saved successfully.',
        'time': '5 hours ago',
        'unread': false,
        'icon': Icons.download_done_rounded,
      },
      {
        'category': 'Personal',
        'title': 'Listening Memory',
        'desc': 'Relive your late-night coding era from August. Check your new Time Capsule card.',
        'time': '1 day ago',
        'unread': false,
        'icon': Icons.auto_awesome_outlined,
      }
    ];

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
            // Slide indicator pill
            Container(
              height: 5,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                
                // Settings button (trigger settings sheet)
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: RythemeTheme.secondaryText),
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => const NotificationSettingsSheet(),
                    );
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // Notifications List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassContainer(
                      level: GlassLevel.soft,
                      borderWidth: notif['unread'] ? 1.2 : 1.0,
                      hasRedGlow: notif['unread'],
                      glowColor: RythemeTheme.primaryRed.withOpacity(0.5),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notif['icon'],
                              color: notif['unread'] ? RythemeTheme.brightRed : RythemeTheme.secondaryText,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          
                          // Text Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      notif['title'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: notif['unread'] ? Colors.white : RythemeTheme.secondaryText,
                                      ),
                                    ),
                                    Text(
                                      notif['time'],
                                      style: const TextStyle(fontSize: 10, color: RythemeTheme.disabledText),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif['desc'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: notif['unread'] ? RythemeTheme.secondaryText : RythemeTheme.disabledText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Unread Red Dot Indicator
                          if (notif['unread']) ...[
                            const SizedBox(width: 8),
                            Container(
                              height: 6,
                              width: 6,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: const BoxDecoration(
                                color: RythemeTheme.brightRed,
                                shape: BoxShape.circle,
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
