import 'package:flutter/material.dart';

/// Paleta de 9 seed colors disponíveis para o usuário personalizar o tema.
class AppColors {
  AppColors._();

  static const List<Color> seedColors = [
    Color(0xFF005CEE), // Blue (padrão)
    Color(0xFF10B981), // Emerald
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFFF43F5E), // Rose
    Color(0xFF94A3B8), // Slate
    Color(0xFFF3DE2C), // Yellow
  ];

  static const Color defaultSeedColor = Color(0xFF005CEE);

  // Superfícies do tema escuro
  static const Color darkBackground = Color(0xFF181818);
  static const Color darkSurface = Color(0xFF212121);
  static const Color darkSurfaceContainer = Color(0xFF2D2D2D);

  // Superfícies do tema claro
  static const Color lightBackground = Color(0xFFF4F4F5);
  static const Color lightSurfaceContainer = Color(0xFFE8E8EA);
}
