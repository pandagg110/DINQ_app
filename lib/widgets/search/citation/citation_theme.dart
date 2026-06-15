import 'package:flutter/material.dart';

/// 与 TSX `CitationResults.tsx` 设计 token 对齐。
abstract final class CitationTheme {
  CitationTheme._();

  static const avatarScholar = 'assets/images/analysis/avatar_scholar.png';
  static const orcidIcon =
      'https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png';

  static const iconBase = 'assets/icons/search/citation/';
  static const iconFileText = '${iconBase}file-text.svg';
  static const iconQuote = '${iconBase}quote.svg';
  static const iconAward = '${iconBase}award.svg';
  static const iconBuilding = '${iconBase}building-2.svg';
  static const iconHash = '${iconBase}hash.svg';
  static const iconGraduation = 'assets/icons/search/progress/graduation-cap.svg';
  static const iconChevron = 'assets/icons/search/progress/chevron-down.svg';

  static const rankColor = Color(0xFFD8DEE9);
  static const titleAccent = Color(0xFF5E81AC);
  static const iconNordic = Color(0xFF81A1C1);
  static const paperAccent = Color(0xFFBF616A);
  static const borderLight = Color(0xFFE5E9F0);
  static const cardBorder = Color(0xFFF3F4F6);
  static const metricsBg = Color(0x1488C0D0);
  static const metricsBgStrong = Color(0x1A88C0D0);

  static const tagBackgrounds = [
    Color(0x80F5D97A),
    Color(0x80F5C4C4),
    Color(0x80C8E6A0),
  ];
  static const tagForegrounds = [
    Color(0xFF5E4A1E),
    Color(0xFF7A4A4A),
    Color(0xFF3D5E3D),
  ];

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1488C0D0),
      Color(0x0F5E81AC),
    ],
  );
}
