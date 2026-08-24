import 'package:decima/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors', () {
    test('should have exactly 9 seed colors', () {
      expect(AppColors.seedColors, hasLength(9));
    });

    test('should contain only Color instances', () {
      for (final color in AppColors.seedColors) {
        expect(color, isA<Color>());
      }
    });

    test('should have a default seed color', () {
      expect(AppColors.defaultSeedColor, isA<Color>());
    });

    test('should have default seed color in the seed colors list', () {
      expect(AppColors.seedColors, contains(AppColors.defaultSeedColor));
    });
  });
}
