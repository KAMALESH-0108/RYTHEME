import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/customization_provider.dart';

enum GlassLevel {
  soft,      // Level 1: ~4-6% opacity
  standard,  // Level 2: ~7-10% opacity
  elevated,  // Level 3: ~10-15% opacity
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final GlassLevel level;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final bool hasRedGlow;
  final Color? glowColor;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    super.key,
    required this.child,
    this.level = GlassLevel.standard,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderWidth = 1.0,
    this.hasRedGlow = false,
    this.glowColor,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to active design customizations
    final customization = Provider.of<CustomizationProvider>(context);
    final themeAccentColor = customization.accentColor;
    final opacityMultiplier = customization.glassOpacityMultiplier;

    double opacity;
    double blurSigma;

    switch (level) {
      case GlassLevel.soft:
        opacity = (0.05 * opacityMultiplier).clamp(0.01, 0.95);
        blurSigma = 6.0;
        break;
      case GlassLevel.standard:
        opacity = (0.09 * opacityMultiplier).clamp(0.01, 0.95);
        blurSigma = 12.0;
        break;
      case GlassLevel.elevated:
        opacity = (0.14 * opacityMultiplier).clamp(0.01, 0.95);
        blurSigma = 20.0;
        break;
    }

    final doubleRadius = borderRadius ?? BorderRadius.circular(16.0);

    // Border Decoration
    final borderPaint = Border.all(
      color: Colors.white.withOpacity(((0.08 + (level.index * 0.02)) * opacityMultiplier).clamp(0.01, 0.95)),
      width: borderWidth,
    );

    final resolvedGlowColor = glowColor ?? themeAccentColor;

    // Box Decoration
    final decoration = BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: doubleRadius,
      border: borderPaint,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        if (hasRedGlow)
          BoxShadow(
            color: resolvedGlowColor.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
      ],
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: hasRedGlow
          ? BoxDecoration(
              borderRadius: doubleRadius,
              boxShadow: [
                BoxShadow(
                  color: resolvedGlowColor.withOpacity(0.18),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: doubleRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            alignment: alignment,
            padding: padding,
            decoration: decoration,
            child: child,
          ),
        ),
      ),
    );
  }
}
