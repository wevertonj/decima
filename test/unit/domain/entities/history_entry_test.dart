import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistoryEntry', () {
    test('should create instance with required properties', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );

      expect(entry.id, 1);
      expect(entry.lines.first.expression, '12.50 + 3.00');
      expect(entry.result, '15.50');
      expect(entry.createdAt, createdAt);
      expect(entry.name, isNull);
      expect(entry.isFavorite, isFalse);
    });

    test('should create instance without id', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );

      expect(entry.id, isNull);
      expect(entry.lines.first.expression, '12.50 + 3.00');
      expect(entry.result, '15.50');
      expect(entry.createdAt, createdAt);
      expect(entry.name, isNull);
      expect(entry.isFavorite, isFalse);
    });

    test('should create instance with name', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        name: 'Conta do mercado',
      );

      expect(entry.name, 'Conta do mercado');
      expect(entry.isFavorite, isFalse);
    });

    test('should create instance with isFavorite true', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        isFavorite: true,
      );

      expect(entry.name, isNull);
      expect(entry.isFavorite, isTrue);
    });

    test('should create instance with name and isFavorite', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '200.00 × 3.00', result: '600.00')],
        result: '600.00',
        createdAt: createdAt,
        name: 'Orçamento mensal',
        isFavorite: true,
      );

      expect(entry.name, 'Orçamento mensal');
      expect(entry.isFavorite, isTrue);
    });

    test('should support value equality', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry1 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );
      final entry2 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );

      expect(entry1, equals(entry2));
    });

    test('should support value equality with name and isFavorite', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry1 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        name: 'Test',
        isFavorite: true,
      );
      final entry2 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        name: 'Test',
        isFavorite: true,
      );

      expect(entry1, equals(entry2));
    });

    test('should not be equal with different name', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry1 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        name: 'Name A',
      );
      final entry2 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        name: 'Name B',
      );

      expect(entry1, isNot(equals(entry2)));
    });

    test('should not be equal with different isFavorite', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry1 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        isFavorite: false,
      );
      final entry2 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        isFavorite: true,
      );

      expect(entry1, isNot(equals(entry2)));
    });

    test('should not be equal with different ids', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry1 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );
      final entry2 = HistoryEntry(
        id: 2,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );

      expect(entry1, isNot(equals(entry2)));
    });

    test('should have consistent hashCode for equal instances', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry1 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        name: 'Test',
        isFavorite: true,
      );
      final entry2 = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        name: 'Test',
        isFavorite: true,
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('should create a copy with updated fields using copyWith', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );
      final copy = entry.copyWith(id: 2, result: '20.00');

      expect(copy.id, 2);
      expect(copy.lines.first.expression, '12.50 + 3.00');
      expect(copy.result, '20.00');
      expect(copy.createdAt, createdAt);
      expect(copy.name, isNull);
      expect(copy.isFavorite, isFalse);
    });

    test('should copyWith name', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );
      final copy = entry.copyWith(name: 'Meu cálculo');

      expect(copy.name, 'Meu cálculo');
      expect(copy.id, 1);
      expect(copy.lines.first.expression, '12.50 + 3.00');
    });

    test('should copyWith isFavorite', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
      );
      final copy = entry.copyWith(isFavorite: true);

      expect(copy.isFavorite, isTrue);
      expect(copy.id, 1);
    });

    test('should copyWith preserve existing name and isFavorite', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final entry = HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
        result: '15.50',
        createdAt: createdAt,
        name: 'Original',
        isFavorite: true,
      );
      final copy = entry.copyWith(id: 2);

      expect(copy.id, 2);
      expect(copy.name, 'Original');
      expect(copy.isFavorite, isTrue);
    });
  });
}
