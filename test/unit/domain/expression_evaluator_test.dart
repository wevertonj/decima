import 'package:decima/domain/expression_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ExpressionEvaluator evaluator;

  setUp(() {
    evaluator = ExpressionEvaluator();
  });

  group('ExpressionEvaluator', () {
    group('basic operations', () {
      test('should evaluate simple addition', () {
        final result = evaluator.evaluate('12.50 + 3.00');

        expect(result, '15.50');
      });

      test('should evaluate simple subtraction', () {
        final result = evaluator.evaluate('50.00 − 25.00');

        expect(result, '25.00');
      });

      test('should evaluate simple multiplication', () {
        final result = evaluator.evaluate('10.00 × 3.00');

        expect(result, '30.00');
      });

      test('should evaluate simple division', () {
        final result = evaluator.evaluate('100.00 ÷ 4.00');

        expect(result, '25.00');
      });
    });

    group('operator precedence', () {
      test('should respect multiplication over addition', () {
        // 2 + 3 × 4 = 2 + 12 = 14
        final result = evaluator.evaluate('2.00 + 3.00 × 4.00');

        expect(result, '14.00');
      });

      test('should respect division over subtraction', () {
        // 20 - 10 ÷ 2 = 20 - 5 = 15
        final result = evaluator.evaluate('20.00 − 10.00 ÷ 2.00');

        expect(result, '15.00');
      });

      test('should respect multiplication over subtraction', () {
        // 10 - 2 × 3 = 10 - 6 = 4
        final result = evaluator.evaluate('10.00 − 2.00 × 3.00');

        expect(result, '4.00');
      });

      test(
        'should evaluate left to right for same precedence addition and subtraction',
        () {
          // 10 + 5 - 3 = 12
          final result = evaluator.evaluate('10.00 + 5.00 − 3.00');

          expect(result, '12.00');
        },
      );

      test(
        'should evaluate left to right for same precedence multiplication and division',
        () {
          // 12 × 2 ÷ 4 = 6
          final result = evaluator.evaluate('12.00 × 2.00 ÷ 4.00');

          expect(result, '6.00');
        },
      );

      test('should handle complex expression with all operators', () {
        // 10 + 2 × 3 − 4 ÷ 2 = 10 + 6 - 2 = 14
        final result = evaluator.evaluate('10.00 + 2.00 × 3.00 − 4.00 ÷ 2.00');

        expect(result, '14.00');
      });
    });

    group('percentage', () {
      test('should calculate percentage in addition context', () {
        // 100 + 10% = 100 + 10 = 110
        final result = evaluator.evaluate('100.00 + 10.00 %');

        expect(result, '110.00');
      });

      test('should calculate percentage in subtraction context', () {
        // 200 - 25% = 200 - 50 = 150
        final result = evaluator.evaluate('200.00 − 25.00 %');

        expect(result, '150.00');
      });

      test('should calculate percentage in multiplication context', () {
        // 200 × 10% = 20
        final result = evaluator.evaluate('200.00 × 10.00 %');

        expect(result, '20.00');
      });

      test('should calculate percentage in division context', () {
        // 200 ÷ 10% = 2000
        final result = evaluator.evaluate('200.00 ÷ 10.00 %');

        expect(result, '2000.00');
      });

      test('should parse literal % without space in addition', () {
        final result = evaluator.evaluate('100.00 + 10.00%');

        expect(result, '110.00');
      });

      test('should parse literal % without space in subtraction', () {
        final result = evaluator.evaluate('200.00 − 25.00%');

        expect(result, '150.00');
      });

      test('should parse literal % without space in multiplication', () {
        final result = evaluator.evaluate('200.00 × 10.00%');

        expect(result, '20.00');
      });

      test('should parse literal % without space in division', () {
        final result = evaluator.evaluate('200.00 ÷ 10.00%');

        expect(result, '2000.00');
      });

      test('should parse multiple literal % tokens in chained expression', () {
        // 100 + 10% → 110; depois + 5% do último operando (10) = 0.5 → 110.5
        final result = evaluator.evaluate('100.00 + 10.00% + 5.00%');

        expect(result, '110.50');
      });
    });

    group('edge cases', () {
      test('should return the number itself for single value expression', () {
        final result = evaluator.evaluate('42.50');

        expect(result, '42.50');
      });

      test('should handle zero values', () {
        final result = evaluator.evaluate('0.00 + 5.00');

        expect(result, '5.00');
      });

      test('should handle result of zero', () {
        final result = evaluator.evaluate('5.00 − 5.00');

        expect(result, '0.00');
      });

      test('should handle very large numbers', () {
        final result = evaluator.evaluate('999999.99 + 0.01');

        expect(result, '1000000.00');
      });

      test('should handle decimal precision correctly', () {
        // 0.10 + 0.20 não deve produzir 0.30000000000000004
        final result = evaluator.evaluate('0.10 + 0.20');

        expect(result, '0.30');
      });
    });

    group('error handling', () {
      test('should return error string for division by zero', () {
        final result = evaluator.evaluate('10.00 ÷ 0.00');

        expect(result, isNotNull);
        expect(result, isNot('10.00'));
      });

      test('should return null for empty expression', () {
        final result = evaluator.evaluate('');

        expect(result, isNull);
      });

      test('should return null for invalid expression', () {
        final result = evaluator.evaluate('+ +');

        expect(result, isNull);
      });

      test('should return null for expression with only operator', () {
        final result = evaluator.evaluate('+');

        expect(result, isNull);
      });

      test('should handle trailing operator gracefully', () {
        // "12.50 +" deve avaliar como apenas "12.50"
        final result = evaluator.evaluate('12.50 +');

        expect(result, '12.50');
      });
    });

    group('formatting', () {
      test('should format result with 2 decimal places', () {
        final result = evaluator.evaluate('10.00 ÷ 3.00');

        // 10/3 = 3.333... deve ser formatado com 2 casas decimais
        expect(result, '3.33');
      });

      test(
        'should remove unnecessary trailing zeros only up to 2 decimal places',
        () {
          final result = evaluator.evaluate('4.00 × 2.50');

          expect(result, '10.00');
        },
      );
    });

    group('parentheses', () {
      test('should evaluate simple parenthesized expression', () {
        // (5 + 3) × 2 = 16
        final result = evaluator.evaluate('( 5.00 + 3.00 ) × 2.00');

        expect(result, '16.00');
      });

      test('should override precedence with parentheses', () {
        // 2 × (3 + 4) = 14, e não (2 × 3) + 4 = 10
        final result = evaluator.evaluate('2.00 × ( 3.00 + 4.00 )');

        expect(result, '14.00');
      });

      test('should evaluate nested parentheses', () {
        // (10 × (2 + 3)) = 50
        final result = evaluator.evaluate('( 10.00 × ( 2.00 + 3.00 ) )');

        expect(result, '50.00');
      });

      test('should evaluate deeply nested parentheses', () {
        // ((((5 + 5)))) = 10
        final result = evaluator.evaluate('( ( ( ( 5.00 + 5.00 ) ) ) )');

        expect(result, '10.00');
      });

      test('should evaluate complex nested expression with all operators', () {
        // (10 × 50) + 30 + (48 ÷ (18 × 1.5%)) = 500 + 30 + (48 ÷ 0.27) = 707.78
        final result = evaluator.evaluate(
          '( 10.00 × 50.00 ) + 30.00 + ( 48.00 ÷ ( 18.00 × 1.50% ) )',
        );

        expect(result, isNotNull);
        // 18 × 1.5% no contexto × = 18 × 0.015 = 0.27
        // 48 ÷ 0.27 = 177.7777...
        // 500 + 30 + 177.78 = 707.78
        expect(result, '707.78');
      });

      test('should evaluate parentheses without spaces', () {
        final result = evaluator.evaluate('(5.00+3.00)×2.00');

        expect(result, '16.00');
      });

      test('should evaluate percentage inside parentheses', () {
        // (100 + 10%) × 2 → dentro: 100 + 10 = 110; × 2 = 220
        final result = evaluator.evaluate('( 100.00 + 10.00% ) × 2.00');

        expect(result, '220.00');
      });

      test('should return null for unbalanced opening parenthesis', () {
        final result = evaluator.evaluate('( 5.00 + 3.00');

        expect(result, isNull);
      });

      test('should return null for unbalanced closing parenthesis', () {
        final result = evaluator.evaluate('5.00 + 3.00 )');

        expect(result, isNull);
      });

      test('should return null for empty parentheses', () {
        final result = evaluator.evaluate('( )');

        expect(result, isNull);
      });

      test(
        'should evaluate paren result feeding into outer with precedence',
        () {
          // 5 + (2 × 3) = 11
          final result = evaluator.evaluate('5.00 + ( 2.00 × 3.00 )');

          expect(result, '11.00');
        },
      );

      test('should evaluate two parenthesized terms in sequence', () {
        // (2 + 3) × (4 + 1) = 5 × 5 = 25
        final result = evaluator.evaluate('( 2.00 + 3.00 ) × ( 4.00 + 1.00 )');

        expect(result, '25.00');
      });
    });
  });
}
