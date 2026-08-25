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

  /// Re-resolve [ThemeModeOption.system] contra o brilho atual da
  /// plataforma e ressincroniza nativamente. Chamar quando o brilho do SO
  /// muda com o app aberto (`didChangePlatformBrightness`); com preferência
  /// explícita clara/escura é um no-op inofensivo.
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
