import 'package:decima/domain/enums/theme_mode_option.dart';

/// Espelha o tema escolhido no app no modo noturno nativo do SO
/// (`UiModeManager`, Android 12+), para a splash nativa do próximo launch
/// já abrir na cor certa mesmo divergindo do dark mode do sistema.
abstract class NightModeService {
  /// Resolve [mode] contra o brilho atual da plataforma (para
  /// [ThemeModeOption.system]) e sincroniza o resultado nativamente.
  /// No-op em plataformas/versões sem suporte nativo.
  Future<void> syncThemeMode(ThemeModeOption mode);
}
