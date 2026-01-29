import 'package:flutter/material.dart';

class GitHubConstants {
  // Language colors mapping
  static const Map<String, Color> languageColors = {
    'JavaScript': Color(0xFFF7DF1E),
    'TypeScript': Color(0xFF3178C6),
    'Python': Color(0xFF3776AB),
    'Java': Color(0xFFED8B00),
    'C++': Color(0xFF00599C),
    'C': Color(0xFFA8B9CC),
    'C#': Color(0xFF239120),
    'Go': Color(0xFF00ADD8),
    'Rust': Color(0xFF000000),
    'Ruby': Color(0xFFCC342D),
    'PHP': Color(0xFF777BB4),
    'Swift': Color(0xFFFA7343),
    'Kotlin': Color(0xFF7F52FF),
    'Dart': Color(0xFF0175C2),
    'HTML': Color(0xFFE34C26),
    'CSS': Color(0xFF1572B6),
    'Shell': Color(0xFF89E051),
    'PowerShell': Color(0xFF012456),
    'R': Color(0xFF276DC3),
    'Scala': Color(0xFFDC322F),
    'Clojure': Color(0xFF5881D8),
    'Haskell': Color(0xFF5D4F85),
    'Elixir': Color(0xFF4E2A8E),
    'Erlang': Color(0xFFA90533),
    'Lua': Color(0xFF000080),
    'Perl': Color(0xFF39457E),
    'MATLAB': Color(0xFFE16737),
    'Objective-C': Color(0xFF438EFF),
    'Vue': Color(0xFF4FC08D),
    'React': Color(0xFF61DAFB),
    'Angular': Color(0xFFDD0031),
    'Svelte': Color(0xFFFF3E00),
  };

  static Color getLanguageColor(String language) {
    return languageColors[language] ?? const Color(0xFFE5E7EB);
  }
}

