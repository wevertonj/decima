import 'package:flutter_test/flutter_test.dart';
import 'package:decima/domain/enums/decimal_separator.dart';

void main() {
  group('DecimalSeparator', () {
    test('should have 2 values', () {
      expect(DecimalSeparator.values.length, 2);
    });

    test('should contain dot and comma', () {
      expect(DecimalSeparator.values, contains(DecimalSeparator.dot));
      expect(DecimalSeparator.values, contains(DecimalSeparator.comma));
    });

    test('should have correct character for dot', () {
      expect(DecimalSeparator.dot.character, '.');
    });

    test('should have correct character for comma', () {
      expect(DecimalSeparator.comma.character, ',');
    });
  });
}
