import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/ui/history/history_page.dart';
import 'package:decima/ui/history/history_view_model.dart';
import 'package:decima/ui/history/widgets/history_list_item.dart';

import '../../helpers/pump_app.dart';
import '../../mocks/mock_history_repository.dart';

void main() {
  late MockHistoryRepository mockHistoryRepository;
  late HistoryViewModel viewModel;

  final now = DateTime(2026, 4, 22, 10, 30);

  List<HistoryEntry> createEntries(int count, {bool favorites = false}) {
    return List.generate(
      count,
      (i) => HistoryEntry(
        id: i + 1,
        lines: [
          HistoryLine(
            expression: '${(i + 1) * 10}.00 + ${(i + 1) * 5}.00',
            result: '${(i + 1) * 15}.00',
          ),
        ],
        result: '${(i + 1) * 15}.00',
        createdAt: now.subtract(Duration(minutes: i)),
        isFavorite: favorites,
      ),
    );
  }

  setUp(() {
    mockHistoryRepository = MockHistoryRepository();

    // Default: empty history
    when(
      () => mockHistoryRepository.getPaginated(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => <HistoryEntry>[]);

    when(
      () => mockHistoryRepository.getFavorites(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => <HistoryEntry>[]);

    when(() => mockHistoryRepository.clear()).thenAnswer((_) async {});
    when(
      () => mockHistoryRepository.toggleFavorite(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockHistoryRepository.updateName(any(), any()),
    ).thenAnswer((_) async {});

    viewModel = HistoryViewModel(historyRepository: mockHistoryRepository);
  });

  group('HistoryPage', () {
    group('rendering', () {
      testWidgets('should display title and filter tabs', (tester) async {
        await tester.pumpApp(HistoryPage(viewModel: viewModel));

        expect(find.text('History'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);
      });

      testWidgets('should show empty state when no entries', (tester) async {
        await tester.pumpApp(HistoryPage(viewModel: viewModel));

        expect(find.text('No history yet'), findsOneWidget);
        expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      });

      testWidgets('should show entries when history is not empty', (
        tester,
      ) async {
        final entries = createEntries(3);
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        expect(find.byType(HistoryListItem), findsNWidgets(3));
      });

      testWidgets('should show expression and result in each item', (
        tester,
      ) async {
        final entries = [
          HistoryEntry(
            id: 1,
            lines: [HistoryLine(expression: '50.00 + 25.00', result: '75.00')],
            result: '75.00',
            createdAt: now,
          ),
        ];
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        expect(find.text('50.00 + 25.00'), findsOneWidget);
        expect(find.text('= 75.00'), findsOneWidget);
      });

      testWidgets('should show entry name when present', (tester) async {
        final entries = [
          HistoryEntry(
            id: 1,
            lines: [HistoryLine(expression: '100.00 × 2.00', result: '200.00')],
            result: '200.00',
            createdAt: now,
            name: 'Conta do mercado',
          ),
        ];
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        expect(find.text('Conta do mercado'), findsOneWidget);
      });
    });

    group('load more', () {
      testWidgets('should show load more when there are more entries', (
        tester,
      ) async {
        // Return exactly pageSize entries to trigger hasMore
        final entries = createEntries(20);
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Scroll to the bottom to find the load more button
        await tester.scrollUntilVisible(
          find.text('Load more'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Load more'), findsOneWidget);
      });
    });

    group('favorites', () {
      testWidgets('should toggle favorite when star is tapped', (tester) async {
        final entries = [
          HistoryEntry(
            id: 1,
            lines: [HistoryLine(expression: '10.00 + 5.00', result: '15.00')],
            result: '15.00',
            createdAt: now,
            isFavorite: false,
          ),
        ];
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Find the star within the HistoryListItem (not in the SegmentedButton)
        final starInItem = find.descendant(
          of: find.byType(HistoryListItem),
          matching: find.byIcon(Icons.star_outline_rounded),
        );
        expect(starInItem, findsOneWidget);

        // Tap the star
        await tester.tap(starInItem);
        await tester.pumpAndSettle();

        // Verify toggleFavorite was called
        verify(() => mockHistoryRepository.toggleFavorite(1)).called(1);

        // Now shows filled star within the item
        final filledStarInItem = find.descendant(
          of: find.byType(HistoryListItem),
          matching: find.byIcon(Icons.star_rounded),
        );
        expect(filledStarInItem, findsOneWidget);
      });

      testWidgets('should show empty favorites state when filter is active', (
        tester,
      ) async {
        // All entries returns some, favorites returns none
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => createEntries(3));

        when(
          () => mockHistoryRepository.getFavorites(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => <HistoryEntry>[]);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Tap "Favorites" tab
        await tester.tap(find.text('Favorites'));
        await tester.pumpAndSettle();

        expect(find.text('No favorites yet'), findsOneWidget);
        expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      });
    });

    group('clear history', () {
      testWidgets('should show confirmation dialog before clearing', (
        tester,
      ) async {
        final entries = createEntries(3);
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Tap delete icon in app bar
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(
          find.text(
            'Delete all history entries? This action cannot be undone.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('should clear history when confirmed', (tester) async {
        final entries = createEntries(3);
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Tap delete, then confirm
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        verify(() => mockHistoryRepository.clear()).called(1);
      });

      testWidgets('should not clear history when cancelled', (tester) async {
        final entries = createEntries(3);
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Tap delete, then cancel
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        verifyNever(() => mockHistoryRepository.clear());
      });
    });

    group('rename', () {
      testWidgets('should show rename dialog on long press', (tester) async {
        final entries = [
          HistoryEntry(
            id: 1,
            lines: [HistoryLine(expression: '10.00 + 5.00', result: '15.00')],
            result: '15.00',
            createdAt: now,
          ),
        ];
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Long press the entry
        await tester.longPress(find.byType(HistoryListItem));
        await tester.pumpAndSettle();

        expect(find.text('Rename'), findsOneWidget);
        expect(find.text('Entry name'), findsOneWidget);
      });

      testWidgets('should update name when rename is saved', (tester) async {
        final entries = [
          HistoryEntry(
            id: 1,
            lines: [HistoryLine(expression: '10.00 + 5.00', result: '15.00')],
            result: '15.00',
            createdAt: now,
          ),
        ];
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Long press, type name, save
        await tester.longPress(find.byType(HistoryListItem));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'My Calculation');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        verify(
          () => mockHistoryRepository.updateName(1, 'My Calculation'),
        ).called(1);
      });
    });

    group('expression truncation', () {
      testWidgets('should truncate long expressions', (tester) async {
        final entries = [
          HistoryEntry(
            id: 1,
            lines: [
              HistoryLine(
                expression:
                    '1000.00 + 2000.00 + 3000.00 + 4000.00 + 5000.00 + 6000.00',
                result: '21000.00',
              ),
            ],
            result: '21000.00',
            createdAt: now,
          ),
        ];
        when(
          () => mockHistoryRepository.getPaginated(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => entries);

        await tester.pumpApp(HistoryPage(viewModel: viewModel));
        await tester.pumpAndSettle();

        // Full expression should NOT be visible
        expect(
          find.text(
            '1000.00 + 2000.00 + 3000.00 + 4000.00 + 5000.00 + 6000.00',
          ),
          findsNothing,
        );
        // Truncated version with "..." should be visible
        expect(find.textContaining('...'), findsOneWidget);
      });
    });
  });
}
