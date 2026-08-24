import 'dart:async';

import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/entities/history_selection.dart';
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
    group('equals', () {
      test('should evaluate expression and add to timeline', () {
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

        expect(viewModel.timelineEntries, isNotEmpty);
      });

      test('should reset for new calculation after equals', () {
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

        expect(viewModel.currentOperator, isNull);
      });

      test('should set result as current display after equals', () {
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

        expect(viewModel.currentDisplayValue, '15.50');
      });

      test('should persist session to history repository on clear', () {
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
        viewModel.clear();

        verify(() => mockHistoryRepository.add(any())).called(1);
      });

      test('should do nothing when only first number is entered', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.equals();

        expect(viewModel.timelineEntries, isEmpty);
        verifyNever(() => mockHistoryRepository.add(any()));
      });

      test('should notify listeners after equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');

        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.equals();

        expect(notified, true);
      });
    });

    group('clear', () {
      test('should reset display to 0.00', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.clear();

        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should clear expression', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.clear();

        expect(viewModel.expression, '');
      });

      test('should clear current operator', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.clear();

        expect(viewModel.currentOperator, isNull);
      });

      test('should clear preview result', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.clear();

        expect(viewModel.previewResult, isNull);
      });

      test('should clear session timeline', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.equals();
        viewModel.clear();

        expect(viewModel.timelineEntries, isEmpty);
      });

      test('should notify listeners on clear', () {
        viewModel.inputDigit('1');
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.clear();

        expect(notified, true);
      });
    });

    group('clear with empty state', () {
      test('should be a no-op when there is nothing to clear', () {
        var notified = false;
        viewModel.addListener(() => notified = true);

        viewModel.clear();

        expect(notified, false);
        expect(viewModel.hasContent, false);
        expect(viewModel.currentDisplayValue, '0.00');
      });
    });

    group('flushSession', () {
      /// Digita `10.00 + 5.00` sem pressionar `=`.
      void typePendingSum() {
        for (final d in ['1', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');
        for (final d in ['5', '0', '0']) {
          viewModel.inputDigit(d);
        }
      }

      HistoryEntry capturedAdd() {
        return verify(
              () => mockHistoryRepository.add(captureAny()),
            ).captured.single
            as HistoryEntry;
      }

      test(
        'should persist a pending expression that was never equalled',
        () async {
          typePendingSum();

          await viewModel.flushSession();

          final entry = capturedAdd();
          expect(entry.lines.single.expression, '10.00 + 5.00');
          expect(entry.lines.single.result, '15.00');
        },
      );

      test('should auto-close open parentheses before evaluating', () async {
        viewModel.inputParenthesis();
        typePendingSum();

        await viewModel.flushSession();

        final entry = capturedAdd();
        expect(entry.lines.single.expression, '( 10.00 + 5.00 )');
        expect(entry.lines.single.result, '15.00');
      });

      test(
        'should not persist a bare number typed without an operator',
        () async {
          viewModel.inputDigit('1');
          viewModel.inputDigit('2');

          await viewModel.flushSession();

          expect(viewModel.timelineEntries, isEmpty);
          verifyNever(() => mockHistoryRepository.add(any()));
        },
      );

      test('should be a no-op on an empty session', () async {
        await viewModel.flushSession();

        expect(viewModel.timelineEntries, isEmpty);
        verifyNever(() => mockHistoryRepository.add(any()));
        verifyNever(() => mockHistoryRepository.update(any()));
      });

      test(
        'should not duplicate the line when called right after equals',
        () async {
          typePendingSum();
          viewModel.equals();

          await viewModel.flushSession();

          expect(viewModel.timelineEntries, hasLength(1));
          verify(() => mockHistoryRepository.add(any())).called(1);
          verifyNever(() => mockHistoryRepository.update(any()));
        },
      );

      test('should be idempotent across repeated calls', () async {
        typePendingSum();

        await viewModel.flushSession();
        await viewModel.flushSession();

        expect(viewModel.timelineEntries, hasLength(1));
        verify(() => mockHistoryRepository.add(any())).called(1);
        verifyNever(() => mockHistoryRepository.update(any()));
      });

      test('should only complete after an in-flight add has landed', () async {
        final pendingAdd = Completer<HistoryEntry>();
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) => pendingAdd.future);
        typePendingSum();

        var landed = false;
        final flush = viewModel.flushSession().then((_) => landed = true);
        await Future<void>.delayed(Duration.zero);

        expect(landed, isFalse);

        pendingAdd.complete(HistoryFixtures.entry1);
        await flush;

        expect(landed, isTrue);
      });

      test(
        'should take the edit-mode path when the cursor is mid-expression',
        () async {
          typePendingSum();
          viewModel.moveCursorLeft();

          expect(viewModel.isEditingMidExpression, isTrue);

          await viewModel.flushSession();

          final entry = capturedAdd();
          expect(entry.lines.single.expression, '10.00 + 5.00');
          expect(viewModel.isEditingMidExpression, isFalse);
        },
      );

      test(
        'should update the same session when a line lands mid-add',
        () async {
          final pendingAdd = Completer<HistoryEntry>();
          when(
            () => mockHistoryRepository.add(any()),
          ).thenAnswer((_) => pendingAdd.future);

          typePendingSum();
          viewModel.equals();

          // Segunda linha com o `add` da primeira ainda em voo — não pode
          // virar uma segunda sessão.
          viewModel.setOperator('+');
          for (final d in ['1', '0', '0']) {
            viewModel.inputDigit(d);
          }
          viewModel.equals();

          pendingAdd.complete(
            HistoryFixtures.singleLine(
              id: 7,
              expression: '10.00 + 5.00',
              result: '15.00',
              createdAt: HistoryFixtures.timestamp1,
            ),
          );
          await viewModel.flushSession();

          verify(() => mockHistoryRepository.add(any())).called(1);
          final updated =
              verify(
                    () => mockHistoryRepository.update(captureAny()),
                  ).captured.single
                  as HistoryEntry;
          expect(updated.id, 7);
          expect(updated.lines, hasLength(2));
          expect(updated.lines.last.expression, '15.00 + 1.00');
        },
      );
    });

    group('loadSession', () {
      test('should load history entries into timeline', () {
        final entry = HistoryFixtures.entry1;
        viewModel.loadSession(HistorySelection(entry: entry, lineIndex: 0));

        expect(viewModel.timelineEntries.length, 1);
      });

      test('should set result as current display value', () {
        viewModel.loadSession(
          HistorySelection(entry: HistoryFixtures.entry1, lineIndex: 0),
        );

        expect(viewModel.currentDisplayValue, '15.50');
      });

      test('should clear current expression when loading session', () {
        viewModel.inputDigit('1');
        viewModel.setOperator('+');
        viewModel.loadSession(
          HistorySelection(entry: HistoryFixtures.entry1, lineIndex: 0),
        );

        expect(viewModel.expression, '');
        expect(viewModel.currentOperator, isNull);
      });

      test('should notify listeners when session is loaded', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.loadSession(
          HistorySelection(entry: HistoryFixtures.entry1, lineIndex: 0),
        );

        expect(notified, true);
      });
    });
  });
}
