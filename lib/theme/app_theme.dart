import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color brandBlack = Color(0xFF171717);
  static const Color brandWhite = Color(0xFFFFFFFF);

  /// 全局页面/顶栏统一底色（对齐 `my_first_app` DinqTokens.bgPage 米白），
  /// 使顶部导航栏与页面同色、消除白/米白色缝。
  static const Color brandPage = Color(0xFFFAF9F6);
  static const Color brandGray = Color(0xFFF9F9F9);
  static const Color brandLightGray = Color(0xFFEDEDE5);

  /// 全局系统栏样式（Android edge-to-edge）。
  ///
  /// API 35+ 强制透明系统导航栏，`systemNavigationBarColor` 设实体色会被忽略，
  /// 露出 window 黑底 → 「底部黑边」。导航栏必须透明，由页面 bgPage 自己铺到底。
  static const SystemUiOverlayStyle pageSystemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarDividerColor: Colors.transparent,
  );

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
      // Switch：M3 默认用紫色系（未选中轨道 surfaceContainerHighest 是薰衣草紫，
      // QA 反馈"开关紫色"的根因）。对齐 web 开关配色：开=黑(#171717/#2a2826)、
      // 关=浅灰(#d6d3cc)、圆钮白色。
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(brandWhite),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.selected)
              ? brandBlack
              : const Color(0xFFD6D3CC),
        ),
        trackOutlineColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: brandPage,
        foregroundColor: brandBlack,
        elevation: 0,
        centerTitle: true,
        // 带 AppBar 的页面会覆盖全局 SystemChrome 设置，这里同样保持
        // Android 状态栏透明+深色图标，与米白页面底色统一。
        systemOverlayStyle: pageSystemUiOverlayStyle,
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
