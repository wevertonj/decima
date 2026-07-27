import 'package:flutter_test/flutter_test.dart';
import 'package:decima/domain/entities/calculation.dart';

void main() {
  group('Calculation', () {
    test('should create instance with required properties', () {
      final timestamp = DateTime(2026, 1, 15, 10, 30);
      final calculation = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: timestamp,
      );

      expect(calculation.expression, '12.50 + 3.00');
      expect(calculation.result, '15.50');
      expect(calculation.timestamp, timestamp);
    });

    test('should support value equality', () {
      final timestamp = DateTime(2026, 1, 15, 10, 30);
      final calc1 = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: timestamp,
      );
      final calc2 = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: timestamp,
      );

      expect(calc1, equals(calc2));
    });

    test('should not be equal with different expressions', () {
      final timestamp = DateTime(2026, 1, 15, 10, 30);
      final calc1 = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: timestamp,
      );
      final calc2 = Calculation(
        expression: '10.00 + 5.50',
        result: '15.50',
        timestamp: timestamp,
      );

      expect(calc1, isNot(equals(calc2)));
    });

    test('should not be equal with different results', () {
      final timestamp = DateTime(2026, 1, 15, 10, 30);
      final calc1 = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: timestamp,
      );
      final calc2 = Calculation(
        expression: '12.50 + 3.00',
        result: '16.00',
        timestamp: timestamp,
      );

      expect(calc1, isNot(equals(calc2)));
    });

    test('should not be equal with different timestamps', () {
      final calc1 = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: DateTime(2026, 1, 15, 10, 30),
      );
      final calc2 = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: DateTime(2026, 1, 16, 10, 30),
      );

      expect(calc1, isNot(equals(calc2)));
    });

    test('should have consistent hashCode for equal instances', () {
      final timestamp = DateTime(2026, 1, 15, 10, 30);
      final calc1 = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: timestamp,
      );
      final calc2 = Calculation(
        expression: '12.50 + 3.00',
        result: '15.50',
        timestamp: timestamp,
      );

      expect(calc1.hashCode, equals(calc2.hashCode));
    });
  });
}
