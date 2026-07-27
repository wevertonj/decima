import 'dart:ui';

/// Configuração da janela em plataformas desktop.
///
/// A janela tem tamanho fixo (não redimensionável) com proporção
/// mobile-like, alinhada ao layout vertical da calculadora.
class DesktopWindowConfig {
  DesktopWindowConfig._();

  /// Tamanho fixo da janela — usado como size, minimumSize e maximumSize.
  static const Size windowSize = Size(360, 720);

  /// Título nativo da janela (usado antes do l10n estar disponível).
  static const String appTitle = 'WevaCalc';

  /// Altura da [AppTitleBar] customizada.
  static const double titleBarHeight = 40.0;
}
