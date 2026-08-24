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
    group('backspace', () {
      test('should remove last digit from current input', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.backspace();

        expect(viewModel.currentDisplayValue, '0.12');
      });

      test(
        'should update preview when deleting digits from second operand',
        () {
          viewModel.inputDigit('1');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');
          viewModel.inputDigit('3');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.backspace();

          // 100.00 + 0.30 preview
          expect(viewModel.previewResult, isNotNull);
        },
      );

      test('should notify listeners on backspace', () {
        viewModel.inputDigit('1');
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.backspace();

        expect(notified, true);
      });

      test('should remove a closing parenthesis without resetting engine', () {
        viewModel.inputParenthesis(); // (
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis(); // ) → committed: ( 12.50 + 3.00 )

        expect(viewModel.fullDisplayText, '( 12.50 + 3.00 )');
        expect(viewModel.openParenCount, 0);

        viewModel.backspace();

        expect(viewModel.fullDisplayText, '( 12.50 + 3.00');
        expect(viewModel.openParenCount, 1);
      });

      test(
        'should remove an opening parenthesis when it is the last token',
        () {
          viewModel.inputParenthesis(); // (

          expect(viewModel.openParenCount, 1);

          viewModel.backspace();

          expect(viewModel.openParenCount, 0);
          expect(viewModel.hasContent, false);
        },
      );

      test('should remove an opening parenthesis preceded by an operator '
          'and restore the previous operand for editing', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputParenthesis(); // (

        expect(viewModel.fullDisplayText, '10.00 + (');

        viewModel.backspace(); // remove (

        expect(viewModel.fullDisplayText, '10.00 +');

        viewModel.backspace(); // remove +

        expect(viewModel.fullDisplayText, '10.00');
        expect(viewModel.currentOperator, isNull);
      });

      test('should not replace opening parenthesis with 0.00 when backspacing '
          'a complex expression', () {
        // 4.25 + (36.00 × 2.00) + 3.65
        viewModel.inputDigit('4');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.setOperator('+');
        viewModel.inputParenthesis();

        viewModel.inputDigit('3');
        viewModel.inputDigit('6');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');

        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();
        viewModel.setOperator('+');

        viewModel.inputDigit('3');
        viewModel.inputDigit('6');
        viewModel.inputDigit('5');

        // Remove 3.65
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();

        // Remove trailing + and then )
        viewModel.backspace();
        viewModel.backspace();

        // Remove 2.00 and operator ×
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();

        // Remove 36.00
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();
        viewModel.backspace();

        expect(viewModel.fullDisplayText, '4.25 + (');

        viewModel.backspace();

        expect(viewModel.fullDisplayText, '4.25 +');
      });

      test('should remove pending operator after closed parenthesis without '
          'adding ghost 0.00', () {
        // (10.00 × 50.00) +
        viewModel.inputParenthesis();
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();
        viewModel.setOperator('+');

        expect(viewModel.fullDisplayText, '( 10.00 × 50.00 ) +');

        viewModel.backspace();

        expect(viewModel.currentOperator, isNull);
        expect(viewModel.fullDisplayText, '( 10.00 × 50.00 )');
      });

      test('should keep closing parenthesis when deleting a trailing operator '
          'in a nested expression', () {
        // (2.50 + 2.56) × 3.00 +
        viewModel.inputParenthesis();
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('6');
        viewModel.inputParenthesis();
        viewModel.setOperator('×');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');

        expect(viewModel.fullDisplayText, '( 2.50 + 2.56 ) × 3.00 +');

        viewModel.backspace();

        expect(viewModel.fullDisplayText, '( 2.50 + 2.56 ) × 3.00');
        expect(viewModel.currentOperator, isNull);
      });

      test(
        'should remove only one closing paren at a time in nested close-close sequence',
        () {
          // (10.00 × 50.00) + 30.00 + (48.00 ÷ (18.00 × 1.50%)) +
          viewModel.inputParenthesis();
          viewModel.inputDigit('1');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('×');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputParenthesis();
          viewModel.setOperator('+');

          viewModel.inputDigit('3');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');

          viewModel.inputParenthesis();
          viewModel.inputDigit('4');
          viewModel.inputDigit('8');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('÷');

          viewModel.inputParenthesis();
          viewModel.inputDigit('1');
          viewModel.inputDigit('8');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('×');
          viewModel.inputDigit('1');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.applyPercentage();
          viewModel.inputParenthesis();
          viewModel.inputParenthesis();
          viewModel.setOperator('+');

          expect(
            viewModel.fullDisplayText,
            '( 10.00 × 50.00 ) + 30.00 + ( 48.00 ÷ ( 18.00 × 1.50% ) ) +',
          );

          viewModel.backspace(); // remove trailing +
          expect(
            viewModel.fullDisplayText,
            '( 10.00 × 50.00 ) + 30.00 + ( 48.00 ÷ ( 18.00 × 1.50% ) )',
          );

          viewModel.backspace(); // remove only the last )
          expect(
            viewModel.fullDisplayText,
            '( 10.00 × 50.00 ) + 30.00 + ( 48.00 ÷ ( 18.00 × 1.50% )',
          );
          expect(viewModel.fullDisplayText.contains('% 0.00'), isFalse);
          expect(viewModel.openParenCount, 1);
        },
      );

      test(
        'should backspace into the inner expression after removing close paren',
        () {
          viewModel.inputParenthesis(); // (
          viewModel.inputDigit('1');
          viewModel.inputDigit('2');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.inputParenthesis(); // ) → ( 12.50 )

          viewModel.backspace(); // remove )
          viewModel.backspace(); // remove last digit of 12.50

          expect(viewModel.fullDisplayText, '( 1.25');
        },
      );

      test('should not leave a dangling operator with 0.00 when engine empties '
          'after restoring an operand from a closed parenthesis', () {
        viewModel.inputParenthesis(); // (
        viewModel.inputDigit('3');
        viewModel.inputDigit('2');
        viewModel.inputDigit('6');
        viewModel.setOperator('−');
        viewModel.inputDigit('0');
        viewModel.inputDigit('4');
        viewModel.inputParenthesis(); // ) → ( 3.26 − 0.04 )

        viewModel.backspace(); // remove )
        viewModel.backspace(); // 0.04 → 0.00 (empty)

        // Display must not include a trailing 0.00 ghost value.
        expect(viewModel.fullDisplayText, '( 3.26 −');
        expect(viewModel.currentOperator, '−');
      });

      test('should promote dangling operator back to pending when deleting '
          'all digits of the right-hand operand', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.setOperator('−'); // commits '+' and '0.05', pending = '−'
        viewModel.inputDigit('2');
        // committed: [1.00, +, 0.05], pendingOp: −, engine: 0.02
        viewModel.backspace(); // 0.02 → 0.00 (empty)

        // After clearing the active operand, we should still display the
        // pending operator without an extra 0.00 token.
        expect(viewModel.fullDisplayText, '1.00 + 0.05 −');
      });
    });

    group('action queue', () {
      test('should process 50 rapid actions without dropping any', () {
        // Arrange — count notifications to verify all actions were processed.
        var notifications = 0;
        viewModel.addListener(() => notifications++);

        // Act — fire 50 actions in burst (digit/operator alternated to avoid
        // Add2Engine integer overflow with a single huge number).
        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
        }

        // Assert — every action triggered a notification (no drops).
        expect(notifications, 50);
      });

      test('should preserve order across mixed actions in burst', () {
        // Arrange
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // Act — simulate user typing "12 + 34 ="
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('4');
        viewModel.equals();

        // Assert — final result must reflect the ordered processing
        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.timelineEntries.first.expression, '0.12 + 0.34');
        expect(viewModel.timelineEntries.first.result, '0.46');
      });

      test(
        'should enqueue actions triggered during processing (reentrancy)',
        () {
          // Arrange — listener that re-dispatches an action while the current
          // one is still being processed (synchronous notifyListeners).
          var fired = false;
          viewModel.addListener(() {
            if (!fired) {
              fired = true;
              viewModel.inputDigit('9');
            }
          });

          // Act
          viewModel.inputDigit('5');

          // Assert — both digits processed in order: '5' then '9'
          expect(viewModel.currentDisplayValue, '0.59');
        },
      );

      test(
        'should not drop actions when 50 operators+digits fire in burst',
        () {
          // Arrange
          when(
            () => mockHistoryRepository.add(any()),
          ).thenAnswer((_) async => HistoryFixtures.entry1);

          // Act — 1 + 1 + 1 + ... 25 times => result should be 0.25
          for (var i = 0; i < 25; i++) {
            viewModel.inputDigit('1');
            if (i < 24) viewModel.setOperator('+');
          }
          viewModel.equals();

          // Assert — exactly one timeline entry; sum is 25 * 0.01 = 0.25
          expect(viewModel.timelineEntries, hasLength(1));
          expect(viewModel.timelineEntries.first.result, '0.25');
        },
      );
    });
  });
}
