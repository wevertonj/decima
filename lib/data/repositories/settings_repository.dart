import 'package:decima/domain/entities/window_position.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';

abstract class SettingsRepository {
  Future<ThemeModeOption> getThemeMode();
  Future<void> setThemeMode(ThemeModeOption mode);

  Future<int> getSeedColorIndex();
  Future<void> setSeedColorIndex(int index);

  Future<DecimalSeparator> getDecimalSeparator();
  Future<void> setDecimalSeparator(DecimalSeparator separator);

  Future<String?> getLocale();
  Future<void> setLocale(String? locale);

  /// Last known top-left corner of the desktop window, or null when never
  /// saved or only half stored.
  Future<WindowPosition?> getWindowPosition();
  Future<void> setWindowPosition(double x, double y);
}
