import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/domain/entities/window_position.dart';
import 'package:decima/ui/core/desktop/desktop_window_config.dart';
import 'package:decima/ui/core/desktop/window_position.dart';

/// Inicializa a janela desktop: tamanho fixo, sem a barra de título do
/// sistema (substituída pela AppTitleBar customizada) e na última posição
/// usada — centralizada quando não há posição salva ou ela não é mais
/// alcançável.
///
/// Deve ser chamado antes de `runApp`, apenas em plataformas desktop.
Future<void> initDesktopWindow({
  required SettingsRepository settingsRepository,
}) async {
  await windowManager.ensureInitialized();

  final position = await _restorablePosition(settingsRepository);

  final options = WindowOptions(
    size: DesktopWindowConfig.windowSize,
    minimumSize: DesktopWindowConfig.windowSize,
    maximumSize: DesktopWindowConfig.windowSize,
    center: position == null,
    title: DesktopWindowConfig.appTitle,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setResizable(false);
    await windowManager.setMaximizable(false);
    // Antes do show(): reposicionar depois faria a janela piscar no centro.
    if (position != null) {
      await windowManager.setPosition(Offset(position.x, position.y));
    }
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Posição salva quando ela ainda cai em algum monitor conectado; null em
/// qualquer outro caso — inclusive falha de leitura, que não pode impedir
/// o app de abrir.
Future<WindowPosition?> _restorablePosition(
  SettingsRepository repository,
) async {
  try {
    final saved = await repository.getWindowPosition();
    if (saved == null) return null;

    final displays = await screenRetriever.getAllDisplays();
    if (!isWindowPositionReachable(position: saved, displays: displays)) {
      return null;
    }

    return saved;
  } on Object {
    return null;
  }
}
