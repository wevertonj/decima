import 'package:decima/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    group('light theme', () {
      test('should return a ThemeData', () {
        final theme = AppTheme.light(seedColor: Colors.amber);

        expect(theme, isA<ThemeData>());
      });

      test('should have light brightness', () {
        final theme = AppTheme.light(seedColor: Colors.amber);

        expect(theme.brightness, Brightness.light);
      });

      test('should use ColorScheme.fromSeed', () {
        final theme = AppTheme.light(seedColor: Colors.amber);

        expect(theme.colorScheme.brightness, Brightness.light);
      });

      test('should use Material 3', () {
        final theme = AppTheme.light(seedColor: Colors.amber);

        expect(theme.useMaterial3, isTrue);
      });
    });

    group('dark theme', () {
      test('should return a ThemeData', () {
        final theme = AppTheme.dark(seedColor: Colors.amber);

        expect(theme, isA<ThemeData>());
      });

      test('should have dark brightness', () {
        final theme = AppTheme.dark(seedColor: Colors.amber);

        expect(theme.brightness, Brightness.dark);
      });

      test('should use ColorScheme.fromSeed with dark brightness', () {
        final theme = AppTheme.dark(seedColor: Colors.amber);

        expect(theme.colorScheme.brightness, Brightness.dark);
      });

      test('should use Material 3', () {
        final theme = AppTheme.dark(seedColor: Colors.amber);

        expect(theme.useMaterial3, isTrue);
      });
    });

    group('seed color variation', () {
      test('should produce different color schemes for different seeds', () {
        final amberTheme = AppTheme.dark(seedColor: Colors.amber);
        final blueTheme = AppTheme.dark(seedColor: Colors.blue);

        expect(
          amberTheme.colorScheme.primary,
          isNot(equals(blueTheme.colorScheme.primary)),
        );
      });
    });
  });
}
