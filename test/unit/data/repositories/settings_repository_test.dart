import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/data/repositories/settings_repository_impl.dart';
import 'package:decima/domain/entities/window_position.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';

void main() {
  late SettingsRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepositoryImpl();
  });

  group('SettingsRepository', () {
    group('themeMode', () {
      test('should return system as default theme mode', () async {
        final result = await repository.getThemeMode();

        expect(result, ThemeModeOption.system);
      });

      test('should save and load theme mode', () async {
        await repository.setThemeMode(ThemeModeOption.dark);

        final result = await repository.getThemeMode();

        expect(result, ThemeModeOption.dark);
      });

      test('should save and load light theme mode', () async {
        await repository.setThemeMode(ThemeModeOption.light);

        final result = await repository.getThemeMode();

        expect(result, ThemeModeOption.light);
      });
    });

    group('seedColor', () {
      test(
        'should return default seed color index (0) when none saved',
        () async {
          final result = await repository.getSeedColorIndex();

          expect(result, 0);
        },
      );

      test('should save and load seed color index', () async {
        await repository.setSeedColorIndex(5);

        final result = await repository.getSeedColorIndex();

        expect(result, 5);
      });
    });

    group('decimalSeparator', () {
      test('should return dot as default decimal separator', () async {
        final result = await repository.getDecimalSeparator();

        expect(result, DecimalSeparator.dot);
      });

      test('should save and load decimal separator', () async {
        await repository.setDecimalSeparator(DecimalSeparator.comma);

        final result = await repository.getDecimalSeparator();

        expect(result, DecimalSeparator.comma);
      });

      test('should save and load dot separator', () async {
        await repository.setDecimalSeparator(DecimalSeparator.dot);

        final result = await repository.getDecimalSeparator();

        expect(result, DecimalSeparator.dot);
      });
    });

    group('locale', () {
      test('should return null as default locale', () async {
        final result = await repository.getLocale();

        expect(result, isNull);
      });

      test('should save and load locale', () async {
        await repository.setLocale('pt_BR');

        final result = await repository.getLocale();

        expect(result, 'pt_BR');
      });

      test('should save and load different locale', () async {
        await repository.setLocale('en');

        final result = await repository.getLocale();

        expect(result, 'en');
      });

      test('should allow clearing locale to null', () async {
        await repository.setLocale('pt_BR');
        await repository.setLocale(null);

        final result = await repository.getLocale();

        expect(result, isNull);
      });
    });

    group('windowPosition', () {
      test('should return null when no position was saved', () async {
        final result = await repository.getWindowPosition();

        expect(result, isNull);
      });

      test('should save and load the window position', () async {
        await repository.setWindowPosition(1280.0, 240.5);

        final result = await repository.getWindowPosition();

        expect(result, const WindowPosition(x: 1280.0, y: 240.5));
      });

      test('should save negative coordinates (display to the left)', () async {
        await repository.setWindowPosition(-1920.0, -80.0);

        final result = await repository.getWindowPosition();

        expect(result, const WindowPosition(x: -1920.0, y: -80.0));
      });

      test('should overwrite a previously saved position', () async {
        await repository.setWindowPosition(100.0, 100.0);
        await repository.setWindowPosition(300.0, 50.0);

        final result = await repository.getWindowPosition();

        expect(result, const WindowPosition(x: 300.0, y: 50.0));
      });

      test('should return null when only x is stored', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('window_x', 120.0);

        final result = await repository.getWindowPosition();

        expect(result, isNull);
      });

      test('should return null when only y is stored', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('window_y', 120.0);

        final result = await repository.getWindowPosition();

        expect(result, isNull);
      });
    });
  });
}
