import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/ui/calculator/calculator_page.dart';
import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:decima/ui/calculator/widgets/animated_input_display.dart';
import 'package:decima/ui/calculator/widgets/calculator_button.dart';
import 'package:decima/ui/calculator/widgets/calculator_keypad.dart';
import 'package:decima/ui/calculator/widgets/timeline_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  group('CalculatorPage', () {
    /// Helper to get the current display text from AnimatedInputDisplay
    String getDisplayText(WidgetTester tester) {
      final display = tester.widget<AnimatedInputDisplay>(
        find.byType(AnimatedInputDisplay),
      );

      return display.text;
    }

    group('rendering', () {
      testWidgets('should display timeline and keypad', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        expect(find.byType(TimelineDisplay), findsOneWidget);
        expect(find.byType(CalculatorKeypad), findsOneWidget);
      });

      testWidgets('should display initial value 0.00', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        expect(getDisplayText(tester), equals('0.00'));
      });

      testWidgets('should display history and settings icons', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        expect(find.byIcon(Icons.history_rounded), findsOneWidget);
        expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      });

      testWidgets('should display backspace icon in icon bar', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        expect(find.byIcon(Icons.backspace_rounded), findsOneWidget);
      });

      testWidgets(
        'should render backspace icon dimmed when there is nothing to delete',
        (tester) async {
          await tester.pumpApp(CalculatorPage(viewModel: viewModel));

          final icon = tester.widget<Icon>(
            find.byIcon(Icons.backspace_rounded),
          );
          final colors = Theme.of(
            tester.element(find.byIcon(Icons.backspace_rounded)),
          ).colorScheme;

          expect(icon.color, equals(colors.onSurface.withValues(alpha: 0.5)));
        },
      );

      testWidgets(
        'should render backspace icon in primary color when there is content',
        (tester) async {
          await tester.pumpApp(CalculatorPage(viewModel: viewModel));

          await tester.tap(find.text('5'));
          await tester.pumpAndSettle();

          final icon = tester.widget<Icon>(
            find.byIcon(Icons.backspace_rounded),
          );
          final colors = Theme.of(
            tester.element(find.byIcon(Icons.backspace_rounded)),
          ).colorScheme;

          expect(icon.color, equals(colors.primary));
        },
      );

      testWidgets(
        'should call viewModel.backspace when backspace icon is tapped',
        (tester) async {
          await tester.pumpApp(CalculatorPage(viewModel: viewModel));

          await tester.tap(find.text('5'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('7'));
          await tester.pumpAndSettle();

          expect(getDisplayText(tester), equals('0.57'));

          await tester.tap(find.byIcon(Icons.backspace_rounded));
          await tester.pumpAndSettle();

          expect(getDisplayText(tester), equals('0.05'));
        },
      );
    });

    group('integration', () {
      testWidgets('should update display when digit is tapped', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('12.50'));
      });

      testWidgets('should update display when operator is tapped', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        // Input 1250 → 12.50
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        // Tap operator +
        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('12.50 +'));
      });

      testWidgets('should calculate and show result after equals', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        // Input 10.00 + 5.00 =
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('='));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('15.00'));
      });

      testWidgets('should clear display when C is tapped', (tester) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('C'));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('0.00'));
      });

      testWidgets('should evaluate parenthesized expression via the keypad', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        // ( 5.00 + 3.00 ) × 2.00 = 16.00
        await tester.tap(find.text('( )'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('3'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('( )'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('×'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('='));
        await tester.pumpAndSettle();

        expect(getDisplayText(tester), equals('16.00'));
      });

      testWidgets('should keep C active regardless of current content', (
        tester,
      ) async {
        await tester.pumpApp(CalculatorPage(viewModel: viewModel));

        CalculatorButton clearButton() => tester.widget<CalculatorButton>(
          find.ancestor(
            of: find.text('C'),
            matching: find.byType(CalculatorButton),
          ),
        );

        expect(clearButton().isDimmed, isFalse);

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();

        expect(clearButton().isDimmed, isFalse);
      });
    });
  });
}
