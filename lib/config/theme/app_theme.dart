import 'package:decima/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Gerador de ThemeData claro e escuro usando ColorScheme.fromSeed.
class AppTheme {
  AppTheme._();

  static ThemeData light({required Color seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: AppColors.lightBackground,
      surfaceContainer: AppColors.lightSurfaceContainer,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
    );
  }

  static ThemeData dark({required Color seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: AppColors.darkBackground,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkSurfaceContainer,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }
}
