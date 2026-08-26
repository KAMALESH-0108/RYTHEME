import 'package:flutter/material.dart';

class CustomizationProvider with ChangeNotifier {
  // Theme Accent Colors mapping
  static const Map<String, Color> accentColors = {
    'Bright Red': Color(0xFFFF1F2D),
    'Crimson': Color(0xFFA5000A),
    'Cyberpunk Blue': Color(0xFF00E5FF),
    'Emerald Green': Color(0xFF00E676),
  };

  String _currentAccentName = 'Bright Red';
  double _glassOpacityMultiplier = 1.0;
  double _uiScale = 1.0;

  // Getters
  String get currentAccentName => _currentAccentName;
  Color get accentColor => accentColors[_currentAccentName]!;
  double get glassOpacityMultiplier => _glassOpacityMultiplier;
  double get uiScale => _uiScale;

  // Setters
  void setAccentColor(String name) {
    if (accentColors.containsKey(name)) {
      _currentAccentName = name;
      notifyListeners();
    }
  }

  void setGlassOpacity(double value) {
    _glassOpacityMultiplier = value.clamp(0.4, 1.8);
    notifyListeners();
  }

  void setUiScale(double value) {
    _uiScale = value.clamp(0.8, 1.3);
    notifyListeners();
  }

  void resetCustomizations() {
    _currentAccentName = 'Bright Red';
    _glassOpacityMultiplier = 1.0;
    _uiScale = 1.0;
    notifyListeners();
  }
}
