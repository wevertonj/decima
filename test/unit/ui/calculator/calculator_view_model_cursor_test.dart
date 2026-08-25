import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
    group('cursor', () {
      test('should default cursorPosition to length of fullDisplayText', () {
        expect(viewModel.cursorPosition, viewModel.fullDisplayText.length);
      });

      test('cursorPosition follows the end as text grows', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        // "12.50"
        expect(viewModel.cursorPosition, 5);
      });

      test('moveCursorLeft decrements position', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        // "12.50", cursor em 5
        viewModel.moveCursorLeft();
        expect(viewModel.cursorPosition, 4);
      });

      test('moveCursorLeft at 0 is a no-op', () {
        viewModel.setCursorPosition(0);
        viewModel.moveCursorLeft();
        expect(viewModel.cursorPosition, 0);
      });

      test('moveCursorRight increments position', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setCursorPosition(2);
        viewModel.moveCursorRight();
        expect(viewModel.cursorPosition, 3);
      });

      test('moveCursorRight at end is a no-op', () {
        viewModel.inputDigit('5');
        viewModel.moveCursorRight();
        expect(viewModel.cursorPosition, viewModel.fullDisplayText.length);
      });

      test('setCursorPosition clamps within bounds', () {
        viewModel.inputDigit('1');
        viewModel.setCursorPosition(99);
        expect(viewModel.cursorPosition, viewModel.fullDisplayText.length);
        viewModel.setCursorPosition(-5);
        expect(viewModel.cursorPosition, 0);
      });

      test('clear resets cursor to end (which becomes 0.00 length=4)', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.setCursorPosition(2);
        viewModel.clear();
        expect(viewModel.cursorPosition, viewModel.fullDisplayText.length);
      });

      test('equals resets cursor to end', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setCursorPosition(3);
        viewModel.equals();
        expect(viewModel.cursorPosition, viewModel.fullDisplayText.length);
      });

      test('moveCursorLeft notifies listeners', () {
        viewModel.inputDigit('1');
        var notified = false;
        viewModel.addListener(() => notified = true);
        viewModel.moveCursorLeft();
        expect(notified, true);
      });

      test('previewResult returns null for trailing operator (no crash)', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        // "10.00 + 5.00"; entra em modo de edição no início e chama
        // setOperator ali para produzir um cenário de operador solto.
        viewModel.setCursorPosition(0);
        // cursor em 0 em '10.00 + 5.00' -> setOperator insere ' + ' literal
        // -> ' + 10.00 + 5.00', que começa com espaço + operador e NÃO
        // pode quebrar previewResult.
        viewModel.setOperator('+');
        expect(viewModel.previewResult, isNull);
      });

      test('= evaluates the edited expression with Add2-formatted values', () {
        viewModel.inputDigit('2');
        viewModel.inputDigit('3');
        viewModel.inputDigit('7');
        // "2.37"
        viewModel.setCursorPosition(4); // no fim
        viewModel.moveCursorLeft(); // entra em modo de edição na pos 3
        viewModel.inputDigit('1');
        // bruto '237' com digitsAfter=1, inserir '1' -> '23.17'.
        expect(viewModel.fullDisplayText, '23.17');
        // Move o cursor para o fim do bloco antes de adicionar ' + ',
        // para digitsAfter=0 e o operador ser anexado literalmente.
        viewModel.setCursorPosition(5);
        viewModel.setOperator('+');
        // ' + ' anexado literal, pois o cursor está na borda direita do bloco.
        // Um '1' novo então inicia o bloco da direita: bruto '1' -> '0.01'.
        viewModel.inputDigit('1');
        expect(viewModel.fullDisplayText, '23.17 + 0.01');
        viewModel.equals();
        expect(viewModel.timelineEntries.last.result, '23.18');
      });

      test(
        'cursor stays anchored to trailing digits across delete + insert',
        () {
          // Reproduz o cenário reportado pelo usuário:
          // Começa com '2.00', cursor entre os dois zeros (pos 3).
          // Backspace -> '0.20', cursor deve ficar na pos 3 ('0.2|0').
          // Digita '3' -> '2.30', cursor deve ficar na pos 3 ('2.3|0').
          // Digita '4' -> '23.40', cursor deve ficar na pos 4 ('23.4|0').
          viewModel.inputDigit('2');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          // "2.00"
          viewModel.setCursorPosition(3); // entre os dois zeros

          viewModel.backspace();
          expect(viewModel.fullDisplayText, '0.20');
          expect(viewModel.cursorPosition, 3);

          viewModel.inputDigit('3');
          expect(viewModel.fullDisplayText, '2.30');
          expect(viewModel.cursorPosition, 3);

          viewModel.inputDigit('4');
          expect(viewModel.fullDisplayText, '23.40');
          expect(viewModel.cursorPosition, 4);
        },
      );

      test('previewResult evaluates edited expression', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        // "10.00 + 5.00" = 15.00
        expect(viewModel.previewResult, '15.00');
        // Move o cursor para a posição 2 (entre '0' e '.') no primeiro número
        viewModel.setCursorPosition(2);
        viewModel.inputDigit('0');
        // '0' inserido dentro de "10.00" → "100.00 + 5.00"
        expect(viewModel.fullDisplayText, '100.00 + 5.00');
        expect(viewModel.previewResult, '105.00');
      });
    });
  });
}
