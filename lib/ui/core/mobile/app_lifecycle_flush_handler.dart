import 'dart:ui' show AppExitResponse;

import 'package:decima/utils/platform_info.dart';
import 'package:flutter/widgets.dart';

/// Grava a sessão quando o app vai para segundo plano em mobile.
///
/// O Android encerra o processo sem garantir `detached`, então o flush
/// precisa acontecer já em `hidden`/`paused`. Em desktop nada é registrado
/// — quem cuida do fechamento é o `WindowCloseHandler`; ali `onHide`
/// também dispara ao minimizar, e fechar o cálculo em andamento nesse
/// caso surpreenderia o usuário.
class AppLifecycleFlushHandler extends StatefulWidget {
  const AppLifecycleFlushHandler({
    super.key,
    required this.onFlush,
    required this.child,
  });

  /// Gravação da sessão a executar quando o app sai de primeiro plano.
  final Future<void> Function() onFlush;

  final Widget child;

  @override
  State<AppLifecycleFlushHandler> createState() =>
      _AppLifecycleFlushHandlerState();
}

class _AppLifecycleFlushHandlerState extends State<AppLifecycleFlushHandler> {
  /// Não-null apenas em mobile — é o que marca o handler como ativo.
  AppLifecycleListener? _listener;

  @override
  void initState() {
    super.initState();
    if (PlatformInfo.isDesktop) return;

    _listener = AppLifecycleListener(
      onHide: widget.onFlush,
      onPause: widget.onFlush,
      onExitRequested: _onExitRequested,
    );
  }

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }

  Future<AppExitResponse> _onExitRequested() async {
    await widget.onFlush();

    return AppExitResponse.exit;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
