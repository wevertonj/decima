import 'dart:convert';

import 'package:decima/data/models/history_model.dart';
import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/history_fixtures.dart';

void main() {
  group('HistoryModel', () {
    test('should create instance with required properties', () {
      final model = HistoryFixtures.model1;

      expect(model.id, 1);
      expect(model.linesJson, isNotEmpty);
      expect(model.result, '15.50');
      expect(
        model.createdAt,
        HistoryFixtures.timestamp1.millisecondsSinceEpoch,
      );
      expect(model.name, isNull);
      expect(model.isFavorite, isFalse);
    });

    test('should create instance with name', () {
      final model = HistoryFixtures.modelWithName;

      expect(model.name, 'Conta do mercado');
      expect(model.isFavorite, isFalse);
    });

    test('should create instance with isFavorite', () {
      final model = HistoryFixtures.modelFavorite;

      expect(model.name, isNull);
      expect(model.isFavorite, isTrue);
    });

    group('toMap', () {
      test('should convert to map with all fields', () {
        final model = HistoryFixtures.model1;
        final map = model.toMap();

        expect(map['id'], 1);
        expect(map['expression'], isNotEmpty);
        expect(map['result'], '15.50');
        expect(
          map['created_at'],
          HistoryFixtures.timestamp1.millisecondsSinceEpoch,
        );
        expect(map['name'], isNull);
        expect(map['is_favorite'], 0);
      });

      test('should convert to map without id when id is null', () {
        final model = HistoryModel(
          linesJson: jsonEncode([
            {'expression': '12.50 + 3.00', 'result': '15.50'},
          ]),
          result: '15.50',
          createdAt: HistoryFixtures.timestamp1.millisecondsSinceEpoch,
        );
        final map = model.toMap();

        expect(map.containsKey('id'), isFalse);
        expect(map['expression'], isNotEmpty);
        expect(map['result'], '15.50');
        expect(
          map['created_at'],
          HistoryFixtures.timestamp1.millisecondsSinceEpoch,
        );
        expect(map['name'], isNull);
        expect(map['is_favorite'], 0);
      });

      test('should convert to map with name', () {
        final model = HistoryFixtures.modelWithName;
        final map = model.toMap();

        expect(map['name'], 'Conta do mercado');
        expect(map['is_favorite'], 0);
      });

      test('should convert to map with isFavorite true', () {
        final model = HistoryFixtures.modelFavorite;
        final map = model.toMap();

        expect(map['is_favorite'], 1);
        expect(map['name'], isNull);
      });
    });

    group('fromMap', () {
      test('should create model from map', () {
        final model = HistoryModel.fromMap(HistoryFixtures.map1);

        expect(model.id, 1);
        expect(model.linesJson, isNotEmpty);
        expect(model.result, '15.50');
        expect(
          model.createdAt,
          HistoryFixtures.timestamp1.millisecondsSinceEpoch,
        );
        expect(model.name, isNull);
        expect(model.isFavorite, isFalse);
      });

      test('should create model from map without id', () {
        final model = HistoryModel.fromMap(HistoryFixtures.mapWithoutId);

        expect(model.id, isNull);
        expect(model.linesJson, isNotEmpty);
      });

      test('should create model from map with name', () {
        final model = HistoryModel.fromMap(HistoryFixtures.mapWithName);

        expect(model.name, 'Conta do mercado');
        expect(model.isFavorite, isFalse);
      });

      test('should create model from map with isFavorite', () {
        final model = HistoryModel.fromMap(HistoryFixtures.mapFavorite);

        expect(model.name, isNull);
        expect(model.isFavorite, isTrue);
      });
    });

    group('toEntity', () {
      test('should convert to HistoryEntry entity', () {
        final model = HistoryFixtures.model1;
        final entity = model.toEntity();

        expect(entity, isA<HistoryEntry>());
        expect(entity.id, 1);
        expect(entity.lines, hasLength(1));
        expect(entity.lines.first.expression, '12.50 + 3.00');
        expect(entity.result, '15.50');
        expect(entity.createdAt, HistoryFixtures.timestamp1);
        expect(entity.name, isNull);
        expect(entity.isFavorite, isFalse);
      });

      test('should convert to entity with name', () {
        final model = HistoryFixtures.modelWithName;
        final entity = model.toEntity();

        expect(entity.name, 'Conta do mercado');
        expect(entity.isFavorite, isFalse);
      });

      test('should convert to entity with isFavorite', () {
        final model = HistoryFixtures.modelFavorite;
        final entity = model.toEntity();

        expect(entity.name, isNull);
        expect(entity.isFavorite, isTrue);
      });

      test('should handle legacy plain-text expression format', () {
        final model = HistoryModel(
          id: 1,
          linesJson: '12.50 + 3.00', // Legacy format: not JSON
          result: '15.50',
          createdAt: HistoryFixtures.timestamp1.millisecondsSinceEpoch,
        );
        final entity = model.toEntity();

        expect(entity.lines, hasLength(1));
        expect(entity.lines.first.expression, '12.50 + 3.00');
        expect(entity.lines.first.result, '15.50');
      });
    });

    group('fromEntity', () {
      test('should create model from HistoryEntry entity', () {
        final entity = HistoryFixtures.entry1;
        final model = HistoryModel.fromEntity(entity);

        expect(model.id, 1);
        expect(model.linesJson, isNotEmpty);
        // Verifica o round-trip do JSON
        final decoded = jsonDecode(model.linesJson) as List;
        expect(decoded, hasLength(1));
        expect(decoded.first['expression'], '12.50 + 3.00');
        expect(model.result, '15.50');
        expect(
          model.createdAt,
          HistoryFixtures.timestamp1.millisecondsSinceEpoch,
        );
        expect(model.name, isNull);
        expect(model.isFavorite, isFalse);
      });

      test('should create model from entity without id', () {
        final entity = HistoryEntry(
          lines: [HistoryLine(expression: '5.00 + 3.00', result: '8.00')],
          result: '8.00',
          createdAt: HistoryFixtures.timestamp1,
        );
        final model = HistoryModel.fromEntity(entity);

        expect(model.id, isNull);
        expect(model.linesJson, isNotEmpty);
      });

      test('should create model from entity with name', () {
        final entity = HistoryFixtures.entryWithName;
        final model = HistoryModel.fromEntity(entity);

        expect(model.name, 'Conta do mercado');
        expect(model.isFavorite, isFalse);
      });

      test('should create model from entity with isFavorite', () {
        final entity = HistoryFixtures.entryFavorite;
        final model = HistoryModel.fromEntity(entity);

        expect(model.name, isNull);
        expect(model.isFavorite, isTrue);
      });
    });
  });
}
