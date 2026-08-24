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
        // "12.50", cursor at 5
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
        // "10.00 + 5.00"; enter edit mode at the start, then setOperator
        // there to produce a trailing/dangling operator scenario.
        viewModel.setCursorPosition(0);
        // cursor at 0 in '10.00 + 5.00' -> setOperator literal-inserts ' + '
        // -> ' + 10.00 + 5.00' which starts with a space + operator and
        // must NOT crash previewResult.
        viewModel.setOperator('+');
        expect(viewModel.previewResult, isNull);
      });

      test('= evaluates the edited expression with Add2-formatted values', () {
        viewModel.inputDigit('2');
        viewModel.inputDigit('3');
        viewModel.inputDigit('7');
        // "2.37"
        viewModel.setCursorPosition(4); // at-end
        viewModel.moveCursorLeft(); // enter edit mode at pos 3
        viewModel.inputDigit('1');
        // raw '237' digitsAfter=1, insert '1' -> '23.17'.
        expect(viewModel.fullDisplayText, '23.17');
        // Move cursor to the very end of the block before adding ' + '
        // so digitsAfter=0 and the operator is appended literally.
        viewModel.setCursorPosition(5);
        viewModel.setOperator('+');
        // ' + ' literal-append since cursor is at the block's right edge.
        // Then a fresh '1' starts a new right-hand block: raw '1' -> '0.01'.
        viewModel.inputDigit('1');
        expect(viewModel.fullDisplayText, '23.17 + 0.01');
        viewModel.equals();
        expect(viewModel.timelineEntries.last.result, '23.18');
      });

      test(
        'cursor stays anchored to trailing digits across delete + insert',
        () {
          // Reproduces the user-reported scenario:
          // Start with '2.00', cursor between the two zeros (pos 3).
          // Backspace -> '0.20', cursor must stay at pos 3 ('0.2|0').
          // Type '3' -> '2.30', cursor must stay at pos 3 ('2.3|0').
          // Type '4' -> '23.40', cursor must stay at pos 4 ('23.4|0').
          viewModel.inputDigit('2');
          viewModel.inputDigit('0');
          viewModel.inputDigit('0');
          // "2.00"
          viewModel.setCursorPosition(3); // between the two zeros

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
        // Move cursor to position 2 (between '0' and '.') in first number
        viewModel.setCursorPosition(2);
        viewModel.inputDigit('0');
        // Inserted '0' inside "10.00" → "100.00 + 5.00"
        expect(viewModel.fullDisplayText, '100.00 + 5.00');
        expect(viewModel.previewResult, '105.00');
      });
    });
  });
}
