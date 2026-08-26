import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RythemeTheme {
  // Brand Color Palette
  static const Color background = Color(0xFF030303);
  static const Color primaryBlack = Color(0xFF070707);
  static const Color secondaryBlack = Color(0xFF0D0D0D);

  // Glass Colors (opacity mapped to hex values)
  static const Color glassSurface = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color strongGlass = Color(0x1AFFFFFF);   // rgba(255,255,255,0.10)
  static const Color glassBorder = Color(0x1EFFFFFF);   // rgba(255,255,255,0.12)

  // Red & Crimson accents
  static const Color primaryRed = Color(0xFFE50914);
  static const Color brightRed = Color(0xFFFF1F2D);
  static const Color crimson = Color(0xFFA5000A);
  static const Color darkCrimson = Color(0xFF520005);

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB8B8B8);
  static const Color disabledText = Color(0xFF666666);

  // Status Colors
  static const Color success = Color(0xFF35D07F);
  static const Color warning = Color(0xFFFFB020);

  // Custom Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [primaryBlack, darkCrimson, crimson],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0x66520005), Color(0xAA030303)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkFadeGradient = LinearGradient(
    colors: [Color(0xCC030303), Color(0xFF030303)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows
  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> redGlowShadow = [
    BoxShadow(
      color: primaryRed.withOpacity(0.3),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  // Theme Data Setup
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryRed,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: crimson,
        background: background,
        surface: primaryBlack,
        error: primaryRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 32),
          displayMedium: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 26),
          titleLarge: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 20),
          titleMedium: TextStyle(color: primaryText, fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(color: primaryText, fontSize: 16),
          bodyMedium: TextStyle(color: secondaryText, fontSize: 14),
          labelSmall: TextStyle(color: disabledText, fontSize: 12),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryText,
        size: 24,
      ),
    );
  }
}
