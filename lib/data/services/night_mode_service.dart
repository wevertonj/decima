import 'package:wevacalc/domain/enums/theme_mode_option.dart';

/// Mirrors the app's chosen theme into the native OS-level night mode
/// (Android 12+ `UiModeManager`), so the next launch's native splash screen
/// already opens in the correct color even when it differs from the
/// device's system-wide dark mode setting.
abstract class NightModeService {
  /// Resolves [mode] against the current platform brightness (for
  /// [ThemeModeOption.system]) and syncs the result natively. No-op on
  /// platforms/OS versions without native support.
  Future<void> syncThemeMode(ThemeModeOption mode);
}
