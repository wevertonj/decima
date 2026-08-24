import 'dart:async';

import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/data/services/night_mode_service.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:flutter/foundation.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required SettingsRepository settingsRepository,
    required NightModeService nightModeService,
  }) : _settingsRepository = settingsRepository,
       _nightModeService = nightModeService;

  final SettingsRepository _settingsRepository;
  final NightModeService _nightModeService;

  ThemeModeOption _themeMode = ThemeModeOption.system;
  int _seedColorIndex = 0;
  DecimalSeparator _decimalSeparator = DecimalSeparator.dot;
  String? _locale;

  ThemeModeOption get themeMode => _themeMode;

  int get seedColorIndex => _seedColorIndex;

  DecimalSeparator get decimalSeparator => _decimalSeparator;

  String? get locale => _locale;

  Future<void> loadSettings() async {
    _themeMode = await _settingsRepository.getThemeMode();
    _seedColorIndex = await _settingsRepository.getSeedColorIndex();
    _decimalSeparator = await _settingsRepository.getDecimalSeparator();
    _locale = await _settingsRepository.getLocale();
    unawaited(_nightModeService.syncThemeMode(_themeMode));
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    _themeMode = mode;
    await _settingsRepository.setThemeMode(mode);
    unawaited(_nightModeService.syncThemeMode(mode));
    notifyListeners();
  }

  /// Re-resolves [ThemeModeOption.system] against the current platform
  /// brightness and re-syncs it natively. Call when the OS brightness
  /// changes while the app is open (e.g. `didChangePlatformBrightness`) —
  /// with an explicit light/dark preference this is a harmless no-op.
  void syncNativeNightMode() {
    unawaited(_nightModeService.syncThemeMode(_themeMode));
  }

  Future<void> setSeedColorIndex(int index) async {
    _seedColorIndex = index;
    await _settingsRepository.setSeedColorIndex(index);
    notifyListeners();
  }

  Future<void> setDecimalSeparator(DecimalSeparator separator) async {
    _decimalSeparator = separator;
    await _settingsRepository.setDecimalSeparator(separator);
    notifyListeners();
  }

  Future<void> setLocale(String? locale) async {
    _locale = locale;
    await _settingsRepository.setLocale(locale);
    notifyListeners();
  }
}
