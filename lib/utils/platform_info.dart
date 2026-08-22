import 'package:flutter/foundation.dart';

/// Detecção de plataforma testável.
///
/// Usa [defaultTargetPlatform] em vez de `Platform` para permitir
/// override nos testes via [debugDefaultTargetPlatformOverride].
class PlatformInfo {
  PlatformInfo._();

  /// True quando rodando em desktop (Windows, Linux ou macOS).
  ///
  /// Guarda [kIsWeb] primeiro — na web, [defaultTargetPlatform]
  /// reporta o sistema operacional do navegador.
  static bool get isDesktop {
    if (kIsWeb) return false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// True quando rodando em Linux (GTK).
  ///
  /// Existe para desviar de APIs do `window_manager` cujo comportamento no
  /// GTK difere do Windows/macOS — ver `initDesktopWindow`.
  static bool get isLinux {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.linux;
  }
}
