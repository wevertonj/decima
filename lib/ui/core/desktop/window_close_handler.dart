import 'dart:async';

import 'package:decima/utils/platform_info.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

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

  /// Encerra a janela imediatamente, ignorando o `preventClose`.
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

  /// No Windows, `destroy()` do plugin não destrói a janela na hora — o
  /// desvio via `preventClose(false)` + `close()` real destrói. Rationale
  /// completo em `docs/fundacao/arquitetura.md` § Infra de Desktop.
  @override
  Future<void> destroy() async {
    if (!PlatformInfo.isWindows) {
      await windowManager.destroy();

      return;
    }

    await windowManager.setPreventClose(false);
    await windowManager.close();
  }
}

/// Intercepta o fechamento da janela em desktop para gravar a sessão e a
/// posição antes de o processo terminar. A destruição acontece **sempre**,
/// mesmo com falha ou timeout nas gravações. Em mobile e web nada é
/// registrado: [child] é renderizado direto.
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

  /// `true` do primeiro [onWindowClose] aceito até a destruição. Absorve o
  /// [onWindowClose] reentrante que o `close()` do Windows gera e cliques
  /// repetidos no `X` enquanto as gravações rodam.
  bool _closing = false;

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
    if (_closing) return;

    _closing = true;
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
      try {
        await bridge.destroy();
      } on Object {
        // Destruir falhou: liberar a trava para que o próximo clique no `X`
        // tente de novo, em vez de deixar a janela impossível de fechar.
        _closing = false;
      }
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
