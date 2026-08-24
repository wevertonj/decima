import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/history_fixtures.dart';
import '../../../mocks/mock_clipboard_service.dart';
import '../../../mocks/mock_history_repository.dart';
import '../../../mocks/mock_settings_repository.dart';

void main() {
  late CalculatorViewModel viewModel;
  late MockHistoryRepository mockHistoryRepository;
  late MockSettingsRepository mockSettingsRepository;
  late MockClipboardService mockClipboardService;

  setUpAll(() {
    registerFallbackValue(
      HistoryEntry(
        lines: [HistoryLine(expression: '', result: '')],
        result: '',
        createdAt: DateTime(2026),
      ),
    );
    registerFallbackValue(DecimalSeparator.dot);
  });

  setUp(() {
    mockHistoryRepository = MockHistoryRepository();
    mockSettingsRepository = MockSettingsRepository();
    mockClipboardService = MockClipboardService();
    when(
      () => mockSettingsRepository.getDecimalSeparator(),
    ).thenAnswer((_) async => DecimalSeparator.dot);
    when(() => mockHistoryRepository.add(any())).thenAnswer(
      (_) async => HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '', result: '')],
        result: '',
        createdAt: DateTime(2026),
      ),
    );
    when(() => mockHistoryRepository.update(any())).thenAnswer((_) async {});
    when(() => mockClipboardService.copyText(any())).thenAnswer((_) async {});
    when(() => mockClipboardService.readText()).thenAnswer((_) async => null);
    viewModel = CalculatorViewModel(
      historyRepository: mockHistoryRepository,
      settingsRepository: mockSettingsRepository,
      clipboardService: mockClipboardService,
    );
  });

  group('CalculatorViewModel', () {
    group('timeline', () {
      test('should add entry to timeline after each equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // First calculation
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.timelineEntries.length, 1);
      });

      test('should accumulate timeline entries across calculations', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // First calculation
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.equals();

        // Second calculation
        viewModel.setOperator('×');
        viewModel.inputDigit('2');
        viewModel.equals();

        expect(viewModel.timelineEntries.length, 2);
      });

      test('should have expression and result in timeline entry', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        final entry = viewModel.timelineEntries.first;
        expect(entry.expression, contains('+'));
        expect(entry.result, isNotEmpty);
      });

      test('should limit visible timeline entries', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // Perform many calculations to exceed visible limit
        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
          viewModel.inputDigit('1');
          viewModel.equals();
        }

        expect(
          viewModel.visibleTimelineEntries.length,
          lessThanOrEqualTo(viewModel.maxVisibleEntries),
        );
      });

      test('should have more entries available beyond visible', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
          viewModel.inputDigit('1');
          viewModel.equals();
        }

        expect(viewModel.hasMoreTimelineEntries, true);
      });

      test('should load more timeline entries', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
          viewModel.inputDigit('1');
          viewModel.equals();
        }

        final initialVisible = viewModel.visibleTimelineEntries.length;
        viewModel.loadMoreTimelineEntries();

        expect(
          viewModel.visibleTimelineEntries.length,
          greaterThan(initialVisible),
        );
      });
    });
  });
}
