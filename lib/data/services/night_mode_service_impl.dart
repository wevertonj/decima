import 'package:decima/data/services/night_mode_service.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NightModeServiceImpl implements NightModeService {
  static const _channel = MethodChannel('com.wevasoft.decima/night_mode');

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
      // Sync best-effort — falhar só significa que a splash do próximo
      // launch pode abrir na cor errada, não um bug funcional.
    } on MissingPluginException {
      // Sem handler nativo registrado (embedding antigo/sem suporte) —
      // nada a sincronizar.
    }
  }
}
