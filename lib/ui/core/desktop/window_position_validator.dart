import 'dart:math' as math;
import 'dart:ui';

import 'package:decima/domain/entities/window_position.dart';
import 'package:decima/ui/core/desktop/desktop_window_config.dart';
import 'package:screen_retriever/screen_retriever.dart';

/// Largura mínima da title bar que precisa continuar visível para a janela
/// ser considerada alcançável — o bastante para arrastá-la de volta.
const double minGrabWidth = 80.0;

/// `true` quando a janela em [position] ainda pode ser alcançada pelo
/// mouse nos [displays] atuais: uma fatia de [minGrabWidth] ×
/// [titleBarHeight] da title bar visível, **somada** entre os displays.
/// `false` (→ o chamador centraliza) para posição não-finita, lista vazia
/// ou janela fora da área visível.
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

/// `true` quando [position] merece ser gravada como última posição da
/// janela. No Linux a origem exata é tratada como "desconhecida" — no
/// Wayland `getPosition()` devolve sempre a origem (rationale em
/// `docs/fundacao/arquitetura.md` § Memória da posição da janela).
/// [isLinux] é injetado.
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
