import 'package:decima/domain/add2_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Add2Engine engine;

  setUp(() {
    engine = Add2Engine();
  });

  group('Add2Engine', () {
    group('initial state', () {
      test('should have raw digits as empty string', () {
        expect(engine.rawDigits, '');
      });

      test('should have formatted value as 0.00', () {
        expect(engine.formattedValue, '0.00');
      });

      test('should have integer value as 0', () {
        expect(engine.intValue, 0);
      });
    });

    group('inputDigit', () {
      test('should display 0.01 when pressing 1', () {
        engine.inputDigit('1');

        expect(engine.formattedValue, '0.01');
        expect(engine.rawDigits, '1');
      });

      test('should display 0.12 when pressing 1 then 2', () {
        engine.inputDigit('1');
        engine.inputDigit('2');

        expect(engine.formattedValue, '0.12');
        expect(engine.rawDigits, '12');
      });

      test('should display 1.25 when pressing 1, 2, 5', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('5');

        expect(engine.formattedValue, '1.25');
      });

      test('should display 12.50 when pressing 1, 2, 5, 0', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('5');
        engine.inputDigit('0');

        expect(engine.formattedValue, '12.50');
      });

      test('should display 125.00 when pressing 1, 2, 5, 0, 0', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('5');
        engine.inputDigit('0');
        engine.inputDigit('0');

        expect(engine.formattedValue, '125.00');
      });

      test('should handle large numbers correctly', () {
        // 1234567 raw = 12345.67
        for (final d in '1234567'.split('')) {
          engine.inputDigit(d);
        }

        expect(engine.formattedValue, '12345.67');
      });

      test('should ignore non-digit characters', () {
        engine.inputDigit('a');
        engine.inputDigit('.');
        engine.inputDigit('-');

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '');
      });

      test('should handle pressing 0 as first digit', () {
        engine.inputDigit('0');

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '0');
      });

      test('should handle pressing 0 multiple times', () {
        engine.inputDigit('0');
        engine.inputDigit('0');
        engine.inputDigit('0');

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '000');
      });
    });

    group('inputDoubleZero', () {
      test('should insert two zeros', () {
        engine.inputDigit('5');
        engine.inputDoubleZero();

        expect(engine.formattedValue, '5.00');
        expect(engine.rawDigits, '500');
      });

      test('should insert two zeros from empty', () {
        engine.inputDoubleZero();

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '00');
      });
    });

    group('inputTripleZero', () {
      test('should insert three zeros', () {
        engine.inputDigit('1');
        engine.inputTripleZero();

        expect(engine.formattedValue, '10.00');
        expect(engine.rawDigits, '1000');
      });

      test('should insert three zeros from empty', () {
        engine.inputTripleZero();

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '000');
      });

      test('should build large number with triple zeros', () {
        engine.inputDigit('5');
        engine.inputTripleZero();
        engine.inputTripleZero();

        expect(engine.formattedValue, '50000.00');
        expect(engine.rawDigits, '5000000');
      });
    });

    group('deleteLastDigit', () {
      test('should do nothing when empty', () {
        engine.deleteLastDigit();

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '');
      });

      test('should remove last digit and reformat', () {
        // 12.50 -> remove 0 -> 1.25
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('5');
        engine.inputDigit('0');
        engine.deleteLastDigit();

        expect(engine.formattedValue, '1.25');
        expect(engine.rawDigits, '125');
      });

      test('should go back to 0.12 from 1.25', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('5');
        engine.deleteLastDigit();

        expect(engine.formattedValue, '0.12');
      });

      test('should go back to 0.01 from 0.12', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.deleteLastDigit();

        expect(engine.formattedValue, '0.01');
      });

      test('should go back to 0.00 from 0.01', () {
        engine.inputDigit('1');
        engine.deleteLastDigit();

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '');
      });

      test('should handle multiple deletes to empty', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('3');
        engine.deleteLastDigit();
        engine.deleteLastDigit();
        engine.deleteLastDigit();

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '');
      });
    });

    group('reset', () {
      test('should clear all state', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('5');
        engine.inputDigit('0');
        engine.reset();

        expect(engine.formattedValue, '0.00');
        expect(engine.rawDigits, '');
        expect(engine.intValue, 0);
      });
    });

    group('intValue', () {
      test('should return integer representation of raw digits', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('5');
        engine.inputDigit('0');

        expect(engine.intValue, 1250);
      });

      test('should return 0 when empty', () {
        expect(engine.intValue, 0);
      });

      test('should return correct value for single digit', () {
        engine.inputDigit('5');

        expect(engine.intValue, 5);
      });
    });

    group('doubleValue', () {
      test('should return double value with 2 decimal places', () {
        // rawDigits = '1250' => 12.50
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.inputDigit('5');
        engine.inputDigit('0');

        expect(engine.doubleValue, 12.50);
      });

      test('should return 0.0 when empty', () {
        expect(engine.doubleValue, 0.0);
      });

      test('should return 0.01 for single digit 1', () {
        engine.inputDigit('1');

        expect(engine.doubleValue, 0.01);
      });

      test('should return 0.05 for single digit 5', () {
        engine.inputDigit('5');

        expect(engine.doubleValue, 0.05);
      });
    });

    group('isEmpty', () {
      test('should return true when no digits entered', () {
        expect(engine.isEmpty, true);
      });

      test('should return false after entering a digit', () {
        engine.inputDigit('1');

        expect(engine.isEmpty, false);
      });

      test('should return true after entering and deleting all digits', () {
        engine.inputDigit('1');
        engine.deleteLastDigit();

        expect(engine.isEmpty, true);
      });

      test('should return true after reset', () {
        engine.inputDigit('1');
        engine.inputDigit('2');
        engine.reset();

        expect(engine.isEmpty, true);
      });
    });

    group('setValue', () {
      test('should set value from integer cents', () {
        engine.setValue(1250);

        expect(engine.formattedValue, '12.50');
        expect(engine.intValue, 1250);
      });

      test('should set zero value', () {
        engine.setValue(0);

        expect(engine.formattedValue, '0.00');
        expect(engine.intValue, 0);
      });

      test('should set single digit value', () {
        engine.setValue(5);

        expect(engine.formattedValue, '0.05');
        expect(engine.intValue, 5);
      });

      test('should set large value', () {
        engine.setValue(1000000);

        expect(engine.formattedValue, '10000.00');
        expect(engine.intValue, 1000000);
      });
    });
  });
}
