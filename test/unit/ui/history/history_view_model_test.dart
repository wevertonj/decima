import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/ui/history/history_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/history_fixtures.dart';
import '../../../mocks/mock_history_repository.dart';

void main() {
  late HistoryViewModel viewModel;
  late MockHistoryRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      HistoryEntry(
        lines: [HistoryLine(expression: '', result: '')],
        result: '',
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockRepository = MockHistoryRepository();
    viewModel = HistoryViewModel(historyRepository: mockRepository);
  });

  group('HistoryViewModel', () {
    group('initial state', () {
      test('should have empty entries list', () {
        expect(viewModel.entries, isEmpty);
      });

      test('should have hasMore as false', () {
        expect(viewModel.hasMore, false);
      });

      test('should have isLoading as false', () {
        expect(viewModel.isLoading, false);
      });

      test('should have showFavoritesOnly as false', () {
        expect(viewModel.showFavoritesOnly, false);
      });
    });

    group('loadEntries', () {
      test('should load first page of entries', () async {
        final entries = [
          HistoryFixtures.entry1,
          HistoryFixtures.entry2,
          HistoryFixtures.entry3,
        ];

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => entries);

        await viewModel.loadEntries();

        expect(viewModel.entries, entries);
        expect(viewModel.isLoading, false);
      });

      test('should set hasMore to true when full page returned', () async {
        final entries = List.generate(
          20,
          (i) => HistoryEntry(
            id: i + 1,
            lines: [
              HistoryLine(expression: '$i.00 + 1.00', result: '${i + 1}.00'),
            ],
            result: '${i + 1}.00',
            createdAt: DateTime(2026, 1, 1, i),
          ),
        );

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => entries);

        await viewModel.loadEntries();

        expect(viewModel.hasMore, true);
      });

      test('should set hasMore to false when partial page returned', () async {
        final entries = [HistoryFixtures.entry1, HistoryFixtures.entry2];

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => entries);

        await viewModel.loadEntries();

        expect(viewModel.hasMore, false);
      });

      test('should set isLoading during load', () async {
        final loadingStates = <bool>[];

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async {
          loadingStates.add(viewModel.isLoading);

          return [HistoryFixtures.entry1];
        });

        await viewModel.loadEntries();

        expect(loadingStates, [true]);
        expect(viewModel.isLoading, false);
      });

      test('should notify listeners when entries are loaded', () async {
        var notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadEntries();

        // At least 2 notifications: loading start + loading end
        expect(notifyCount, greaterThanOrEqualTo(2));
      });

      test('should reset pagination when loading entries', () async {
        // Load first page
        final firstPage = List.generate(
          20,
          (i) => HistoryEntry(
            id: i + 1,
            lines: [
              HistoryLine(expression: '$i.00 + 1.00', result: '${i + 1}.00'),
            ],
            result: '${i + 1}.00',
            createdAt: DateTime(2026, 1, 1, i),
          ),
        );

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => firstPage);

        await viewModel.loadEntries();
        expect(viewModel.entries.length, 20);

        // Reload from scratch
        final newEntries = [HistoryFixtures.entry1];
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => newEntries);

        await viewModel.loadEntries();
        expect(viewModel.entries.length, 1);
      });
    });

    group('loadMore', () {
      test('should load next page and append to entries', () async {
        // First page
        final firstPage = List.generate(
          20,
          (i) => HistoryEntry(
            id: i + 1,
            lines: [
              HistoryLine(expression: '$i.00 + 1.00', result: '${i + 1}.00'),
            ],
            result: '${i + 1}.00',
            createdAt: DateTime(2026, 1, 1, i),
          ),
        );

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => firstPage);

        await viewModel.loadEntries();

        // Second page
        final secondPage = [
          HistoryEntry(
            id: 21,
            lines: [HistoryLine(expression: '20.00 + 1.00', result: '21.00')],
            result: '21.00',
            createdAt: DateTime(2026, 1, 2),
          ),
        ];

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 20),
        ).thenAnswer((_) async => secondPage);

        await viewModel.loadMore();

        expect(viewModel.entries.length, 21);
        expect(viewModel.entries.last.id, 21);
      });

      test('should set hasMore to false when last page is partial', () async {
        final firstPage = List.generate(
          20,
          (i) => HistoryEntry(
            id: i + 1,
            lines: [
              HistoryLine(expression: '$i.00 + 1.00', result: '${i + 1}.00'),
            ],
            result: '${i + 1}.00',
            createdAt: DateTime(2026, 1, 1, i),
          ),
        );

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => firstPage);

        await viewModel.loadEntries();

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 20),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadMore();

        expect(viewModel.hasMore, false);
      });

      test('should not load more if hasMore is false', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadEntries();
        expect(viewModel.hasMore, false);

        await viewModel.loadMore();

        // Should not have called getPaginated again with offset 1
        verifyNever(() => mockRepository.getPaginated(limit: 20, offset: 1));
      });

      test('should not load more if already loading', () async {
        final firstPage = List.generate(
          20,
          (i) => HistoryEntry(
            id: i + 1,
            lines: [
              HistoryLine(expression: '$i.00 + 1.00', result: '${i + 1}.00'),
            ],
            result: '${i + 1}.00',
            createdAt: DateTime(2026, 1, 1, i),
          ),
        );

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => firstPage);

        await viewModel.loadEntries();

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 20),
        ).thenAnswer((_) async {
          // Simulate slow load — loadMore called again during this
          return [HistoryFixtures.entry1];
        });

        // Start loading and immediately try again
        final future1 = viewModel.loadMore();
        final future2 = viewModel.loadMore();

        await Future.wait([future1, future2]);

        // getPaginated with offset 20 should only have been called once
        verify(
          () => mockRepository.getPaginated(limit: 20, offset: 20),
        ).called(1);
      });
    });

    group('delete', () {
      test('should delete entry and remove from list', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer(
          (_) async => [
            HistoryFixtures.entry1,
            HistoryFixtures.entry2,
            HistoryFixtures.entry3,
          ],
        );

        await viewModel.loadEntries();

        when(() => mockRepository.delete(2)).thenAnswer((_) async {});

        await viewModel.deleteEntry(2);

        expect(viewModel.entries.length, 2);
        expect(viewModel.entries.any((e) => e.id == 2), false);
      });

      test('should notify listeners after delete', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadEntries();

        when(() => mockRepository.delete(1)).thenAnswer((_) async {});

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.deleteEntry(1);

        expect(notified, true);
      });
    });

    group('clearAll', () {
      test('should clear all entries and reset pagination', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer(
          (_) async => [HistoryFixtures.entry1, HistoryFixtures.entry2],
        );

        await viewModel.loadEntries();
        expect(viewModel.entries.length, 2);

        when(() => mockRepository.clear()).thenAnswer((_) async {});

        await viewModel.clearAll();

        expect(viewModel.entries, isEmpty);
        expect(viewModel.hasMore, false);
      });

      test('should notify listeners after clear', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadEntries();

        when(() => mockRepository.clear()).thenAnswer((_) async {});

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.clearAll();

        expect(notified, true);
      });
    });

    group('updateName', () {
      test('should update name of entry in list', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadEntries();

        when(
          () => mockRepository.updateName(1, 'Compras do mês'),
        ).thenAnswer((_) async {});

        await viewModel.updateName(1, 'Compras do mês');

        expect(viewModel.entries.first.name, 'Compras do mês');
      });

      test('should notify listeners after rename', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadEntries();

        when(
          () => mockRepository.updateName(1, 'Test'),
        ).thenAnswer((_) async {});

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.updateName(1, 'Test');

        expect(notified, true);
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite status of entry in list', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadEntries();
        expect(viewModel.entries.first.isFavorite, false);

        when(() => mockRepository.toggleFavorite(1)).thenAnswer((_) async {});

        await viewModel.toggleFavorite(1);

        expect(viewModel.entries.first.isFavorite, true);
      });

      test('should toggle back from favorite to non-favorite', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entryFavorite]);

        await viewModel.loadEntries();
        expect(viewModel.entries.first.isFavorite, true);

        when(() => mockRepository.toggleFavorite(5)).thenAnswer((_) async {});

        await viewModel.toggleFavorite(5);

        expect(viewModel.entries.first.isFavorite, false);
      });

      test('should notify listeners after toggle', () async {
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => [HistoryFixtures.entry1]);

        await viewModel.loadEntries();

        when(() => mockRepository.toggleFavorite(1)).thenAnswer((_) async {});

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.toggleFavorite(1);

        expect(notified, true);
      });
    });

    group('favorites filter', () {
      test('should load only favorites when filter is enabled', () async {
        final favorites = [HistoryFixtures.entryFavorite];

        when(
          () => mockRepository.getFavorites(limit: 20, offset: 0),
        ).thenAnswer((_) async => favorites);

        await viewModel.setShowFavoritesOnly(true);

        expect(viewModel.entries, favorites);
        expect(viewModel.showFavoritesOnly, true);
        verify(
          () => mockRepository.getFavorites(limit: 20, offset: 0),
        ).called(1);
      });

      test('should load all entries when filter is disabled', () async {
        final all = [HistoryFixtures.entry1, HistoryFixtures.entryFavorite];

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => all);

        await viewModel.setShowFavoritesOnly(false);

        expect(viewModel.entries, all);
        verify(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).called(1);
      });

      test('should reload entries when toggling filter', () async {
        // Load all first
        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer(
          (_) async => [HistoryFixtures.entry1, HistoryFixtures.entryFavorite],
        );

        await viewModel.loadEntries();
        expect(viewModel.entries.length, 2);

        // Toggle to favorites only
        final favorites = [HistoryFixtures.entryFavorite];
        when(
          () => mockRepository.getFavorites(limit: 20, offset: 0),
        ).thenAnswer((_) async => favorites);

        await viewModel.setShowFavoritesOnly(true);

        expect(viewModel.entries.length, 1);
        expect(viewModel.entries.first.isFavorite, true);
      });

      test('should paginate favorites with loadMore', () async {
        final firstPage = List.generate(
          20,
          (i) => HistoryEntry(
            id: i + 1,
            lines: [
              HistoryLine(expression: '$i.00 + 1.00', result: '${i + 1}.00'),
            ],
            result: '${i + 1}.00',
            createdAt: DateTime(2026, 1, 1, i),
            isFavorite: true,
          ),
        );

        when(
          () => mockRepository.getFavorites(limit: 20, offset: 0),
        ).thenAnswer((_) async => firstPage);

        await viewModel.setShowFavoritesOnly(true);

        final secondPage = [
          HistoryEntry(
            id: 21,
            lines: [HistoryLine(expression: '20.00 + 1.00', result: '21.00')],
            result: '21.00',
            createdAt: DateTime(2026, 1, 2),
            isFavorite: true,
          ),
        ];

        when(
          () => mockRepository.getFavorites(limit: 20, offset: 20),
        ).thenAnswer((_) async => secondPage);

        await viewModel.loadMore();

        expect(viewModel.entries.length, 21);
      });
    });

    group('notifications', () {
      test('should notify on loadEntries', () async {
        var notified = false;
        viewModel.addListener(() => notified = true);

        when(
          () => mockRepository.getPaginated(limit: 20, offset: 0),
        ).thenAnswer((_) async => []);

        await viewModel.loadEntries();

        expect(notified, true);
      });

      test('should notify on setShowFavoritesOnly', () async {
        when(
          () => mockRepository.getFavorites(limit: 20, offset: 0),
        ).thenAnswer((_) async => []);

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.setShowFavoritesOnly(true);

        expect(notified, true);
      });
    });
  });
}
