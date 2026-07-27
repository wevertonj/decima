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
}
