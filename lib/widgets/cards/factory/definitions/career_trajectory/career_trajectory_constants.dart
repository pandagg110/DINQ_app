import 'package:flutter/material.dart';

class CareerTrajectoryConstants {
  // Color scheme based on TSX version
  static const List<String> colors = ['#E2C6FF', '#1487FA', '#DDFEBC']; // purple, blue, green

  static const Map<String, Map<String, Color>> colorSchemes = {
    'purple': {
      'main': Color(0xFFEFDFFF),
      'light': Color(0xFFF8F1FF),
      'divider': Color(0xFFCAB4EF),
      'textGray': Color(0xFF897C96),
      'iconColor': Color(0x661D0944),
    },
    'blue': {
      'main': Color(0xFFCCE5FF),
      'light': Color(0xFFE5F2FF),
      'divider': Color(0xFFB4D7EF),
      'textGray': Color(0xFF82909E),
      'iconColor': Color(0x66093344),
    },
    'green': {
      'main': Color(0xFFE3F5D1),
      'light': Color(0xFFF7FFEE),
      'divider': Color(0xFFDBEAC1),
      'textGray': Color(0xFF8B9085),
      'iconColor': Color(0xFF869874),
    },
  };

  static Color parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return const Color(0xFF1487FA);
    } catch (e) {
      return const Color(0xFF1487FA);
    }
  }

  static String getColorSchemeName(String segmentColor) {
    if (segmentColor == colors[0]) return 'purple';
    if (segmentColor == colors[1]) return 'blue';
    return 'green';
  }

  static Map<String, Color> getColorScheme(String segmentColor) {
    return colorSchemes[getColorSchemeName(segmentColor)] ?? colorSchemes['blue']!;
  }
}

