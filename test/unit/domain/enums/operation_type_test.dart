import 'package:flutter_test/flutter_test.dart';
import 'package:decima/domain/enums/operation_type.dart';

void main() {
  group('OperationType', () {
    test('should have 4 values', () {
      expect(OperationType.values.length, 4);
    });

    test('should contain add', () {
      expect(OperationType.values, contains(OperationType.add));
    });

    test('should contain subtract', () {
      expect(OperationType.values, contains(OperationType.subtract));
    });

    test('should contain multiply', () {
      expect(OperationType.values, contains(OperationType.multiply));
    });

    test('should contain divide', () {
      expect(OperationType.values, contains(OperationType.divide));
    });

    test('should have correct symbols', () {
      expect(OperationType.add.symbol, '+');
      expect(OperationType.subtract.symbol, '−');
      expect(OperationType.multiply.symbol, '×');
      expect(OperationType.divide.symbol, '÷');
    });
  });
}
