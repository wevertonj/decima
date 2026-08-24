import 'package:decima/domain/paste_input_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasteInputParser', () {
    group('single number', () {
      test('should parse integer at face value (1250 -> 1250.00)', () {
        final tokens = PasteInputParser.parse('1250');

        expect(tokens, equals(['1250.00']));
      });

      test('should parse decimal with dot preserving precision', () {
        final tokens = PasteInputParser.parse('12.50');

        expect(tokens, equals(['12.50']));
      });

      test('should parse decimal with comma as decimal separator', () {
        final tokens = PasteInputParser.parse('12,50');

        expect(tokens, equals(['12.50']));
      });

      test('should parse decimal with dot thousands and comma decimal', () {
        final tokens = PasteInputParser.parse('1.000,00');

        expect(tokens, equals(['1000.00']));
      });

      test('should parse decimal with comma thousands and dot decimal', () {
        final tokens = PasteInputParser.parse('1,000.00');

        expect(tokens, equals(['1000.00']));
      });

      test(
        'should parse decimal with single fractional digit (12.5 -> 12.50)',
        () {
          final tokens = PasteInputParser.parse('12.5');

          expect(tokens, equals(['12.50']));
        },
      );

      test('should parse zero', () {
        final tokens = PasteInputParser.parse('0');

        expect(tokens, equals(['0.00']));
      });
    });

    group('expression', () {
      test('should parse simple addition with spaces', () {
        final tokens = PasteInputParser.parse('10 + 5');

        expect(tokens, equals(['10.00', '+', '5.00']));
      });

      test('should normalize asterisk to multiplication operator', () {
        final tokens = PasteInputParser.parse('100 * 3');

        expect(tokens, equals(['100.00', '×', '3.00']));
      });

      test('should normalize slash to division operator', () {
        final tokens = PasteInputParser.parse('100/4');

        expect(tokens, equals(['100.00', '÷', '4.00']));
      });

      test('should normalize hyphen to subtraction operator', () {
        final tokens = PasteInputParser.parse('10 - 3');

        expect(tokens, equals(['10.00', '−', '3.00']));
      });

      test('should accept native unicode operators', () {
        final tokens = PasteInputParser.parse('10 × 5');

        expect(tokens, equals(['10.00', '×', '5.00']));
      });

      test('should parse expression with parentheses', () {
        final tokens = PasteInputParser.parse('(10 + 5) × 2');

        expect(tokens, equals(['(', '10.00', '+', '5.00', ')', '×', '2.00']));
      });

      test('should parse expression with literal percent', () {
        final tokens = PasteInputParser.parse('100 + 10%');

        expect(tokens, equals(['100.00', '+', '10.00%']));
      });

      test('should preserve thousands separators inside expression', () {
        final tokens = PasteInputParser.parse('1.000,00 + 50');

        expect(tokens, equals(['1000.00', '+', '50.00']));
      });
    });

    group('invalid input', () {
      test('should return null for empty string', () {
        expect(PasteInputParser.parse(''), isNull);
      });

      test('should return null for whitespace only', () {
        expect(PasteInputParser.parse('   '), isNull);
      });

      test('should return null for non-numeric text', () {
        expect(PasteInputParser.parse('abc'), isNull);
      });

      test('should return null for trailing operator', () {
        expect(PasteInputParser.parse('10 +'), isNull);
      });

      test('should return null for leading operator', () {
        expect(PasteInputParser.parse('+ 10'), isNull);
      });

      test('should return null for unbalanced parentheses', () {
        expect(PasteInputParser.parse('(10 + 5'), isNull);
      });

      test('should return null for two consecutive operators', () {
        expect(PasteInputParser.parse('10 ++ 5'), isNull);
      });

      test('should return null for empty parentheses', () {
        expect(PasteInputParser.parse('()'), isNull);
      });
    });
  });
}
