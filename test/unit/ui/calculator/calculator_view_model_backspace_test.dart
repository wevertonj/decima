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

          // preview de 100.00 + 0.30
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
        viewModel.inputParenthesis(); // ) → consolidado: ( 12.50 + 3.00 )

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

        // Remove o + final e depois o )
        viewModel.backspace();
        viewModel.backspace();

        // Remove 2.00 e o operador ×
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

          viewModel.backspace(); // remove o + final
          expect(
            viewModel.fullDisplayText,
            '( 10.00 × 50.00 ) + 30.00 + ( 48.00 ÷ ( 18.00 × 1.50% ) )',
          );

          viewModel.backspace(); // remove apenas o último )
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
          viewModel.backspace(); // remove o último dígito de 12.50

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
        viewModel.backspace(); // 0.04 → 0.00 (vazio)

        // O display não deve incluir um 0.00 fantasma no final.
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
        viewModel.setOperator('−'); // consolida '+' e '0.05', pendente = '−'
        viewModel.inputDigit('2');
        // consolidados: [1.00, +, 0.05], pendingOp: −, engine: 0.02
        viewModel.backspace(); // 0.02 → 0.00 (vazio)

        // Após limpar o operando ativo, o operador pendente ainda deve
        // aparecer sem um token 0.00 extra.
        expect(viewModel.fullDisplayText, '1.00 + 0.05 −');
      });
    });

    group('action queue', () {
      test('should process 50 rapid actions without dropping any', () {
        // Arrange — conta as notificações para verificar que nenhuma ação se perdeu.
        var notifications = 0;
        viewModel.addListener(() => notifications++);

        // Act — dispara 50 ações em burst (dígito/operador alternados para
        // evitar overflow de inteiro no Add2Engine com um único número enorme).
        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          viewModel.setOperator('+');
        }

        // Assert — cada ação disparou uma notificação (nenhuma descartada).
        expect(notifications, 50);
      });

      test('should preserve order across mixed actions in burst', () {
        // Arrange
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // Act — simula o usuário digitando "12 + 34 ="
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.setOperator('+');
        viewModel.inputDigit('3');
        viewModel.inputDigit('4');
        viewModel.equals();

        // Assert — o resultado final deve refletir o processamento em ordem
        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.timelineEntries.first.expression, '0.12 + 0.34');
        expect(viewModel.timelineEntries.first.result, '0.46');
      });

      test(
        'should enqueue actions triggered during processing (reentrancy)',
        () {
          // Arrange — listener que redespacha uma ação enquanto a atual
          // ainda está sendo processada (notifyListeners síncrono).
          var fired = false;
          viewModel.addListener(() {
            if (!fired) {
              fired = true;
              viewModel.inputDigit('9');
            }
          });

          // Act
          viewModel.inputDigit('5');

          // Assert — os dois dígitos processados em ordem: '5' depois '9'
          expect(viewModel.currentDisplayValue, '0.59');
        },
      );

      test('should not drop actions when 50 operators+digits fire in burst', () {
        // Arrange
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => HistoryFixtures.entry1);

        // Act — 1 + 1 + 1 + ... 25 vezes => resultado deve ser 0.25
        for (var i = 0; i < 25; i++) {
          viewModel.inputDigit('1');
          if (i < 24) viewModel.setOperator('+');
        }
        viewModel.equals();

        // Assert — exatamente uma entrada na timeline; a soma é 25 * 0.01 = 0.25
        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.timelineEntries.first.result, '0.25');
      });
    });
  });
}
