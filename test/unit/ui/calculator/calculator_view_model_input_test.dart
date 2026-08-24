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
    group('initial state', () {
      test('should have empty display value showing 0.00', () {
        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should have empty expression', () {
        expect(viewModel.expression, '');
      });

      test('should have no preview result', () {
        expect(viewModel.previewResult, isNull);
      });

      test('should have empty timeline', () {
        expect(viewModel.timelineEntries, isEmpty);
      });

      test('should have no current operator', () {
        expect(viewModel.currentOperator, isNull);
      });
    });

    group('inputDigit', () {
      test('should update display when pressing digits', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');

        expect(viewModel.currentDisplayValue, '12.50');
      });

      test('should notify listeners when digit is pressed', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.inputDigit('1');

        expect(notified, true);
      });
    });

    group('inputDoubleZero', () {
      test('should insert double zero', () {
        viewModel.inputDigit('5');
        viewModel.inputDoubleZero();

        expect(viewModel.currentDisplayValue, '5.00');
      });
    });

    group('inputTripleZero', () {
      test('should insert triple zero', () {
        viewModel.inputDigit('1');
        viewModel.inputTripleZero();

        expect(viewModel.currentDisplayValue, '10.00');
      });
    });

    group('setOperator', () {
      test('should set current operator', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');

        expect(viewModel.currentOperator, '+');
      });

      test('should build expression with first number and operator', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');

        expect(viewModel.expression, '12.50 +');
      });

      test('should allow entering second number after operator', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.currentDisplayValue, '3.00');
        expect(viewModel.expression, '12.50 +');
      });

      test('should show preview result when second number is entered', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.previewResult, '15.50');
      });

      test('should not show preview when operator just pressed', () {
        viewModel.inputDigit('2');
        viewModel.inputDigit('4');
        viewModel.inputDigit('5');
        viewModel.setOperator('+');

        // "2.45 +" has no valid second operand
        expect(viewModel.previewResult, isNull);
      });

      test('should not show preview after chained operator without value', () {
        viewModel.inputDigit('2');
        viewModel.inputDigit('4');
        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('−');

        // "2.45 + 3.00 −" has no valid last operand
        expect(viewModel.previewResult, isNull);
      });

      test('should show preview for chained expression with all operands', () {
        viewModel.inputDigit('2');
        viewModel.inputDigit('4');
        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('−');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        // "2.45 + 3.00 − 1.00" = 4.45
        expect(viewModel.previewResult, '4.45');
      });

      test('should allow chaining operations', () {
        // 12.50 + 3.00 = 15.50, then × ...
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');

        // Expression should contain the accumulated computation
        expect(viewModel.expression, contains('×'));
      });

      test('should preserve full expression when chaining operations', () {
        // Type: 2.42 + 0.03 + 0.08 + 0.11
        viewModel.inputDigit('2');
        viewModel.inputDigit('4');
        viewModel.inputDigit('2');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.setOperator('+');
        viewModel.inputDigit('8');
        viewModel.setOperator('+');
        viewModel.inputDigit('1');
        viewModel.inputDigit('1');

        // Should show full expression, NOT compacted
        expect(viewModel.fullDisplayText, '2.42 + 0.03 + 0.08 + 0.11');
      });

      test(
        'should replace operator when pressing another operator without entering digits',
        () {
          viewModel.inputDigit('1');
          viewModel.inputDigit('2');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');
          viewModel.setOperator('−');

          expect(viewModel.currentOperator, '−');
          expect(viewModel.expression, '12.50 −');
        },
      );

      test('should notify listeners when operator is set', () {
        viewModel.inputDigit('1');
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.setOperator('+');

        expect(notified, true);
      });
    });

    group('fullDisplayText', () {
      test('should return current value when no expression', () {
        expect(viewModel.fullDisplayText, '0.00');
      });

      test('should return expression when operator just pressed', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');

        expect(viewModel.fullDisplayText, '12.50 +');
      });

      test(
        'should return full inline expression when typing second number',
        () {
          viewModel.inputDigit('1');
          viewModel.inputDigit('2');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.setOperator('×');
          viewModel.inputDigit('5');
          viewModel.inputDigit('2');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');

          expect(viewModel.fullDisplayText, '12.50 × 52.00');
        },
      );

      test('should return result after equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.fullDisplayText, '15.00');
      });
    });

    group('thousands separator formatting', () {
      test('should format display with dot separator and thousands', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // Input 1250000 cents = 12,500.00
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.fullDisplayText, '12,500.00');
      });

      test('should format display with comma separator and thousands', () {
        viewModel.decimalSeparator = DecimalSeparator.comma;

        // Input 1250000 cents = 12.500,00
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.fullDisplayText, '12.500,00');
      });

      test('should format expression parts with thousands separator', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // 12500.00 +
        for (final d in ['1', '2', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');

        expect(viewModel.expression, '12,500.00 +');
      });

      test('should format full expression with thousands separator', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // 12500.00 + 3500.00
        for (final d in ['1', '2', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');
        for (final d in ['3', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }

        expect(viewModel.fullDisplayText, '12,500.00 + 3,500.00');
      });

      test('should evaluate correctly despite display formatting', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // 12500.00 + 3500.00 = 16000.00
        for (final d in ['1', '2', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');
        for (final d in ['3', '5', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }

        when(() => mockHistoryRepository.add(any())).thenAnswer(
          (_) async => HistoryEntry(
            id: 1,
            lines: [HistoryLine(expression: '', result: '')],
            result: '',
            createdAt: DateTime.now(),
          ),
        );
        viewModel.equals();

        expect(viewModel.fullDisplayText, '16,000.00');
      });

      test('should not add thousands separator for small values', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');

        expect(viewModel.fullDisplayText, '1.25');
      });

      test('should format preview result with thousands separator', () {
        viewModel.decimalSeparator = DecimalSeparator.dot;

        // 99999.00 + 1.00 => preview 100,000.00... wait, preview uses evaluator
        // Let's use something simpler: 50000.00 + 50000.00
        for (final d in ['5', '0', '0', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }
        viewModel.setOperator('+');
        for (final d in ['5', '0', '0', '0', '0', '0', '0']) {
          viewModel.inputDigit(d);
        }

        expect(viewModel.previewResult, '100,000.00');
      });
    });

    group('hasContent', () {
      test('should be false in initial state', () {
        expect(viewModel.hasContent, isFalse);
      });

      test('should be true when a digit is entered', () {
        viewModel.inputDigit('5');

        expect(viewModel.hasContent, isTrue);
      });

      test('should be true when operator is pressed after a value', () {
        viewModel.inputDigit('5');
        viewModel.setOperator('+');

        expect(viewModel.hasContent, isTrue);
      });

      test('should be false after clear', () {
        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.clear();

        expect(viewModel.hasContent, isFalse);
      });

      test('should be true after equals (timeline has entries)', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.equals();

        expect(viewModel.hasContent, isTrue);
      });

      test('should be true after opening a parenthesis', () {
        viewModel.inputParenthesis();

        expect(viewModel.hasContent, isTrue);
      });

      test('should notify listeners when content state changes', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.inputDigit('1');

        expect(notified, isTrue);
        expect(viewModel.hasContent, isTrue);
      });
    });

    group('dispose', () {
      test('should dispose without errors', () {
        expect(() => viewModel.dispose(), returnsNormally);
      });
    });
  });
}
