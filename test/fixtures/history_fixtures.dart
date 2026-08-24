import 'dart:convert';

import 'package:decima/data/models/history_model.dart';
import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';

class HistoryFixtures {
  HistoryFixtures._();

  static final DateTime timestamp1 = DateTime(2026, 1, 15, 10, 30);
  static final DateTime timestamp2 = DateTime(2026, 1, 15, 11, 45);
  static final DateTime timestamp3 = DateTime(2026, 1, 16, 9, 0);

  /// Helper to create a single-line entry from an expression/result pair.
  static HistoryEntry singleLine({
    int? id,
    required String expression,
    required String result,
    required DateTime createdAt,
    String? name,
    bool isFavorite = false,
  }) {
    return HistoryEntry(
      id: id,
      lines: [HistoryLine(expression: expression, result: result)],
      result: result,
      createdAt: createdAt,
      name: name,
      isFavorite: isFavorite,
    );
  }

  static HistoryEntry get entry1 => singleLine(
    id: 1,
    expression: '12.50 + 3.00',
    result: '15.50',
    createdAt: timestamp1,
  );

  static HistoryEntry get entry2 => singleLine(
    id: 2,
    expression: '100.00 × 2.00',
    result: '200.00',
    createdAt: timestamp2,
  );

  static HistoryEntry get entry3 => singleLine(
    id: 3,
    expression: '50.00 − 25.00',
    result: '25.00',
    createdAt: timestamp3,
  );

  static HistoryEntry get entryWithName => singleLine(
    id: 4,
    expression: '500.00 ÷ 2.00',
    result: '250.00',
    createdAt: timestamp1,
    name: 'Conta do mercado',
  );

  static HistoryEntry get entryFavorite => singleLine(
    id: 5,
    expression: '1000.00 + 500.00',
    result: '1500.00',
    createdAt: timestamp2,
    isFavorite: true,
  );

  static HistoryEntry get entryWithNameAndFavorite => singleLine(
    id: 6,
    expression: '200.00 × 3.00',
    result: '600.00',
    createdAt: timestamp3,
    name: 'Orçamento mensal',
    isFavorite: true,
  );

  static List<HistoryEntry> get entries => [entry1, entry2, entry3];

  static String _encodeLine(String expression, String result) {
    return jsonEncode([
      {'expression': expression, 'result': result},
    ]);
  }

  static HistoryModel get model1 => HistoryModel(
    id: 1,
    linesJson: _encodeLine('12.50 + 3.00', '15.50'),
    result: '15.50',
    createdAt: timestamp1.millisecondsSinceEpoch,
  );

  static HistoryModel get model2 => HistoryModel(
    id: 2,
    linesJson: _encodeLine('100.00 × 2.00', '200.00'),
    result: '200.00',
    createdAt: timestamp2.millisecondsSinceEpoch,
  );

  static HistoryModel get modelWithName => HistoryModel(
    id: 4,
    linesJson: _encodeLine('500.00 ÷ 2.00', '250.00'),
    result: '250.00',
    createdAt: timestamp1.millisecondsSinceEpoch,
    name: 'Conta do mercado',
  );

  static HistoryModel get modelFavorite => HistoryModel(
    id: 5,
    linesJson: _encodeLine('1000.00 + 500.00', '1500.00'),
    result: '1500.00',
    createdAt: timestamp2.millisecondsSinceEpoch,
    isFavorite: true,
  );

  static Map<String, dynamic> get map1 => {
    'id': 1,
    'expression': _encodeLine('12.50 + 3.00', '15.50'),
    'result': '15.50',
    'created_at': timestamp1.millisecondsSinceEpoch,
    'name': null,
    'is_favorite': 0,
  };

  static Map<String, dynamic> get mapWithoutId => {
    'expression': _encodeLine('12.50 + 3.00', '15.50'),
    'result': '15.50',
    'created_at': timestamp1.millisecondsSinceEpoch,
    'name': null,
    'is_favorite': 0,
  };

  static Map<String, dynamic> get mapWithName => {
    'id': 4,
    'expression': _encodeLine('500.00 ÷ 2.00', '250.00'),
    'result': '250.00',
    'created_at': timestamp1.millisecondsSinceEpoch,
    'name': 'Conta do mercado',
    'is_favorite': 0,
  };

  static Map<String, dynamic> get mapFavorite => {
    'id': 5,
    'expression': _encodeLine('1000.00 + 500.00', '1500.00'),
    'result': '1500.00',
    'created_at': timestamp2.millisecondsSinceEpoch,
    'name': null,
    'is_favorite': 1,
  };
}
