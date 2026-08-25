import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:decima/ui/settings/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_night_mode_service.dart';
import '../../../mocks/mock_settings_repository.dart';

void main() {
  late SettingsViewModel viewModel;
  late MockSettingsRepository mockRepository;
  late MockNightModeService mockNightModeService;

  setUpAll(() {
    registerFallbackValue(ThemeModeOption.system);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    mockNightModeService = MockNightModeService();
    when(
      () => mockNightModeService.syncThemeMode(any()),
    ).thenAnswer((_) async {});
  });

  group('SettingsViewModel', () {
    group('initial state', () {
      test('should have default values before loading', () {
        viewModel = SettingsViewModel(
          settingsRepository: mockRepository,
          nightModeService: mockNightModeService,
        );

        expect(viewModel.themeMode, ThemeModeOption.system);
        expect(viewModel.seedColorIndex, 0);
        expect(viewModel.decimalSeparator, DecimalSeparator.dot);
        expect(viewModel.locale, isNull);
      });
    });

    group('loadSettings', () {
      test('should load all settings from repository', () async {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeModeOption.dark);
        when(
          () => mockRepository.getSeedColorIndex(),
        ).thenAnswer((_) async => 3);
        when(
          () => mockRepository.getDecimalSeparator(),
        ).thenAnswer((_) async => DecimalSeparator.comma);
        when(() => mockRepository.getLocale()).thenAnswer((_) async => 'pt_BR');

        viewModel = SettingsViewModel(
          settingsRepository: mockRepository,
          nightModeService: mockNightModeService,
        );
        await viewModel.loadSettings();

        expect(viewModel.themeMode, ThemeModeOption.dark);
        expect(viewModel.seedColorIndex, 3);
        expect(viewModel.decimalSeparator, DecimalSeparator.comma);
        expect(viewModel.locale, 'pt_BR');
      });

      test('should notify listeners after loading', () async {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeModeOption.system);
        when(
          () => mockRepository.getSeedColorIndex(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockRepository.getDecimalSeparator(),
        ).thenAnswer((_) async => DecimalSeparator.dot);
        when(() => mockRepository.getLocale()).thenAnswer((_) async => null);

        viewModel = SettingsViewModel(
          settingsRepository: mockRepository,
          nightModeService: mockNightModeService,
        );

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.loadSettings();

        expect(notified, true);
      });
    });

    group('setThemeMode', () {
      setUp(() {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeModeOption.system);
        when(
          () => mockRepository.getSeedColorIndex(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockRepository.getDecimalSeparator(),
        ).thenAnswer((_) async => DecimalSeparator.dot);
        when(() => mockRepository.getLocale()).thenAnswer((_) async => null);

        viewModel = SettingsViewModel(
          settingsRepository: mockRepository,
          nightModeService: mockNightModeService,
        );
      });

      test('should update theme mode and persist', () async {
        when(
          () => mockRepository.setThemeMode(ThemeModeOption.dark),
        ).thenAnswer((_) async {});

        await viewModel.setThemeMode(ThemeModeOption.dark);

        expect(viewModel.themeMode, ThemeModeOption.dark);
        verify(
          () => mockRepository.setThemeMode(ThemeModeOption.dark),
        ).called(1);
      });

      test('should notify listeners when theme mode changes', () async {
        when(
          () => mockRepository.setThemeMode(ThemeModeOption.light),
        ).thenAnswer((_) async {});

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.setThemeMode(ThemeModeOption.light);

        expect(notified, true);
      });
    });

    group('setSeedColorIndex', () {
      setUp(() {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeModeOption.system);
        when(
          () => mockRepository.getSeedColorIndex(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockRepository.getDecimalSeparator(),
        ).thenAnswer((_) async => DecimalSeparator.dot);
        when(() => mockRepository.getLocale()).thenAnswer((_) async => null);

        viewModel = SettingsViewModel(
          settingsRepository: mockRepository,
          nightModeService: mockNightModeService,
        );
      });

      test('should update seed color index and persist', () async {
        when(
          () => mockRepository.setSeedColorIndex(5),
        ).thenAnswer((_) async {});

        await viewModel.setSeedColorIndex(5);

        expect(viewModel.seedColorIndex, 5);
        verify(() => mockRepository.setSeedColorIndex(5)).called(1);
      });

      test('should notify listeners when seed color changes', () async {
        when(
          () => mockRepository.setSeedColorIndex(2),
        ).thenAnswer((_) async {});

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.setSeedColorIndex(2);

        expect(notified, true);
      });
    });

    group('setDecimalSeparator', () {
      setUp(() {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeModeOption.system);
        when(
          () => mockRepository.getSeedColorIndex(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockRepository.getDecimalSeparator(),
        ).thenAnswer((_) async => DecimalSeparator.dot);
        when(() => mockRepository.getLocale()).thenAnswer((_) async => null);

        viewModel = SettingsViewModel(
          settingsRepository: mockRepository,
          nightModeService: mockNightModeService,
        );
      });

      test('should update decimal separator and persist', () async {
        when(
          () => mockRepository.setDecimalSeparator(DecimalSeparator.comma),
        ).thenAnswer((_) async {});

        await viewModel.setDecimalSeparator(DecimalSeparator.comma);

        expect(viewModel.decimalSeparator, DecimalSeparator.comma);
        verify(
          () => mockRepository.setDecimalSeparator(DecimalSeparator.comma),
        ).called(1);
      });

      test('should notify listeners when separator changes', () async {
        when(
          () => mockRepository.setDecimalSeparator(DecimalSeparator.comma),
        ).thenAnswer((_) async {});

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.setDecimalSeparator(DecimalSeparator.comma);

        expect(notified, true);
      });
    });

    group('setLocale', () {
      setUp(() {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeModeOption.system);
        when(
          () => mockRepository.getSeedColorIndex(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockRepository.getDecimalSeparator(),
        ).thenAnswer((_) async => DecimalSeparator.dot);
        when(() => mockRepository.getLocale()).thenAnswer((_) async => null);

        viewModel = SettingsViewModel(
          settingsRepository: mockRepository,
          nightModeService: mockNightModeService,
        );
      });

      test('should update locale and persist', () async {
        when(() => mockRepository.setLocale('pt_BR')).thenAnswer((_) async {});

        await viewModel.setLocale('pt_BR');

        expect(viewModel.locale, 'pt_BR');
        verify(() => mockRepository.setLocale('pt_BR')).called(1);
      });

      test('should notify listeners when locale changes', () async {
        when(() => mockRepository.setLocale('en')).thenAnswer((_) async {});

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.setLocale('en');

        expect(notified, true);
      });

      test('should allow setting locale to null', () async {
        when(() => mockRepository.setLocale(null)).thenAnswer((_) async {});

        await viewModel.setLocale(null);

        expect(viewModel.locale, isNull);
        verify(() => mockRepository.setLocale(null)).called(1);
      });
    });

    group('native night mode sync', () {
      setUp(() {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeModeOption.dark);
        when(
          () => mockRepository.getSeedColorIndex(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockRepository.getDecimalSeparator(),
        ).thenAnswer((_) async => DecimalSeparator.dot);
        when(() => mockRepository.getLocale()).thenAnswer((_) async => null);
        when(() => mockRepository.setThemeMode(any())).thenAnswer((_) async {});

        viewModel = SettingsViewModel(
          settingsRepository: mockRepository,
          nightModeService: mockNightModeService,
        );
      });

      test('loadSettings syncs the loaded theme mode natively', () async {
        await viewModel.loadSettings();

        verify(
          () => mockNightModeService.syncThemeMode(ThemeModeOption.dark),
        ).called(1);
      });

      test('setThemeMode syncs the new theme mode natively', () async {
        await viewModel.setThemeMode(ThemeModeOption.light);

        verify(
          () => mockNightModeService.syncThemeMode(ThemeModeOption.light),
        ).called(1);
      });

      test('syncNativeNightMode re-syncs the current theme mode', () async {
        await viewModel.loadSettings();
        clearInteractions(mockNightModeService);

        viewModel.syncNativeNightMode();

        verify(
          () => mockNightModeService.syncThemeMode(ThemeModeOption.dark),
        ).called(1);
      });
    });
  });
}
