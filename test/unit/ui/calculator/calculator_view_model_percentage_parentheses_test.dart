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
    group('percentage', () {
      test(
        'should display literal % in expression for addition without changing current value',
        () {
          // 100.00 + 10% → display mostra 100.00 + 10.00%, valor segue 10.00
          viewModel.inputDigit('1');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');
          viewModel.inputDigit('1');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.applyPercentage();

          expect(viewModel.currentDisplayValue, '10.00');
          expect(viewModel.fullDisplayText, '100.00 + 10.00%');
          expect(viewModel.previewResult, '110.00');
        },
      );

      test(
        'should display literal % in expression for multiplication without changing current value',
        () {
          // 200.00 × 50% → display mostra 200.00 × 50.00%, valor segue 50.00
          viewModel.inputDigit('2');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('×');
          viewModel.inputDigit('5');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.applyPercentage();

          expect(viewModel.currentDisplayValue, '50.00');
          expect(viewModel.fullDisplayText, '200.00 × 50.00%');
          expect(viewModel.previewResult, '100.00');
        },
      );

      test('should display literal % for subtraction', () {
        // 200.00 − 25% = 150.00
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('−');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();

        expect(viewModel.fullDisplayText, '200.00 − 25.00%');
        expect(viewModel.previewResult, '150.00');
      });

      test('should display literal % for division', () {
        // 200.00 ÷ 10% = 2000.00
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('÷');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();

        expect(viewModel.fullDisplayText, '200.00 ÷ 10.00%');
        expect(viewModel.previewResult, '2,000.00');
      });

      test('should not apply percentage without operator', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();

        // Deve permanecer inalterado
        expect(viewModel.currentDisplayValue, '10.00');
        expect(viewModel.fullDisplayText, '10.00');
      });

      test(
        'should preserve % literal in timeline entry expression after equals',
        () {
          when(
            () => mockHistoryRepository.add(any()),
          ).thenAnswer((_) async => HistoryFixtures.entry1);

          viewModel.inputDigit('1');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');
          viewModel.inputDigit('1');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.applyPercentage();
          viewModel.equals();

          expect(viewModel.timelineEntries, hasLength(1));
          expect(viewModel.timelineEntries.first.expression, '100.00 + 10.00%');
          expect(viewModel.timelineEntries.first.result, '110.00');
        },
      );

      test('should persist literal % expression to history repository', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();
        viewModel.equals();
        viewModel.clear();

        final captured = verify(
          () => mockHistoryRepository.add(captureAny()),
        ).captured;
        final entry = captured.single as HistoryEntry;
        expect(entry.lines.first.expression, contains('%'));
      });

      test('should preserve % literal when chaining with another operator', () {
        // 100 + 10% + 5 → a expressão deve manter "100.00 + 10.00% +"
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.applyPercentage();
        viewModel.setOperator('+');

        expect(viewModel.expression, '100.00 + 10.00% +');
      });
    });

    group('parentheses', () {
      test('should have openParenCount 0 initially', () {
        expect(viewModel.openParenCount, 0);
      });

      test('should open parenthesis at start of expression', () {
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 1);
        expect(viewModel.expression, '(');
      });

      test('should accept digits inside parentheses', () {
        viewModel.inputParenthesis();
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.currentDisplayValue, '5.00');
        expect(viewModel.fullDisplayText, '( 5.00');
      });

      test('should close parenthesis when balanced and last is value', () {
        viewModel.inputParenthesis();
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 0);
        expect(viewModel.expression, '( 5.00 + 3.00 )');
      });

      test('should evaluate parenthesized expression on equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // (5.00 + 3.00) × 2.00 = 16.00
        viewModel.inputParenthesis();
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();
        viewModel.setOperator('×');
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.timelineEntries.first.result, '16.00');
      });

      test('should support nested parentheses', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // (10.00 × (2.00 + 3.00)) = 50.00
        viewModel.inputParenthesis();
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 2);

        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 0);
        viewModel.equals();

        expect(viewModel.timelineEntries.first.result, '50.00');
      });

      test('should auto-close unbalanced parentheses on equals', () {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // ( 5.00 + 3.00  → equals deve autofechar → 8.00
        viewModel.inputParenthesis();
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.timelineEntries.first.result, '8.00');
      });

      test('should open parenthesis after operator', () {
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 1);
        expect(viewModel.expression, '5.00 + (');
      });

      test('should not open parenthesis after a value (without operator)', () {
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputParenthesis();

        // Deve ser ignorado — sem multiplicação implícita
        expect(viewModel.openParenCount, 0);
        expect(viewModel.expression, '');
      });

      test(
        'should support continuing operations after closing parenthesis',
        () {
          when(
            () => mockHistoryRepository.add(any()),
          ).thenAnswer((_) async => HistoryFixtures.entry1);

          // (2.00 + 3.00) × 4.00 = 20.00
          viewModel.inputParenthesis();
          viewModel.inputDigit('2');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.setOperator('+');
          viewModel.inputDigit('3');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.inputParenthesis();
          viewModel.setOperator('×');
          viewModel.inputDigit('4');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          viewModel.equals();

          expect(viewModel.timelineEntries.first.result, '20.00');
        },
      );

      test('should preserve open paren expression in fullDisplayText', () {
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputParenthesis();
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.fullDisplayText, '5.00 + ( 2.00');
      });

      test('should notify listeners when parenthesis is inserted', () {
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.inputParenthesis();

        expect(notified, isTrue);
      });
    });

    group('parentheses in edit mode', () {
      /// Digita `1250` (→ `12.50`) e deixa o cursor no meio do número.
      void typeAndEditMidNumber(int cursorPosition) {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setCursorPosition(cursorPosition);
      }

      test('openParenCount should reflect the text being edited', () {
        typeAndEditMidNumber(2);

        expect(viewModel.openParenCount, 0);

        viewModel.inputParenthesis();

        expect(viewModel.openParenCount, 1);
      });

      test('should keep the expression evaluable after opening', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setCursorPosition(10);
        viewModel.inputParenthesis();
        viewModel.moveCursorToEnd();
        viewModel.inputParenthesis();

        expect(viewModel.fullDisplayText, '10.00 + ( 5.00 )');
        expect(viewModel.previewResult, '15.00');
      });

      test('equals should auto-close open parentheses in edit mode', () {
        typeAndEditMidNumber(2);
        viewModel.inputParenthesis();
        viewModel.moveCursorToEnd();
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.timelineEntries.first.result, '15.50');
        expect(viewModel.currentDisplayValue, '15.50');
      });
    });
  });
}
