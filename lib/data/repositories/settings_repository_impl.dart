import 'package:shared_preferences/shared_preferences.dart';

import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/domain/entities/window_position.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _keyThemeMode = 'theme_mode';
  static const _keySeedColorIndex = 'seed_color_index';
  static const _keyDecimalSeparator = 'decimal_separator';
  static const _keyLocale = 'locale';
  static const _keyWindowX = 'window_x';
  static const _keyWindowY = 'window_y';

  @override
  Future<ThemeModeOption> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode);

    if (value == null) return ThemeModeOption.system;

    return ThemeModeOption.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeModeOption.system,
    );
  }

  @override
  Future<void> setThemeMode(ThemeModeOption mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  @override
  Future<int> getSeedColorIndex() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_keySeedColorIndex) ?? 0;
  }

  @override
  Future<void> setSeedColorIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeedColorIndex, index);
  }

  @override
  Future<DecimalSeparator> getDecimalSeparator() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyDecimalSeparator);

    if (value == null) return DecimalSeparator.dot;

    return DecimalSeparator.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DecimalSeparator.dot,
    );
  }

  @override
  Future<void> setDecimalSeparator(DecimalSeparator separator) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDecimalSeparator, separator.name);
  }

  @override
  Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_keyLocale);
  }

  @override
  Future<void> setLocale(String? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_keyLocale);
    } else {
      await prefs.setString(_keyLocale, locale);
    }
  }

  @override
  Future<WindowPosition?> getWindowPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_keyWindowX);
    final y = prefs.getDouble(_keyWindowY);

    // Meia posição não é posição: só uma das chaves gravadas (escrita
    // interrompida) equivale a não ter posição salva.
    if (x == null || y == null) return null;

    return WindowPosition(x: x, y: y);
  }

  @override
  Future<void> setWindowPosition(double x, double y) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWindowX, x);
    await prefs.setDouble(_keyWindowY, y);
  }
}
