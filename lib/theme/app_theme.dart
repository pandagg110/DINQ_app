import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandBlack = Color(0xFF171717);
  static const Color brandWhite = Color(0xFFFFFFFF);

  /// 全局页面/顶栏统一底色（对齐 `my_first_app` DinqTokens.bgPage 米白），
  /// 使顶部导航栏与页面同色、消除白/米白色缝。
  static const Color brandPage = Color(0xFFFAF9F6);
  static const Color brandGray = Color(0xFFF9F9F9);
  static const Color brandLightGray = Color(0xFFEDEDE5);

  /// 用于可能包含 emoji 的文案，确保系统用 emoji 字体渲染
  static const List<String> emojiFontFallback = [
    'Segoe UI Emoji',
    'Apple Color Emoji',
    'Noto Color Emoji',
  ];

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: brandBlack,
      scaffoldBackgroundColor: brandPage,
      textTheme: _textTheme(base.textTheme),
      colorScheme: base.colorScheme.copyWith(
        primary: brandBlack,
        secondary: brandBlack,
        surface: brandWhite,
        // M3 默认紫色 surfaceTint 会在弹出菜单/对话框的 elevation 上泄漏
        // （integration 页下拉菜单紫色底的根因），全局压掉
        surfaceTint: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: brandWhite,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: brandPage,
        foregroundColor: brandBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Geist',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: brandBlack,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlack,
          foregroundColor: brandWhite,
          textStyle: const TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF171717), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE12C2C), width: 1),
        ),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Geist'),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Geist'),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Geist'),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Geist'),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Geist'),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Geist'),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Geist'),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Geist'),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Geist'),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Geist'),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Geist'),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Geist'),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Geist'),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Geist'),
    );
  }
}
