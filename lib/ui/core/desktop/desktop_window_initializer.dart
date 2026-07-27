import 'package:window_manager/window_manager.dart';

import 'package:decima/ui/core/desktop/desktop_window_config.dart';

/// Inicializa a janela desktop: tamanho fixo, centralizada, sem a barra
/// de título do sistema (substituída pela AppTitleBar customizada).
///
/// Deve ser chamado antes de `runApp`, apenas em plataformas desktop.
Future<void> initDesktopWindow() async {
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: DesktopWindowConfig.windowSize,
    minimumSize: DesktopWindowConfig.windowSize,
    maximumSize: DesktopWindowConfig.windowSize,
    center: true,
    title: DesktopWindowConfig.appTitle,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setResizable(false);
    await windowManager.setMaximizable(false);
    await windowManager.show();
    await windowManager.focus();
  });
}
