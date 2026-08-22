import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'package:decima/utils/platform_info.dart';

/// Ponte com o `window_manager` usada pelo [WindowCloseHandler].
///
/// Existe para manter o handler testável: o plugin real depende de method
/// channels nativos, indisponíveis em `flutter test`.
abstract class WindowCloseBridge {
  /// Faz o pedido de fechamento chegar como [WindowListener.onWindowClose]
  /// em vez de encerrar o app imediatamente.
  Future<void> setPreventClose(bool value);

  void addListener(WindowListener listener);

  void removeListener(WindowListener listener);

  /// Canto superior esquerdo da janela, em pixels lógicos.
  Future<Offset> getPosition();

  /// Fecha a janela ignorando o `preventClose`.
  Future<void> destroy();
}

/// Implementação real, delegando ao singleton [windowManager].
class WindowManagerCloseBridge implements WindowCloseBridge {
  const WindowManagerCloseBridge();

  @override
  Future<void> setPreventClose(bool value) =>
      windowManager.setPreventClose(value);

  @override
  void addListener(WindowListener listener) =>
      windowManager.addListener(listener);

  @override
  void removeListener(WindowListener listener) =>
      windowManager.removeListener(listener);

  @override
  Future<Offset> getPosition() => windowManager.getPosition();

  @override
  Future<void> destroy() => windowManager.destroy();
}

/// Intercepta o fechamento da janela em desktop para gravar a sessão e a
/// posição da janela antes de o processo terminar.
///
/// Com `setPreventClose(true)`, o `X` da title bar, o `Alt+F4` e o "Fechar
/// janela" da barra de tarefas chegam como [WindowListener.onWindowClose]
/// em vez de encerrarem o app. O handler chama [onFlush] e [onSavePosition]
/// — **em paralelo**, para que um travar não impeça o outro — e só então
/// destrói a janela. A destruição acontece **sempre**, mesmo que as
/// gravações falhem ou estourem [flushTimeout], para que o app nunca fique
/// impossível de fechar.
///
/// Em mobile e web nada é registrado: [child] é renderizado direto.
class WindowCloseHandler extends StatefulWidget {
  const WindowCloseHandler({
    super.key,
    required this.onFlush,
    required this.child,
    this.onSavePosition,
    this.bridge,
    this.flushTimeout = defaultFlushTimeout,
  });

  /// Tempo máximo de espera pelas gravações antes de fechar assim mesmo.
  static const Duration defaultFlushTimeout = Duration(seconds: 3);

  /// Gravação da sessão a executar antes de destruir a janela.
  final Future<void> Function() onFlush;

  /// Gravação da posição da janela, lida do plugin logo antes do fechamento.
  /// Quando null, a posição não é consultada nem salva.
  final Future<void> Function(double x, double y)? onSavePosition;

  final Widget child;

  /// Ponte com o `window_manager`. Quando null, usa a real.
  final WindowCloseBridge? bridge;

  final Duration flushTimeout;

  @override
  State<WindowCloseHandler> createState() => _WindowCloseHandlerState();
}

class _WindowCloseHandlerState extends State<WindowCloseHandler>
    with WindowListener {
  /// Não-null apenas em desktop — é o que marca o handler como ativo.
  WindowCloseBridge? _bridge;

  @override
  void initState() {
    super.initState();
    if (!PlatformInfo.isDesktop) return;

    final bridge = widget.bridge ?? const WindowManagerCloseBridge();
    _bridge = bridge;
    bridge.addListener(this);
    unawaited(bridge.setPreventClose(true));
  }

  @override
  void dispose() {
    _bridge?.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(_flushAndDestroy());
  }

  Future<void> _flushAndDestroy() async {
    final bridge = _bridge;
    if (bridge == null) return;

    try {
      // `Future.wait` sem `eagerError`: as duas gravações sempre rodam até
      // o fim, e o erro da primeira que falhar chega depois disso.
      await Future.wait([
        widget.onFlush(),
        _savePosition(bridge),
      ]).timeout(widget.flushTimeout);
    } on Object {
      // Falha ou timeout nas gravações não pode impedir o fechamento — o
      // `finally` destrói a janela de qualquer forma.
    } finally {
      await bridge.destroy();
    }
  }

  Future<void> _savePosition(WindowCloseBridge bridge) async {
    final save = widget.onSavePosition;
    if (save == null) return;

    final position = await bridge.getPosition();
    await save(position.dx, position.dy);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
