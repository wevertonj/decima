import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeModeOption', () {
    test('should have 3 values', () {
      expect(ThemeModeOption.values.length, 3);
    });

    test('should contain light, dark and system', () {
      expect(ThemeModeOption.values, contains(ThemeModeOption.light));
      expect(ThemeModeOption.values, contains(ThemeModeOption.dark));
      expect(ThemeModeOption.values, contains(ThemeModeOption.system));
    });
  });
}
