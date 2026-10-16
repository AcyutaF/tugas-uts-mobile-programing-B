import 'package:flutter/material.dart';

class AppColors {
  static const black = Color(0xFF0B0B0B);
  static const surface = Color(0xFF171717);
  static const surfaceHigh = Color(0xFF222222);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF1D77A);
  static const textMuted = Color(0xFF9E9E9E);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: Colors.black,
    secondary: AppColors.goldLight,
    surface: AppColors.surface,
    onSurface: Colors.white,
    error: Color(0xFFEF6C6C),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.gold,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.gold,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.gold),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.gold),
      ),
    ),
  );
}