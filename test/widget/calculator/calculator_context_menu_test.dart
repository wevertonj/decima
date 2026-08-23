import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/ui/calculator/calculator_page.dart';
import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:decima/ui/calculator/widgets/timeline_display.dart';
import 'package:decima/utils/l10n/app_localizations.dart';

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

  Future<void> longPressDisplay(WidgetTester tester) async {
    await tester.longPress(find.byType(TimelineDisplay));
    await tester.pumpAndSettle();
  }

  Future<void> secondaryTapDisplay(WidgetTester tester) async {
    await tester.tap(
      find.byType(TimelineDisplay),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
  }

  group('CalculatorContextMenu', () {
    testWidgets('should not show copy options when there is nothing typed', (
      tester,
    ) async {
      await tester.pumpApp(CalculatorPage(viewModel: viewModel));

      await longPressDisplay(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.copyExpression), findsNothing);
      expect(find.text(l10n.copyResult), findsNothing);
      expect(find.text(l10n.copyHistory), findsNothing);
      expect(find.text(l10n.paste), findsOneWidget);
    });

    testWidgets('should show copyExpression option after a digit is typed', (
      tester,
    ) async {
      await tester.pumpApp(CalculatorPage(viewModel: viewModel));
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      await longPressDisplay(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.copyExpression), findsOneWidget);
    });

    testWidgets('should copy expression and dismiss menu when tapped', (
      tester,
    ) async {
      await tester.pumpApp(CalculatorPage(viewModel: viewModel));
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      await longPressDisplay(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.copyExpression));
      await tester.pumpAndSettle();

      verify(() => mockClipboardService.copyText('12.50')).called(1);
      expect(find.text(l10n.copyExpression), findsNothing);
    });

    testWidgets('should show snackbar when paste content is invalid', (
      tester,
    ) async {
      when(
        () => mockClipboardService.readText(),
      ).thenAnswer((_) async => 'not a number');

      await tester.pumpApp(
        Scaffold(body: CalculatorPage(viewModel: viewModel)),
      );

      await longPressDisplay(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.paste));
      await tester.pumpAndSettle();

      expect(find.text(l10n.pasteInvalid), findsOneWidget);
    });

    testWidgets('should paste valid content into the display', (tester) async {
      when(
        () => mockClipboardService.readText(),
      ).thenAnswer((_) async => '1250');

      await tester.pumpApp(CalculatorPage(viewModel: viewModel));

      await longPressDisplay(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.paste));
      await tester.pumpAndSettle();

      expect(viewModel.currentDisplayValue, '1,250.00');
    });

    testWidgets('should open the menu on right click', (tester) async {
      await tester.pumpApp(CalculatorPage(viewModel: viewModel));
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      await secondaryTapDisplay(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.copyExpression), findsOneWidget);
      expect(find.text(l10n.paste), findsOneWidget);
    });

    testWidgets('should copy expression selected from the right click menu', (
      tester,
    ) async {
      await tester.pumpApp(CalculatorPage(viewModel: viewModel));
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      await secondaryTapDisplay(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.copyExpression));
      await tester.pumpAndSettle();

      verify(() => mockClipboardService.copyText('12.50')).called(1);
      expect(find.text(l10n.copyExpression), findsNothing);
    });
  });
}
