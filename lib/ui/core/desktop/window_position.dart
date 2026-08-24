import 'dart:math' as math;
import 'dart:ui';

import 'package:decima/domain/entities/window_position.dart';
import 'package:decima/ui/core/desktop/desktop_window_config.dart';
import 'package:screen_retriever/screen_retriever.dart';

/// Largura mínima da title bar que precisa continuar visível para a janela
/// ser considerada alcançável — o bastante para arrastá-la de volta.
const double minGrabWidth = 80.0;

/// True quando a janela posicionada em [position] ainda pode ser alcançada
/// pelo mouse nos [displays] atuais.
///
/// O critério é a **title bar**: é por ela que a janela se move, então basta
/// que uma fatia dela — [minGrabWidth] × [titleBarHeight] de área — esteja
/// dentro da área útil de algum monitor. Áreas são **somadas** entre os
/// displays, para que uma janela repartida entre dois monitores adjacentes
/// continue válida.
///
/// Devolve false para posição corrompida (`NaN`/infinito), lista de displays
/// vazia, monitor desconectado, e mudança de resolução ou de DPI que tenha
/// deixado a janela fora da área visível. Em todos esses casos o chamador
/// abre a janela centralizada.
bool isWindowPositionReachable({
  required WindowPosition position,
  required List<Display> displays,
  Size windowSize = DesktopWindowConfig.windowSize,
  double titleBarHeight = DesktopWindowConfig.titleBarHeight,
}) {
  if (!position.isFinite) return false;
  if (displays.isEmpty) return false;

  final titleBar = Rect.fromLTWH(
    position.x,
    position.y,
    windowSize.width,
    titleBarHeight,
  );
  final requiredArea = minGrabWidth * titleBarHeight;

  var visibleArea = 0.0;
  for (final display in displays) {
    visibleArea += _overlapArea(titleBar, _visibleBounds(display));
    if (visibleArea >= requiredArea) return true;
  }

  return false;
}

/// True quando [position] merece ser gravada como a última posição da janela.
///
/// No Wayland o cliente não conhece a própria posição — o protocolo não expõe
/// coordenadas globais, e `getPosition()` devolve sempre a origem. Gravar isso
/// faria a janela reabrir encostada no canto superior esquerdo em vez de
/// centralizada, ou seja, pior do que não lembrar nada. Em Linux a origem
/// exata é então tratada como "desconhecida"; o custo do falso negativo no X11
/// (janela realmente encostada no canto) é abrir centralizada na próxima vez.
///
/// [isLinux] é injetado — ver `PlatformInfo.isLinux`.
bool isWindowPositionStorable({
  required WindowPosition position,
  required bool isLinux,
}) {
  if (!position.isFinite) return false;
  if (isLinux && position.x == 0 && position.y == 0) return false;

  return true;
}

/// Área útil do monitor (sem a barra de tarefas), em coordenadas do desktop
/// virtual. Nem toda plataforma preenche `visiblePosition`/`visibleSize` —
/// o fallback é o display inteiro na origem.
Rect _visibleBounds(Display display) {
  return (display.visiblePosition ?? Offset.zero) &
      (display.visibleSize ?? display.size);
}

/// Área da interseção entre dois retângulos; zero quando são disjuntos.
double _overlapArea(Rect a, Rect b) {
  final width = math.min(a.right, b.right) - math.max(a.left, b.left);
  final height = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
  if (width <= 0 || height <= 0) return 0.0;

  return width * height;
}
