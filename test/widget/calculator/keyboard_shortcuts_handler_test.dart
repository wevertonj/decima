import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:wevacalc/domain/entities/history_entry.dart';
import 'package:wevacalc/domain/entities/history_line.dart';
import 'package:wevacalc/domain/enums/decimal_separator.dart';
import 'package:wevacalc/ui/calculator/calculator_page.dart';
import 'package:wevacalc/ui/calculator/calculator_view_model.dart';
import 'package:wevacalc/ui/calculator/widgets/animated_input_display.dart';
import 'package:wevacalc/ui/calculator/widgets/calculator_keypad.dart';
import 'package:wevacalc/ui/calculator/widgets/keyboard_shortcuts_handler.dart';
import 'package:wevacalc/utils/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';
import '../../mocks/mock_clipboard_service.dart';
import '../../mocks/mock_history_repository.dart';
import '../../mocks/mock_settings_repository.dart';

void main() {
  late MockHistoryRepository mockHistoryRepository;
  late MockSettingsRepository mockSettingsRepository;
  late MockClipboardService mockClipboardService;
  late CalculatorViewModel viewModel;

  setUpAll(() {
    registerFallbackValue(
      HistoryEntry(
        lines: [HistoryLine(expression: '', result: '')],
        result: '',
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(DecimalSeparator.dot);
  });

  setUp(() {
    mockHistoryRepository = MockHistoryRepository();
    mockSettingsRepository = MockSettingsRepository();
    mockClipboardService = MockClipboardService();
    when(() => mockHistoryRepository.add(any())).thenAnswer(
      (_) async => HistoryEntry(
        id: 1,
        lines: [HistoryLine(expression: '', result: '')],
        result: '',
        createdAt: DateTime.now(),
      ),
    );
    when(() => mockHistoryRepository.update(any())).thenAnswer((_) async {});
    when(
      () => mockSettingsRepository.getDecimalSeparator(),
    ).thenAnswer((_) async => DecimalSeparator.dot);
    when(() => mockClipboardService.copyText(any())).thenAnswer((_) async {});
    when(() => mockClipboardService.readText()).thenAnswer((_) async => null);
    viewModel = CalculatorViewModel(
      historyRepository: mockHistoryRepository,
      settingsRepository: mockSettingsRepository,
      clipboardService: mockClipboardService,
    );
  });

  String displayText(WidgetTester tester) {
    return tester
        .widget<AnimatedInputDisplay>(find.byType(AnimatedInputDisplay))
        .text;
  }

  int? displayCursor(WidgetTester tester) {
    return tester
        .widget<AnimatedInputDisplay>(find.byType(AnimatedInputDisplay))
        .cursorPosition;
  }

  Finder keypadLabel(String label) {
    return find.descendant(
      of: find.byType(CalculatorKeypad),
      matching: find.text(label),
    );
  }

  Future<void> sendKeys(
    WidgetTester tester,
    List<LogicalKeyboardKey> keys,
  ) async {
    for (final key in keys) {
      await tester.sendKeyEvent(key);
    }
    await tester.pumpAndSettle();
  }

  Future<void> sendChar(
    WidgetTester tester,
    LogicalKeyboardKey key,
    String character,
  ) async {
    await tester.sendKeyEvent(key, character: character);
    await tester.pumpAndSettle();
  }

  Future<AppLocalizations> loadL10n() {
    return AppLocalizations.delegate.load(const Locale('en'));
  }

  group('KeyboardShortcutsHandler', () {
    group('digits', () {
      testWidgets('should type digits into the display', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit0,
        ]);

        expect(displayText(tester), equals('12.50'));
      });

      testWidgets('should type numpad digits into the display', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.numpad7,
          LogicalKeyboardKey.numpad5,
        ]);

        expect(displayText(tester), equals('0.75'));
      });

      testWidgets('should not drop keys typed in a burst', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
        await tester.pumpAndSettle();

        expect(displayText(tester), equals('98.76'));
      });
    });

    group('operators', () {
      testWidgets('should append the plus operator', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [LogicalKeyboardKey.digit5]);
        await sendChar(tester, LogicalKeyboardKey.equal, '+');

        expect(displayText(tester), equals('0.05 +'));
      });

      testWidgets('should append the minus operator', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [LogicalKeyboardKey.digit5]);
        await sendChar(tester, LogicalKeyboardKey.minus, '-');

        expect(displayText(tester), equals('0.05 −'));
      });

      testWidgets('should append the multiply operator from the x key', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [LogicalKeyboardKey.digit5]);
        await sendChar(tester, LogicalKeyboardKey.keyX, 'x');

        expect(displayText(tester), equals('0.05 ×'));
      });

      testWidgets('should append the divide operator', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [LogicalKeyboardKey.digit5]);
        await sendChar(tester, LogicalKeyboardKey.slash, '/');

        expect(displayText(tester), equals('0.05 ÷'));
      });
    });

    group('equals', () {
      testWidgets('should evaluate the expression with Enter', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendChar(tester, LogicalKeyboardKey.equal, '+');
        await sendKeys(tester, [
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendKeys(tester, [LogicalKeyboardKey.enter]);

        expect(displayText(tester), equals('6.00'));
      });

      testWidgets('should evaluate the expression with the equal key', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendChar(tester, LogicalKeyboardKey.digit8, '*');
        await sendKeys(tester, [
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendKeys(tester, [LogicalKeyboardKey.equal]);

        expect(displayText(tester), equals('6.00'));
      });
    });

    group('deleting', () {
      testWidgets('should delete the last digit with Backspace', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit7,
        ]);
        expect(displayText(tester), equals('0.57'));

        await sendKeys(tester, [LogicalKeyboardKey.backspace]);

        expect(displayText(tester), equals('0.05'));
      });

      testWidgets('should not break when Backspace is pressed while empty', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.backspace,
          LogicalKeyboardKey.backspace,
        ]);

        expect(tester.takeException(), isNull);
        expect(displayText(tester), equals('0.00'));
      });

      testWidgets('should clear everything with Escape', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit0,
        ]);
        await sendKeys(tester, [LogicalKeyboardKey.escape]);

        expect(displayText(tester), equals('0.00'));
      });

      testWidgets('should clear everything with Delete', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit0,
        ]);
        await sendKeys(tester, [LogicalKeyboardKey.delete]);

        expect(displayText(tester), equals('0.00'));
      });
    });

    group('percentage and parentheses', () {
      testWidgets('should append a literal percent sign', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendChar(tester, LogicalKeyboardKey.equal, '+');
        await sendKeys(tester, [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit0,
        ]);
        await sendChar(tester, LogicalKeyboardKey.digit5, '%');

        expect(displayText(tester), equals('1.00 + 0.10%'));
      });

      testWidgets('should evaluate a parenthesized expression', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendChar(tester, LogicalKeyboardKey.digit9, '(');
        await sendKeys(tester, [
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendChar(tester, LogicalKeyboardKey.equal, '+');
        await sendKeys(tester, [
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendChar(tester, LogicalKeyboardKey.digit0, ')');
        await sendChar(tester, LogicalKeyboardKey.digit8, '*');
        await sendKeys(tester, [
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendKeys(tester, [LogicalKeyboardKey.enter]);

        expect(displayText(tester), equals('16.00'));
      });
    });

    group('decimal separator keys', () {
      testWidgets('should map the period key to the double zero shortcut', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [LogicalKeyboardKey.digit1]);
        await sendChar(tester, LogicalKeyboardKey.period, '.');

        expect(displayText(tester), equals('1.00'));
      });

      testWidgets('should map the comma key to the double zero shortcut', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [LogicalKeyboardKey.digit1]);
        await sendChar(tester, LogicalKeyboardKey.comma, ',');

        expect(displayText(tester), equals('1.00'));
      });
    });

    group('cursor movement', () {
      testWidgets('should move the cursor with the arrow keys', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit0,
        ]);
        expect(displayCursor(tester), isNull);

        await sendKeys(tester, [LogicalKeyboardKey.arrowLeft]);
        expect(displayCursor(tester), equals(4));

        await sendKeys(tester, [LogicalKeyboardKey.arrowLeft]);
        expect(displayCursor(tester), equals(3));

        await sendKeys(tester, [LogicalKeyboardKey.arrowRight]);
        expect(displayCursor(tester), equals(4));

        await sendKeys(tester, [LogicalKeyboardKey.arrowRight]);
        expect(displayCursor(tester), isNull);
      });

      testWidgets('should edit the expression at the cursor position', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await sendKeys(tester, [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit0,
        ]);
        await sendKeys(tester, [
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.digit9,
        ]);

        expect(displayText(tester), equals('129.50'));
      });
    });

    group('clipboard', () {
      testWidgets('should copy the current result with Ctrl+C', (tester) async {
        await tester.pumpApp(
          Scaffold(body: CalculatorPage(viewModel: viewModel)),
        );

        await sendKeys(tester, [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);
        await sendChar(tester, LogicalKeyboardKey.equal, '+');
        await sendKeys(tester, [
          LogicalKeyboardKey.digit5,
          LogicalKeyboardKey.digit0,
          LogicalKeyboardKey.digit0,
        ]);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        verify(() => mockClipboardService.copyText('6.00')).called(1);

        final l10n = await loadL10n();
        expect(find.text(l10n.copied), findsOneWidget);
      });

      testWidgets('should paste valid clipboard content with Ctrl+V', (
        tester,
      ) async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '1250');

        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(displayText(tester), equals('1,250.00'));
      });

      testWidgets('should show a snackbar when pasted content is invalid', (
        tester,
      ) async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => 'not a number');

        await tester.pumpApp(
          Scaffold(body: CalculatorPage(viewModel: viewModel)),
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pumpAndSettle();

        final l10n = await loadL10n();
        expect(find.text(l10n.pasteInvalid), findsOneWidget);
      });
    });

    group('visual feedback', () {
      testWidgets('should glow the matching keypad button on a key press', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        TextStyle styleOf(String label) =>
            tester.widget<Text>(keypadLabel(label)).style!;

        expect(styleOf('5').shadows, isNull);

        await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
        await tester.pump();

        expect(styleOf('5').shadows, isNotNull);
        expect(styleOf('7').shadows, isNull);

        await tester.pumpAndSettle();

        expect(styleOf('5').shadows, isNull);
      });

      testWidgets('should glow the operator button on an operator key press', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await tester.sendKeyEvent(LogicalKeyboardKey.minus, character: '-');
        await tester.pump();

        final style = tester.widget<Text>(keypadLabel('−')).style!;

        expect(style.shadows, isNotNull);
      });
    });

    group('text field focus', () {
      testWidgets('should ignore shortcuts while a text field has focus', (
        tester,
      ) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpApp(
          KeyboardShortcutsHandler(
            viewModel: viewModel,
            child: Scaffold(body: TextField(controller: controller)),
          ),
        );

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
        await tester.pumpAndSettle();

        expect(viewModel.fullDisplayText, equals('0.00'));
      });

      testWidgets('should dispatch shortcuts when no text field has focus', (
        tester,
      ) async {
        await tester.pumpApp(
          KeyboardShortcutsHandler(
            viewModel: viewModel,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
        await tester.pumpAndSettle();

        expect(viewModel.fullDisplayText, equals('0.05'));
      });
    });
  });
}
