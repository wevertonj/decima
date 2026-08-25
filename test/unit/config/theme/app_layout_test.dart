import 'package:decima/config/theme/app_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSpacing', () {
    test('should have correct xs value', () {
      expect(AppLayout.spacing.xs, 4.0);
    });

    test('should have correct small value', () {
      expect(AppLayout.spacing.small, 8.0);
    });

    test('should have correct medium value', () {
      expect(AppLayout.spacing.medium, 16.0);
    });

    test('should have correct large value', () {
      expect(AppLayout.spacing.large, 24.0);
    });

    test('should have correct xl value', () {
      expect(AppLayout.spacing.xl, 32.0);
    });
  });

  group('AppPadding', () {
    test('should have correct xs value', () {
      expect(AppLayout.padding.xs, 4.0);
    });

    test('should have correct small value', () {
      expect(AppLayout.padding.small, 8.0);
    });

    test('should have correct medium value', () {
      expect(AppLayout.padding.medium, 16.0);
    });

    test('should have correct large value', () {
      expect(AppLayout.padding.large, 24.0);
    });

    test('should have correct xl value', () {
      expect(AppLayout.padding.xl, 32.0);
    });
  });

  group('AppRadius', () {
    test('should have correct small value', () {
      expect(AppLayout.radius.small, 8.0);
    });

    test('should have correct medium value', () {
      expect(AppLayout.radius.medium, 16.0);
    });

    test('should have correct large value', () {
      expect(AppLayout.radius.large, 24.0);
    });

    test('should have correct circular value', () {
      expect(AppLayout.radius.circular, 100.0);
    });
  });
}
