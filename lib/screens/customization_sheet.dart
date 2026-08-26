import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../components/glass_container.dart';
import '../services/customization_provider.dart';

class CustomizationSheet extends StatelessWidget {
  const CustomizationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final customProvider = Provider.of<CustomizationProvider>(context);
    final accentColor = customProvider.accentColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Customization Center',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                TextButton(
                  onPressed: () => customProvider.resetCustomizations(),
                  child: Text('Reset', style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Options List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 1. Accent Color selection
                  const Text('Accent Theme Energy Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: CustomizationProvider.accentColors.keys.map((name) {
                        final isSelected = customProvider.currentAccentName == name;
                        final colorVal = CustomizationProvider.accentColors[name]!;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () => customProvider.setAccentColor(name),
                            child: GlassContainer(
                              level: isSelected ? GlassLevel.elevated : GlassLevel.soft,
                              hasRedGlow: isSelected,
                              glowColor: colorVal,
                              borderWidth: isSelected ? 1.5 : 1.0,
                              borderRadius: BorderRadius.circular(16),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    height: 8,
                                    width: 8,
                                    decoration: BoxDecoration(color: colorVal, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : RythemeTheme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Glass opacity slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Glass Surfaces Opacity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText)),
                      Text('${(customProvider.glassOpacityMultiplier * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor)),
                    ],
                  ),
                  Slider(
                    value: customProvider.glassOpacityMultiplier,
                    min: 0.4,
                    max: 1.8,
                    activeColor: accentColor,
                    inactiveColor: Colors.white.withOpacity(0.06),
                    onChanged: (val) => customProvider.setGlassOpacity(val),
                  ),

                  const SizedBox(height: 16),

                  // 3. UI Font scale slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('UI Text Scaling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: RythemeTheme.secondaryText)),
                      Text('Scale: x${customProvider.uiScale.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor)),
                    ],
                  ),
                  Slider(
                    value: customProvider.uiScale,
                    min: 0.8,
                    max: 1.3,
                    activeColor: accentColor,
                    inactiveColor: Colors.white.withOpacity(0.06),
                    onChanged: (val) => customProvider.setUiScale(val),
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
