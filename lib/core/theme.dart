import 'package:flutter/material.dart';

/// Central palette + theme, derived from the QuickSlot design language:
/// royal-blue primary, green "confirmed" accent, light-grey canvas, white cards
/// with generous rounding.
class AppColors {
  static const primary = Color(0xFF1B5FE0);
  static const primaryDark = Color(0xFF1247B8);
  static const success = Color(0xFF1F9D57);
  static const successBg = Color(0xFFE3F5EC);
  static const bg = Color(0xFFF4F6F9);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF14141C);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE6E8EC);
  static const chipBg = Color(0xFFEEF1F5);
  static const danger = Color(0xFFDC2626);
  static const star = Color(0xFFF5A623);
}

class AppRadius {
  static const card = 16.0;
  static const chip = 24.0;
  static const button = 14.0;
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      // Force dark text on EVERY style (incl. bodyLarge, which TextField uses
      // for typed input) so nothing renders white-on-white in dark mode.
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            headlineLarge: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            titleLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            bodySmall: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
    );
  }
}
