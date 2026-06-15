import 'package:flutter/material.dart';

/// 与 TSX `AdvisorsList.tsx` 设计 token 对齐。
abstract final class AdvisorTheme {
  AdvisorTheme._();

  static const iconBase = 'assets/icons/search/advisor/';
  static const iconStar = '${iconBase}star.svg';
  static const iconMail = '${iconBase}mail.svg';
  static const iconExternalLink = '${iconBase}external-link.svg';
  static const iconCheck = '${iconBase}check.svg';
  static const iconGraduation = 'assets/icons/search/progress/graduation-cap.svg';
  static const iconSchool = 'assets/icons/line-icons/school.svg';
  static const iconAnalyze = 'assets/icons/search/analyze.svg';
  static const iconRefresh = 'assets/icons/search/refresh.svg';
  static const iconGithub = 'assets/icons/search/lineicons/github.svg';
  static const iconLinkedin = 'assets/icons/search/lineicons/linkedin.svg';
  static const dinqLogo = 'assets/images/analysis/dinq-black.svg';
  static const avatarFallback = 'assets/images/analysis/avatar_scholar.png';

  static const scoreGood = Color(0xFFA3BE8C);
  static const scoreModerate = Color(0xFFEBCB8B);
  static const scoreLow = Color(0xFFBF616A);
  static const starInactive = Color(0xFFE5E7EB);
  static const reasonTitle = Color(0xFF5E81AC);
  static const reasonBg = Color(0x1A88C0D0);
  static const riskTitle = Color(0xB3EBCB8B);
  static const riskBg = Color(0x80FFFBEB);
  static const ratingsBg = Color(0x80F9FAFB);
  static const chipBg = Color(0xFFF5F4EF);
  static const chipBgHover = Color(0xFFF0EFE9);
  static const chipText = Color(0xFF6B6862);
  static const chipTextActive = Color(0xFF3D3B37);
  static const cardBorder = Color(0xFFE5E7EB);
  static const cardBorderHover = Color(0xFFD6D3CD);
  static const highlightBg = Color(0x99BFDBFE);
  static const matchBarColors = [
    Color(0xFF81A1C1),
    Color(0xFFD08770),
    Color(0xFFA3BE8C),
  ];
}
