import 'package:decima/config/theme/app_colors.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:decima/ui/settings/settings_page.dart';
import 'package:decima/ui/settings/settings_view_model.dart';
import 'package:decima/ui/settings/widgets/color_picker.dart';
import 'package:decima/ui/settings/widgets/decimal_separator_selector.dart';
import 'package:decima/ui/settings/widgets/language_selector.dart';
import 'package:decima/ui/settings/widgets/theme_mode_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';
import '../../mocks/mock_night_mode_service.dart';
import '../../mocks/mock_settings_repository.dart';

void main() {
  late MockSettingsRepository mockSettingsRepository;
  late MockNightModeService mockNightModeService;
  late SettingsViewModel viewModel;

  setUpAll(() {
    registerFallbackValue(ThemeModeOption.system);
    registerFallbackValue(DecimalSeparator.dot);
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    mockNightModeService = MockNightModeService();
    when(
      () => mockNightModeService.syncThemeMode(any()),
    ).thenAnswer((_) async {});

    when(
      () => mockSettingsRepository.getThemeMode(),
    ).thenAnswer((_) async => ThemeModeOption.dark);
    when(
      () => mockSettingsRepository.getSeedColorIndex(),
    ).thenAnswer((_) async => 0);
    when(
      () => mockSettingsRepository.getDecimalSeparator(),
    ).thenAnswer((_) async => DecimalSeparator.dot);
    when(
      () => mockSettingsRepository.getLocale(),
    ).thenAnswer((_) async => null);

    when(
      () => mockSettingsRepository.setThemeMode(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockSettingsRepository.setSeedColorIndex(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockSettingsRepository.setDecimalSeparator(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockSettingsRepository.setLocale(any()),
    ).thenAnswer((_) async {});

    viewModel = SettingsViewModel(
      settingsRepository: mockSettingsRepository,
      nightModeService: mockNightModeService,
    );
  });

  group('SettingsPage', () {
    Future<void> pumpSettingsPage(WidgetTester tester) async {
      await viewModel.loadSettings();
      await tester.pumpApp(SettingsPage(viewModel: viewModel));
    }

    group('rendering', () {
      testWidgets('should display title and all sections', (tester) async {
        await pumpSettingsPage(tester);

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Theme'), findsOneWidget);
        expect(find.text('Color'), findsOneWidget);
        expect(find.text('Number format'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
      });

      testWidgets('should display all sub-widgets', (tester) async {
        await pumpSettingsPage(tester);

        expect(find.byType(ThemeModeSelector), findsOneWidget);
        expect(find.byType(ColorPicker), findsOneWidget);
        expect(find.byType(DecimalSeparatorSelector), findsOneWidget);
        expect(find.byType(LanguageSelector), findsOneWidget);
      });

      testWidgets('should display theme mode options', (tester) async {
        await pumpSettingsPage(tester);

        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
        // "System" aparece nas seções de tema e de idioma
        expect(find.text('System'), findsAtLeast(1));
      });

      testWidgets('should display 9 color circles', (tester) async {
        await pumpSettingsPage(tester);

        final colorPicker = tester.widget<ColorPicker>(
          find.byType(ColorPicker),
        );
        // O color picker deve exibir as 9 cores de AppColors
        expect(AppColors.seedColors.length, equals(9));
        expect(colorPicker.selectedIndex, equals(0));
      });
    });

    group('interactions', () {
      testWidgets('should change theme mode when tapped', (tester) async {
        await pumpSettingsPage(tester);

        await tester.tap(find.text('Light'));
        await tester.pumpAndSettle();

        verify(
          () => mockSettingsRepository.setThemeMode(ThemeModeOption.light),
        ).called(1);
      });

      testWidgets('should change decimal separator when tapped', (
        tester,
      ) async {
        await pumpSettingsPage(tester);

        await tester.tap(find.text('1.000,00'));
        await tester.pumpAndSettle();

        verify(
          () => mockSettingsRepository.setDecimalSeparator(
            DecimalSeparator.comma,
          ),
        ).called(1);
      });

      testWidgets('should change language when tapped', (tester) async {
        await pumpSettingsPage(tester);

        await tester.tap(find.text('Português'));
        await tester.pumpAndSettle();

        verify(() => mockSettingsRepository.setLocale('pt')).called(1);
      });

      testWidgets('should select system language', (tester) async {
        // Começa com um idioma específico
        when(
          () => mockSettingsRepository.getLocale(),
        ).thenAnswer((_) async => 'en');
        viewModel = SettingsViewModel(
          settingsRepository: mockSettingsRepository,
          nightModeService: mockNightModeService,
        );

        await pumpSettingsPage(tester);

        // Toca em "System" de idioma (escopado no LanguageSelector para
        // evitar ambiguidade com o "System" do ThemeModeSelector)
        await tester.tap(
          find.descendant(
            of: find.byType(LanguageSelector),
            matching: find.text('System'),
          ),
        );
        await tester.pumpAndSettle();

        verify(() => mockSettingsRepository.setLocale(null)).called(1);
      });
    });
  });
}
