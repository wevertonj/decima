import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:decima/data/database/app_database.dart';
import 'package:decima/data/repositories/history_repository_impl.dart';
import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';

import '../../../fixtures/history_fixtures.dart';

void main() {
  late AppDatabase appDatabase;
  late HistoryRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    appDatabase = AppDatabase(databaseFactory: databaseFactoryFfi);
    await appDatabase.initialize(inMemory: true);
    repository = HistoryRepositoryImpl(database: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  group('HistoryRepositoryImpl', () {
    group('add', () {
      test('should insert a new history entry and return it with id', () async {
        final entry = HistoryEntry(
          lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
          result: '15.50',
          createdAt: HistoryFixtures.timestamp1,
        );

        final result = await repository.add(entry);

        expect(result.id, isNotNull);
        expect(result.lines.first.expression, '12.50 + 3.00');
        expect(result.result, '15.50');
        expect(result.createdAt, HistoryFixtures.timestamp1);
        expect(result.name, isNull);
        expect(result.isFavorite, isFalse);
      });

      test('should insert entry with name and isFavorite', () async {
        final entry = HistoryEntry(
          lines: [HistoryLine(expression: '500.00 ÷ 2.00', result: '250.00')],
          result: '250.00',
          createdAt: HistoryFixtures.timestamp1,
          name: 'Conta do mercado',
          isFavorite: true,
        );

        final result = await repository.add(entry);

        expect(result.id, isNotNull);
        expect(result.name, 'Conta do mercado');
        expect(result.isFavorite, isTrue);
      });

      test('should auto-increment ids', () async {
        final entry1 = HistoryEntry(
          lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
          result: '15.50',
          createdAt: HistoryFixtures.timestamp1,
        );
        final entry2 = HistoryEntry(
          lines: [HistoryLine(expression: '100.00 × 2.00', result: '200.00')],
          result: '200.00',
          createdAt: HistoryFixtures.timestamp2,
        );

        final result1 = await repository.add(entry1);
        final result2 = await repository.add(entry2);

        expect(result2.id, greaterThan(result1.id!));
      });
    });

    group('getAll', () {
      test('should return empty list when no entries exist', () async {
        final entries = await repository.getAll();

        expect(entries, isEmpty);
      });

      test(
        'should return all entries ordered by createdAt descending',
        () async {
          await repository.add(
            HistoryEntry(
              lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
              result: '15.50',
              createdAt: HistoryFixtures.timestamp1,
            ),
          );
          await repository.add(
            HistoryEntry(
              lines: [HistoryLine(expression: '100.00 × 2.00', result: '200.00')],
              result: '200.00',
              createdAt: HistoryFixtures.timestamp2,
            ),
          );
          await repository.add(
            HistoryEntry(
              lines: [HistoryLine(expression: '50.00 − 25.00', result: '25.00')],
              result: '25.00',
              createdAt: HistoryFixtures.timestamp3,
            ),
          );

          final entries = await repository.getAll();

          expect(entries.length, 3);
          expect(entries[0].createdAt, HistoryFixtures.timestamp3);
          expect(entries[1].createdAt, HistoryFixtures.timestamp2);
          expect(entries[2].createdAt, HistoryFixtures.timestamp1);
        },
      );
    });

    group('getById', () {
      test('should return entry by id', () async {
        final added = await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
            result: '15.50',
            createdAt: HistoryFixtures.timestamp1,
            name: 'Test entry',
          ),
        );

        final result = await repository.getById(added.id!);

        expect(result, isNotNull);
        expect(result!.id, added.id);
        expect(result.lines.first.expression, '12.50 + 3.00');
        expect(result.name, 'Test entry');
      });

      test('should return null when id does not exist', () async {
        final result = await repository.getById(999);

        expect(result, isNull);
      });
    });

    group('getPaginated', () {
      test('should return first page of entries', () async {
        for (var i = 0; i < 5; i++) {
          await repository.add(
            HistoryEntry(
              lines: [HistoryLine(expression: 'expr $i', result: 'res $i')],
              result: 'res $i',
              createdAt: HistoryFixtures.timestamp1.add(Duration(minutes: i)),
            ),
          );
        }

        final entries = await repository.getPaginated(limit: 3, offset: 0);

        expect(entries.length, 3);
      });

      test('should return second page of entries', () async {
        for (var i = 0; i < 5; i++) {
          await repository.add(
            HistoryEntry(
              lines: [HistoryLine(expression: 'expr $i', result: 'res $i')],
              result: 'res $i',
              createdAt: HistoryFixtures.timestamp1.add(Duration(minutes: i)),
            ),
          );
        }

        final entries = await repository.getPaginated(limit: 3, offset: 3);

        expect(entries.length, 2);
      });

      test('should return entries ordered by createdAt descending', () async {
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: 'first', result: '1')],
            result: '1',
            createdAt: HistoryFixtures.timestamp1,
          ),
        );
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: 'second', result: '2')],
            result: '2',
            createdAt: HistoryFixtures.timestamp2,
          ),
        );
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: 'third', result: '3')],
            result: '3',
            createdAt: HistoryFixtures.timestamp3,
          ),
        );

        final entries = await repository.getPaginated(limit: 2, offset: 0);

        expect(entries[0].lines.first.expression, 'third');
        expect(entries[1].lines.first.expression, 'second');
      });

      test('should return empty list when offset exceeds total', () async {
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: 'expr', result: 'res')],
            result: 'res',
            createdAt: HistoryFixtures.timestamp1,
          ),
        );

        final entries = await repository.getPaginated(limit: 10, offset: 10);

        expect(entries, isEmpty);
      });
    });

    group('getFavorites', () {
      test('should return only favorite entries', () async {
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: 'not fav', result: '1')],
            result: '1',
            createdAt: HistoryFixtures.timestamp1,
          ),
        );
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: 'fav 1', result: '2')],
            result: '2',
            createdAt: HistoryFixtures.timestamp2,
            isFavorite: true,
          ),
        );
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: 'fav 2', result: '3')],
            result: '3',
            createdAt: HistoryFixtures.timestamp3,
            isFavorite: true,
          ),
        );

        final entries = await repository.getFavorites(limit: 10, offset: 0);

        expect(entries.length, 2);
        expect(entries.every((e) => e.isFavorite), isTrue);
      });

      test('should return paginated favorites', () async {
        for (var i = 0; i < 5; i++) {
          await repository.add(
            HistoryEntry(
              lines: [HistoryLine(expression: 'fav $i', result: 'res $i')],
              result: 'res $i',
              createdAt: HistoryFixtures.timestamp1.add(Duration(minutes: i)),
              isFavorite: true,
            ),
          );
        }

        final page1 = await repository.getFavorites(limit: 3, offset: 0);
        final page2 = await repository.getFavorites(limit: 3, offset: 3);

        expect(page1.length, 3);
        expect(page2.length, 2);
      });

      test('should return empty list when no favorites exist', () async {
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: 'not fav', result: '1')],
            result: '1',
            createdAt: HistoryFixtures.timestamp1,
          ),
        );

        final entries = await repository.getFavorites(limit: 10, offset: 0);

        expect(entries, isEmpty);
      });
    });

    group('updateName', () {
      test('should update name of an entry', () async {
        final added = await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
            result: '15.50',
            createdAt: HistoryFixtures.timestamp1,
          ),
        );

        await repository.updateName(added.id!, 'Meu cálculo');

        final updated = await repository.getById(added.id!);
        expect(updated!.name, 'Meu cálculo');
      });

      test('should set name to null', () async {
        final added = await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
            result: '15.50',
            createdAt: HistoryFixtures.timestamp1,
            name: 'Old name',
          ),
        );

        await repository.updateName(added.id!, null);

        final updated = await repository.getById(added.id!);
        expect(updated!.name, isNull);
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite from false to true', () async {
        final added = await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
            result: '15.50',
            createdAt: HistoryFixtures.timestamp1,
          ),
        );

        await repository.toggleFavorite(added.id!);

        final updated = await repository.getById(added.id!);
        expect(updated!.isFavorite, isTrue);
      });

      test('should toggle favorite from true to false', () async {
        final added = await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
            result: '15.50',
            createdAt: HistoryFixtures.timestamp1,
            isFavorite: true,
          ),
        );

        await repository.toggleFavorite(added.id!);

        final updated = await repository.getById(added.id!);
        expect(updated!.isFavorite, isFalse);
      });
    });

    group('delete', () {
      test('should delete a specific entry by id', () async {
        final added = await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
            result: '15.50',
            createdAt: HistoryFixtures.timestamp1,
          ),
        );
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '100.00 × 2.00', result: '200.00')],
            result: '200.00',
            createdAt: HistoryFixtures.timestamp2,
          ),
        );

        await repository.delete(added.id!);

        final entries = await repository.getAll();
        expect(entries.length, 1);
        expect(entries[0].lines.first.expression, '100.00 × 2.00');
      });
    });

    group('clear', () {
      test('should remove all entries', () async {
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '12.50 + 3.00', result: '15.50')],
            result: '15.50',
            createdAt: HistoryFixtures.timestamp1,
          ),
        );
        await repository.add(
          HistoryEntry(
            lines: [HistoryLine(expression: '100.00 × 2.00', result: '200.00')],
            result: '200.00',
            createdAt: HistoryFixtures.timestamp2,
          ),
        );

        await repository.clear();

        final entries = await repository.getAll();
        expect(entries, isEmpty);
      });
    });
  });
}
