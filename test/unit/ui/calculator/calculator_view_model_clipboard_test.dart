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
    group('clipboard — derived state', () {
      test('hasExpression should be false on initial state', () {
        expect(viewModel.hasExpression, isFalse);
      });

      test('hasExpression should be true after inputting digits', () {
        viewModel.inputDigit('5');

        expect(viewModel.hasExpression, isTrue);
      });

      test('hasResult should be false on initial state', () {
        expect(viewModel.hasResult, isFalse);
      });

      test('hasResult should be true when previewResult is available', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        expect(viewModel.previewResult, isNotNull);
        expect(viewModel.hasResult, isTrue);
      });

      test('hasResult should be true after equals', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.hasResult, isTrue);
      });

      test('hasHistory should be false on initial state', () {
        expect(viewModel.hasHistory, isFalse);
      });

      test('hasHistory should be true after a calculation is committed', () {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.equals();

        expect(viewModel.hasHistory, isTrue);
      });
    });

    group('copyExpression', () {
      test('should copy current expression text to clipboard', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('2');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');

        await viewModel.copyExpression();

        verify(() => mockClipboardService.copyText('12.50')).called(1);
      });

      test('should copy expression including operator and operand', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        await viewModel.copyExpression();

        verify(() => mockClipboardService.copyText('10.00 + 10.00')).called(1);
      });
    });

    group('copyResult', () {
      test('should copy preview result when available', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');

        await viewModel.copyResult();

        verify(() => mockClipboardService.copyText('15.00')).called(1);
      });

      test('should copy current display value after equals', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        await viewModel.copyResult();

        verify(() => mockClipboardService.copyText('15.00')).called(1);
      });
    });

    group('copyHistory', () {
      test('should copy all timeline entries as text', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.equals();
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('×');
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        await viewModel.copyHistory();

        final captured =
            verify(
                  () => mockClipboardService.copyText(captureAny()),
                ).captured.single
                as String;

        expect(captured, contains('1.00 + 0.50 = 1.50'));
        expect(captured, contains('2.00 × 2.00 = 4.00'));
      });
    });

    group('pasteFromClipboard', () {
      test('should paste integer at face value', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '1250');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.currentDisplayValue, '1,250.00');
      });

      test(
        'should paste decimal with dot separator preserving precision',
        () async {
          when(
            () => mockClipboardService.readText(),
          ).thenAnswer((_) async => '12.50');

          final ok = await viewModel.pasteFromClipboard();

          expect(ok, isTrue);
          expect(viewModel.currentDisplayValue, '12.50');
        },
      );

      test('should paste decimal with comma separator', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '12,50');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.currentDisplayValue, '12.50');
      });

      test('should paste full expression and evaluate previewResult', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '10 + 5');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.expression, equals('10.00 +'));
        expect(viewModel.currentDisplayValue, '5.00');
        expect(viewModel.previewResult, '15.00');
      });

      test('should return false when clipboard is empty', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => null);

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should return false for invalid input', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => 'not a number');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should replace existing content', () async {
        viewModel.inputDigit('9');
        viewModel.inputDigit('9');
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '1250');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.currentDisplayValue, '1,250.00');
      });
    });

    group('pasteFromClipboard — resolved lines', () {
      void clipboard(String text) {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => text);
      }

      test('should move a resolved line into the timeline', () async {
        clipboard('10 + 5 = 15');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.timelineEntries.first.expression, '10.00 + 5.00');
        expect(viewModel.timelineEntries.first.result, '15.00');
      });

      test('should leave the result as the current input', () async {
        clipboard('10 + 5 = 15');

        await viewModel.pasteFromClipboard();

        expect(viewModel.fullDisplayText, '15.00');
        expect(viewModel.currentDisplayValue, '15.00');
      });

      test(
        'should start a fresh number when typing after a resolved line',
        () async {
          clipboard('10 + 5 = 15');

          await viewModel.pasteFromClipboard();
          viewModel.inputDigit('7');

          expect(viewModel.currentDisplayValue, '0.07');
        },
      );

      test(
        'should recalculate instead of trusting the pasted result',
        () async {
          clipboard('10 + 5 = 99');

          final ok = await viewModel.pasteFromClipboard();

          expect(ok, isTrue);
          expect(viewModel.timelineEntries.first.result, '15.00');
          expect(viewModel.currentDisplayValue, '15.00');
        },
      );

      test('should accept several resolved lines', () async {
        clipboard('10 + 5 = 15\n20 × 2 = 40');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.timelineEntries, hasLength(2));
        expect(viewModel.timelineEntries[0].result, '15.00');
        expect(viewModel.timelineEntries[1].result, '40.00');
        expect(viewModel.currentDisplayValue, '40.00');
      });

      test('should accept resolved lines followed by an open input', () async {
        clipboard('10 + 5 = 15\n7 + 3');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.timelineEntries, hasLength(1));
        expect(viewModel.fullDisplayText, '7.00 + 3.00');
        expect(viewModel.previewResult, '10.00');
      });

      test('should round-trip the text produced by copyHistory', () async {
        viewModel.inputDigit('1');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();
        viewModel.setOperator('×');
        viewModel.inputDigit('2');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        await viewModel.copyHistory();
        final copied =
            verify(
                  () => mockClipboardService.copyText(captureAny()),
                ).captured.last
                as String;

        viewModel.clear();
        clipboard(copied);
        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.timelineEntries, hasLength(2));
        expect(viewModel.timelineEntries[0].result, '15.00');
        expect(viewModel.timelineEntries[1].result, '30.00');
        expect(viewModel.currentDisplayValue, '30.00');
      });

      test('should handle thousands separators in a resolved line', () async {
        clipboard('1,000.00 + 250.50 = 1,250.50');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.timelineEntries.first.expression, '1,000.00 + 250.50');
        expect(viewModel.timelineEntries.first.result, '1,250.50');
      });

      test('should persist pasted lines on the next equals', () async {
        clipboard('10 + 5 = 15');
        await viewModel.pasteFromClipboard();

        viewModel.setOperator('+');
        viewModel.inputDigit('5');
        viewModel.inputDigit('0');
        viewModel.inputDigit('0');
        viewModel.equals();

        final captured =
            verify(() => mockHistoryRepository.add(captureAny())).captured.last
                as HistoryEntry;

        expect(captured.lines, hasLength(2));
        expect(captured.lines[0].result, '15.00');
        expect(captured.lines[1].result, '20.00');
      });

      test('should reject an equals sign with no result', () async {
        clipboard('10 + 5 =');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
        expect(viewModel.timelineEntries, isEmpty);
        expect(viewModel.currentDisplayValue, '0.00');
      });

      test('should reject an open line before a resolved one', () async {
        clipboard('7 + 3\n10 + 5 = 15');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
        expect(viewModel.timelineEntries, isEmpty);
      });

      test('should reject more than one equals sign in a line', () async {
        clipboard('10 + 5 = 15 = 15');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
      });

      test('should reject an invalid expression before the equals', () async {
        clipboard('10 ++ 5 = 15');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
      });

      test('should reject an expression as the result', () async {
        clipboard('10 + 5 = 3 × 5');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
      });

      test('should reject a resolved line without an operator', () async {
        clipboard('10 = 5');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
        expect(viewModel.timelineEntries, isEmpty);
      });

      test('should reject a division by zero line', () async {
        clipboard('10 ÷ 0 = Error');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isFalse);
      });

      test('should ignore blank lines between resolved lines', () async {
        clipboard('10 + 5 = 15\n\n20 × 2 = 40\n');

        final ok = await viewModel.pasteFromClipboard();

        expect(ok, isTrue);
        expect(viewModel.timelineEntries, hasLength(2));
      });
    });
  });
}
