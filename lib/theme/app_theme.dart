import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandBlack = Color(0xFF171717);
  static const Color brandWhite = Color(0xFFFFFFFF);
  static const Color brandGray = Color(0xFFF9F9F9);
  static const Color brandLightGray = Color(0xFFEDEDE5);

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: brandBlack,
      scaffoldBackgroundColor: brandWhite,
      textTheme: _textTheme(base.textTheme),
      colorScheme: base.colorScheme.copyWith(
        primary: brandBlack,
        secondary: brandBlack,
        surface: brandWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: brandWhite,
        foregroundColor: brandBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF171717), width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Poppins'),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Poppins'),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Poppins'),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Poppins'),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Poppins'),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Poppins'),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Poppins'),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Poppins'),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Poppins'),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Poppins'),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Poppins'),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Poppins'),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Poppins'),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Poppins'),
    );
  }
}


