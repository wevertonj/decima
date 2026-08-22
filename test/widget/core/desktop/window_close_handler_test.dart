import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

import 'package:decima/ui/core/desktop/window_close_handler.dart';

import '../../../helpers/pump_app.dart';

/// Ponte falsa: registra o listener e a ordem dos eventos, sem tocar em
/// nenhum method channel.
class _FakeWindowCloseBridge implements WindowCloseBridge {
  WindowListener? listener;
  bool? preventClose;
  int getPositionCalls = 0;
  Offset position = const Offset(1280, 240);
  final List<String> events = [];

  @override
  void addListener(WindowListener listener) => this.listener = listener;

  @override
  void removeListener(WindowListener listener) {
    if (this.listener == listener) this.listener = null;
  }

  @override
  Future<void> setPreventClose(bool value) async => preventClose = value;

  @override
  Future<Offset> getPosition() async {
    getPositionCalls++;

    return position;
  }

  @override
  Future<void> destroy() async => events.add('destroy');
}

void main() {
  late _FakeWindowCloseBridge bridge;
  late List<String> events;

  setUp(() {
    bridge = _FakeWindowCloseBridge();
    events = bridge.events;
  });

  // O binding verifica que debugDefaultTargetPlatformOverride foi restaurado
  // ANTES dos tearDowns — o reset acontece no corpo do teste, logo após o
  // pump. A plataforma só é lida no initState, então isso é suficiente.
  Future<void> pumpHandlerOn(
    WidgetTester tester,
    TargetPlatform platform, {
    required Future<void> Function() onFlush,
    Future<void> Function(double x, double y)? onSavePosition,
    Duration flushTimeout = WindowCloseHandler.defaultFlushTimeout,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    await tester.pumpApp(
      WindowCloseHandler(
        onFlush: onFlush,
        onSavePosition: onSavePosition,
        bridge: bridge,
        flushTimeout: flushTimeout,
        child: const Scaffold(body: Center(child: Text('content'))),
      ),
    );
    debugDefaultTargetPlatformOverride = null;
  }

  group('WindowCloseHandler', () {
    testWidgets('renders the child', (tester) async {
      await pumpHandlerOn(tester, TargetPlatform.windows, onFlush: () async {});

      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('registers the listener and prevents close on desktop', (
      tester,
    ) async {
      await pumpHandlerOn(tester, TargetPlatform.windows, onFlush: () async {});

      expect(bridge.listener, isNotNull);
      expect(bridge.preventClose, isTrue);
    });

    testWidgets('flushes the session before destroying the window', (
      tester,
    ) async {
      final flush = Completer<void>();
      await pumpHandlerOn(
        tester,
        TargetPlatform.windows,
        onFlush: () {
          events.add('flush');

          return flush.future;
        },
      );

      bridge.listener!.onWindowClose();
      await tester.pump();

      // A janela ainda não pode ter sido destruída: a gravação está em voo.
      expect(events, ['flush']);

      flush.complete();
      await tester.pump();

      expect(events, ['flush', 'destroy']);
    });

    testWidgets('destroys the window even when the flush throws', (
      tester,
    ) async {
      await pumpHandlerOn(
        tester,
        TargetPlatform.windows,
        onFlush: () async {
          events.add('flush');
          throw StateError('database gone');
        },
      );

      bridge.listener!.onWindowClose();
      await tester.pump();

      expect(events, ['flush', 'destroy']);
    });

    testWidgets('destroys the window when the flush times out', (tester) async {
      await pumpHandlerOn(
        tester,
        TargetPlatform.windows,
        onFlush: () {
          events.add('flush');

          // Nunca completa — só o timeout destrava o fechamento.
          return Completer<void>().future;
        },
        flushTimeout: const Duration(milliseconds: 50),
      );

      bridge.listener!.onWindowClose();
      await tester.pump();

      expect(events, ['flush']);

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();

      expect(events, ['flush', 'destroy']);
    });

    testWidgets('saves the window position before destroying the window', (
      tester,
    ) async {
      bridge.position = const Offset(1280, 240.5);
      await pumpHandlerOn(
        tester,
        TargetPlatform.windows,
        onFlush: () async => events.add('flush'),
        onSavePosition: (x, y) async => events.add('position:$x,$y'),
      );

      bridge.listener!.onWindowClose();
      await tester.pump();

      expect(events, ['flush', 'position:1280.0,240.5', 'destroy']);
    });

    testWidgets('destroys the window even when saving the position throws', (
      tester,
    ) async {
      await pumpHandlerOn(
        tester,
        TargetPlatform.windows,
        onFlush: () async => events.add('flush'),
        onSavePosition: (x, y) async => throw StateError('prefs gone'),
      );

      bridge.listener!.onWindowClose();
      await tester.pump();

      expect(events, ['flush', 'destroy']);
    });

    testWidgets('still saves the position when the flush throws', (
      tester,
    ) async {
      await pumpHandlerOn(
        tester,
        TargetPlatform.windows,
        onFlush: () async => throw StateError('database gone'),
        onSavePosition: (x, y) async => events.add('position'),
      );

      bridge.listener!.onWindowClose();
      await tester.pump();

      expect(events, ['position', 'destroy']);
    });

    testWidgets('does not query the position without a save callback', (
      tester,
    ) async {
      await pumpHandlerOn(
        tester,
        TargetPlatform.windows,
        onFlush: () async => events.add('flush'),
      );

      bridge.listener!.onWindowClose();
      await tester.pump();

      expect(bridge.getPositionCalls, 0);
      expect(events, ['flush', 'destroy']);
    });

    testWidgets('unregisters the listener when disposed', (tester) async {
      await pumpHandlerOn(tester, TargetPlatform.windows, onFlush: () async {});

      expect(bridge.listener, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(bridge.listener, isNull);
    });

    testWidgets('does not register a WindowListener on Android', (
      tester,
    ) async {
      await pumpHandlerOn(
        tester,
        TargetPlatform.android,
        onFlush: () async => events.add('flush'),
      );

      expect(bridge.listener, isNull);
      expect(bridge.preventClose, isNull);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('does not register a WindowListener on iOS', (tester) async {
      await pumpHandlerOn(
        tester,
        TargetPlatform.iOS,
        onFlush: () async => events.add('flush'),
      );

      expect(bridge.listener, isNull);
      expect(bridge.preventClose, isNull);
    });
  });
}
