import 'package:flutter/material.dart';

/// 与 TSX analysis 卡片 Tailwind 设计 token 对齐。
abstract final class AnalysisTheme {
  AnalysisTheme._();

  static const primary = Color(0xFFCB7C5D);
  static const borderDefault = Color(0xFF8C827E);
  static const borderInline = Color(0xFFE5E7EB);
  static const cardBg = Color(0x99FFFFFF);
  static const iconBg = Color(0xFFF1E0D9);
  static const watermark = Color(0xFF7A7A7A);
  static const panelBg = Color(0xFFFAF2EF);
  static const panelBgAlt = Color(0xFFFDF0EB);
  static const panelBgMuted = Color(0xFFF6F2F1);
  static const actionBg = Color(0xFFFAF2EF);
  static const textMuted = Color(0xFF6B7280);
  static const textBody = Color(0xFF4D4846);

  /// TSX `text-xs`：12px / line-height 16px，Geist Sans。
  static const watermarkFontSize = 12.0;
  static const watermarkLineHeight = 16 / 12;
  static const fontGeist = 'Geist';

  static const radiusCard = 15.0;
  static const radiusMd = 4.0;
  static const radiusLg = 8.0;
  static const radiusSm = 2.0;
  static const paddingCard = 20.0;
  static const gapCard = 20.0;
  static const contentBottom = 8.0;
  static const watermarkInset = 0.0;
  static const minCardWidth = 376.0;
  static const cardGridGap = 16.0;
  static const fontUdc = 'UDC 1.04';

  static const heatmapCompactBreakpoint = 1055.0;
  static const gridTwoColumnBreakpoint = 768.0;
  static const smBreakpoint = 640.0;

  // 与 TSX Lucide 图标 / 源码 public 图片对齐
  static const actionBarChart = 'assets/images/analysis/action-bar-chart.svg';
  static const actionMicroscope = 'assets/images/analysis/action-microscope.svg';
  static const actionShuffle = 'assets/images/analysis/action-shuffle.svg';
  static const actionCheckCircle = 'assets/images/analysis/action-check-circle.svg';
  static const actionChevronDown = 'assets/images/analysis/action-chevron-down.svg';
  static const actionDot = 'assets/images/analysis/action-dot.svg';
  static const defaultCompany = 'assets/images/analysis/defaultCompany.png';
  static const defaultAvatar = 'assets/images/analysis/avatar.png';
}
