import 'package:flutter/material.dart';

class AppTheme {
  // 核心能量配色
  static const Color primaryGreen = Color(0xFF00E676); // 荧光跑步绿
  static const Color accentOrange = Color(0xFFFF6D00); // 能量橙
  static const Color darkBackground = Color(0xFF121418); // 深邃黑底
  static const Color cardDark = Color(0xFF1E222B); // 卡片深灰
  static const Color textLight = Color(0xFFF5F5F7); // 高亮白
  static const Color textMuted = Color(0xFF8E95A5); // 辅助灰

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentOrange,
        surface: cardDark,
        onSurface: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x0FFFFFFF), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
