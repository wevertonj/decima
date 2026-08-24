import 'dart:ui' show AppExitResponse;

import 'package:decima/ui/core/mobile/app_lifecycle_flush_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  // A plataforma só é lida no initState — o override é resetado logo após o
  // pump, como em window_close_handler_test.
  Future<void> pumpHandlerOn(
    WidgetTester tester,
    TargetPlatform platform, {
    required Future<void> Function() onFlush,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    await tester.pumpApp(
      AppLifecycleFlushHandler(
        onFlush: onFlush,
        child: const Scaffold(body: Center(child: Text('content'))),
      ),
    );
    debugDefaultTargetPlatformOverride = null;
  }

  /// Volta a `resumed` respeitando a máquina de estados do
  /// [AppLifecycleListener] (só aceita transições adjacentes).
  Future<void> restoreLifecycle(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  group('AppLifecycleFlushHandler', () {
    testWidgets('renderiza o child', (tester) async {
      await pumpHandlerOn(tester, TargetPlatform.android, onFlush: () async {});

      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('em mobile faz flush ao ir para segundo plano', (tester) async {
      var flushCalls = 0;
      await pumpHandlerOn(
        tester,
        TargetPlatform.android,
        onFlush: () async => flushCalls++,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(flushCalls, greaterThan(0));
      await restoreLifecycle(tester);
    });

    testWidgets('em mobile faz flush no pedido de saída', (tester) async {
      var flushCalls = 0;
      await pumpHandlerOn(
        tester,
        TargetPlatform.android,
        onFlush: () async => flushCalls++,
      );

      final response = await tester.binding.handleRequestAppExit();

      expect(flushCalls, 1);
      expect(response, AppExitResponse.exit);
    });

    testWidgets('em desktop não registra listener nem faz flush', (
      tester,
    ) async {
      var flushCalls = 0;
      await pumpHandlerOn(
        tester,
        TargetPlatform.windows,
        onFlush: () async => flushCalls++,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.binding.handleRequestAppExit();

      expect(flushCalls, 0);
      await restoreLifecycle(tester);
    });
  });
}
