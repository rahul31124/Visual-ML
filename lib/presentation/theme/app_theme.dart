import 'package:flutter/material.dart';

class AppColors {

  static const Color green = Color(0xFF10B981);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color darkGreen = Color(0xFF059669);
  static const Color deepGreen = Color(0xFF047857);
  static const Color lightGreen = Color(0xFFDCFCE7);
  static const Color softGreen = Color(0xFFF0FDF4);
  static const Color greenBorder = Color(0xFF86EFAC);
  static const Color greenBorderSubtle = Color(0xFFA7F3D0);

  static const Color primaryBlue = Color(0xFF0284C7);
  static const Color darkBlue = Color(0xFF0369A1);
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color lightBlue = Color(0xFFE0F2FE);
  static const Color softBlue = Color(0xFFF0F9FF);
  static const Color blueBorder = Color(0xFFBAE6FD);

  static const Color pink = Color(0xFFEC4899);
  static const Color darkPink = Color(0xFFDB2777);
  static const Color lightPink = Color(0xFFFCE7F3);
  static const Color softPink = Color(0xFFFDF2F8);
  static const Color pinkBorder = Color(0xFFFBCFE8);

  static const Color background = Colors.white;
  static const Color cardSurface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: AppColors.green,
      colorScheme: const ColorScheme.light(
        primary: AppColors.green,
        secondary: AppColors.primaryBlue,
        tertiary: AppColors.pink,
        surface: Colors.white,
      ),
      fontFamily: 'Segoe UI',
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1.0,
      ),
    );
  }
}
