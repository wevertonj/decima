import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:screen_retriever/screen_retriever.dart';

import 'package:decima/domain/entities/window_position.dart';
import 'package:decima/ui/core/desktop/window_position.dart';

/// Display de teste. `visiblePosition`/`visibleSize` descrevem a área útil
/// (fora da barra de tarefas) — é contra ela que a validação roda.
Display _display({
  String id = 'primary',
  Offset position = Offset.zero,
  Size size = const Size(1920, 1080),
  Size? visibleSize,
}) {
  return Display(
    id: id,
    size: size,
    visiblePosition: position,
    visibleSize: visibleSize ?? size,
  );
}

void main() {
  final primary = _display();
  final secondary = _display(id: 'secondary', position: const Offset(1920, 0));

  group('isWindowPositionReachable', () {
    test('accepts a position fully inside a display', () {
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 600, y: 200),
        displays: [primary],
      );

      expect(result, isTrue);
    });

    test('accepts a position on a secondary display', () {
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 2400, y: 100),
        displays: [primary, secondary],
      );

      expect(result, isTrue);
    });

    test('accepts a position at the exact origin of a display', () {
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 0, y: 0),
        displays: [primary],
      );

      expect(result, isTrue);
    });

    test('rejects a position outside every display', () {
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 4000, y: 200),
        displays: [primary, secondary],
      );

      expect(result, isFalse);
    });

    test('rejects a position on a display that was disconnected', () {
      // Salva no monitor secundário, reaberta apenas com o primário.
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 2400, y: 100),
        displays: [primary],
      );

      expect(result, isFalse);
    });

    test('accepts a partially visible window with a grabbable title bar', () {
      // 120 px de largura ainda dentro do display — dá para arrastar de volta.
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 1800, y: 300),
        displays: [primary],
      );

      expect(result, isTrue);
    });

    test(
      'rejects a partially visible window with a title bar out of reach',
      () {
        // Só 30 px de largura sobram — abaixo do mínimo para arrastar.
        final result = isWindowPositionReachable(
          position: const WindowPosition(x: 1890, y: 300),
          displays: [primary],
        );

        expect(result, isFalse);
      },
    );

    test('accepts a title bar partially above the top edge', () {
      // 30 dos 40 px da title bar continuam visíveis.
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 600, y: -10),
        displays: [primary],
      );

      expect(result, isTrue);
    });

    test('rejects a title bar almost entirely above the top edge', () {
      // Sobram 5 px de altura — área insuficiente para agarrar a janela.
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 600, y: -35),
        displays: [primary],
      );

      expect(result, isFalse);
    });

    test('rejects a title bar below the bottom edge', () {
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 600, y: 1080),
        displays: [primary],
      );

      expect(result, isFalse);
    });

    test('rejects a title bar hidden behind the taskbar area', () {
      final withTaskbar = _display(visibleSize: const Size(1920, 1032));

      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 600, y: 1040),
        displays: [withTaskbar],
      );

      expect(result, isFalse);
    });

    test('accepts a window straddling two adjacent displays', () {
      // Metade em cada monitor: a title bar segue inteira visível, mas só a
      // soma das duas interseções revela isso.
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 1740, y: 300),
        displays: [primary, secondary],
      );

      expect(result, isTrue);
    });

    test('rejects any position when there is no display', () {
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 600, y: 200),
        displays: const [],
      );

      expect(result, isFalse);
    });

    test('rejects non-finite coordinates', () {
      expect(
        isWindowPositionReachable(
          position: const WindowPosition(x: double.nan, y: 200),
          displays: [primary],
        ),
        isFalse,
      );
      expect(
        isWindowPositionReachable(
          position: const WindowPosition(x: 600, y: double.infinity),
          displays: [primary],
        ),
        isFalse,
      );
    });

    test(
      'falls back to the full size when the display omits the visible area',
      () {
        const bare = Display(id: 'bare', size: Size(1920, 1080));

        final result = isWindowPositionReachable(
          position: const WindowPosition(x: 600, y: 200),
          displays: const [bare],
        );

        expect(result, isTrue);
      },
    );

    test('honors a custom window size and title bar height', () {
      // Janela larga: 100 px visíveis passam a bastar em qualquer largura.
      final result = isWindowPositionReachable(
        position: const WindowPosition(x: 1820, y: 300),
        windowSize: const Size(1200, 800),
        titleBarHeight: 40,
        displays: [primary],
      );

      expect(result, isTrue);
    });
  });

  group('isWindowPositionStorable', () {
    test('accepts an ordinary position on any platform', () {
      for (final isLinux in [true, false]) {
        expect(
          isWindowPositionStorable(
            position: const WindowPosition(x: 400, y: 250),
            isLinux: isLinux,
          ),
          isTrue,
          reason: 'isLinux: $isLinux',
        );
      }
    });

    test('rejects the origin on Linux (Wayland cannot report a position)', () {
      expect(
        isWindowPositionStorable(
          position: const WindowPosition(x: 0, y: 0),
          isLinux: true,
        ),
        isFalse,
      );
    });

    test('accepts the origin off Linux — there it is a real position', () {
      expect(
        isWindowPositionStorable(
          position: const WindowPosition(x: 0, y: 0),
          isLinux: false,
        ),
        isTrue,
      );
    });

    test('rejects the origin on Linux only when both axes are zero', () {
      expect(
        isWindowPositionStorable(
          position: const WindowPosition(x: 0, y: 250),
          isLinux: true,
        ),
        isTrue,
      );
      expect(
        isWindowPositionStorable(
          position: const WindowPosition(x: 400, y: 0),
          isLinux: true,
        ),
        isTrue,
      );
    });

    test('rejects a corrupt position', () {
      expect(
        isWindowPositionStorable(
          position: const WindowPosition(x: double.nan, y: 250),
          isLinux: false,
        ),
        isFalse,
      );
      expect(
        isWindowPositionStorable(
          position: const WindowPosition(x: 400, y: double.infinity),
          isLinux: false,
        ),
        isFalse,
      );
    });
  });
}
