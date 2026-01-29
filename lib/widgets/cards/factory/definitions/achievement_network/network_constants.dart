import 'package:flutter/material.dart';

class NetworkConstants {
  // Color schemes matching TSX version
  static const Map<String, Map<String, Color>> colorSchemes = {
    'purple': {
      'main': Color(0xFFEFDFFF),
      'light': Color(0xFFF8F1FF),
      'divider': Color(0xFFCAB4EF),
      'textGray': Color(0xFF897C96),
    },
    'blue': {
      'main': Color(0xFFCCE5FF),
      'light': Color(0xFFE5F2FF),
      'divider': Color(0xFFB4D7EF),
      'textGray': Color(0xFF82909E),
    },
  };

  // Grid background color
  static const Color gridColor = Color(0xFFE5E7EB);

  // Golden background for center avatar
  static const Color goldenBackground = Color(0xFFFDE277);

  // Tag colors
  static const Color blueTagColor = Color(0xFFCAE3FF);
  static const Color purpleTagColor = Color(0xFFE2C6FF);

  static Map<String, Color> getColorScheme(bool isTopRow) {
    return isTopRow ? colorSchemes['blue']! : colorSchemes['purple']!;
  }

  // ViewBox size for SVG (percentage-based)
  static const double viewBoxSize = 100.0;

  // Connection points in viewBox coordinates
  static const double topJunctionY = 35.0;
  static const double bottomJunctionY = 65.0;
  static const double topConnectionY = 27.0;
  static const double bottomConnectionY = 73.0;
  static const List<double> connectionXPositions = [20.0, 50.0, 80.0];

  // Grid size (16x16 grid)
  static const String gridSize = '25px 25px';
}

