import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:wevacalc/data/services/night_mode_service.dart';
import 'package:wevacalc/domain/enums/theme_mode_option.dart';

class NightModeServiceImpl implements NightModeService {
  static const _channel = MethodChannel('com.wevasoft.wevacalc/night_mode');

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> syncThemeMode(ThemeModeOption mode) async {
    if (!_isSupported) return;

    final dark = switch (mode) {
      ThemeModeOption.dark => true,
      ThemeModeOption.light => false,
      ThemeModeOption.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };

    try {
      await _channel.invokeMethod<void>('setApplicationNightMode', {
        'dark': dark,
      });
    } on PlatformException {
      // Best-effort sync — a failure here only means the next launch's
      // splash may briefly show the wrong color, not a functional bug.
    } on MissingPluginException {
      // No native handler registered (e.g. running on an older/unsupported
      // embedding) — nothing to sync.
    }
  }
}
