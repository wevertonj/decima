import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/utils/formatters/number_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumberFormatter', () {
    group('with dot separator', () {
      test('should format integer cents to dot format', () {
        final result = NumberFormatter.format(
          1250,
          separator: DecimalSeparator.dot,
        );

        expect(result, '12.50');
      });

      test('should format zero', () {
        final result = NumberFormatter.format(
          0,
          separator: DecimalSeparator.dot,
        );

        expect(result, '0.00');
      });

      test('should format small value (5 cents)', () {
        final result = NumberFormatter.format(
          5,
          separator: DecimalSeparator.dot,
        );

        expect(result, '0.05');
      });

      test('should format value with thousands separator', () {
        final result = NumberFormatter.format(
          1234567,
          separator: DecimalSeparator.dot,
          useThousandsSeparator: true,
        );

        expect(result, '12,345.67');
      });

      test('should format value without thousands separator', () {
        final result = NumberFormatter.format(
          1234567,
          separator: DecimalSeparator.dot,
          useThousandsSeparator: false,
        );

        expect(result, '12345.67');
      });

      test('should format large number with thousands separator', () {
        final result = NumberFormatter.format(
          100000000,
          separator: DecimalSeparator.dot,
          useThousandsSeparator: true,
        );

        expect(result, '1,000,000.00');
      });
    });

    group('with comma separator', () {
      test('should format integer cents to comma format', () {
        final result = NumberFormatter.format(
          1250,
          separator: DecimalSeparator.comma,
        );

        expect(result, '12,50');
      });

      test('should format zero', () {
        final result = NumberFormatter.format(
          0,
          separator: DecimalSeparator.comma,
        );

        expect(result, '0,00');
      });

      test('should format small value (5 cents)', () {
        final result = NumberFormatter.format(
          5,
          separator: DecimalSeparator.comma,
        );

        expect(result, '0,05');
      });

      test('should format value with thousands separator', () {
        final result = NumberFormatter.format(
          1234567,
          separator: DecimalSeparator.comma,
          useThousandsSeparator: true,
        );

        expect(result, '12.345,67');
      });

      test('should format value without thousands separator', () {
        final result = NumberFormatter.format(
          1234567,
          separator: DecimalSeparator.comma,
          useThousandsSeparator: false,
        );

        expect(result, '12345,67');
      });
    });

    group('negative values', () {
      test('should format negative value with dot separator', () {
        final result = NumberFormatter.format(
          -1250,
          separator: DecimalSeparator.dot,
        );

        expect(result, '-12.50');
      });

      test('should format negative value with comma separator', () {
        final result = NumberFormatter.format(
          -1250,
          separator: DecimalSeparator.comma,
        );

        expect(result, '-12,50');
      });

      test('should format negative value with thousands separator', () {
        final result = NumberFormatter.format(
          -1234567,
          separator: DecimalSeparator.dot,
          useThousandsSeparator: true,
        );

        expect(result, '-12,345.67');
      });
    });

    group('formatDouble', () {
      test('should format double with dot separator', () {
        final result = NumberFormatter.formatDouble(
          12.50,
          separator: DecimalSeparator.dot,
        );

        expect(result, '12.50');
      });

      test('should format double with comma separator', () {
        final result = NumberFormatter.formatDouble(
          12.50,
          separator: DecimalSeparator.comma,
        );

        expect(result, '12,50');
      });

      test('should format double with thousands separator', () {
        final result = NumberFormatter.formatDouble(
          12345.67,
          separator: DecimalSeparator.dot,
          useThousandsSeparator: true,
        );

        expect(result, '12,345.67');
      });

      test('should format zero double', () {
        final result = NumberFormatter.formatDouble(
          0.0,
          separator: DecimalSeparator.dot,
        );

        expect(result, '0.00');
      });
    });
  });
}
