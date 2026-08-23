import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decima/ui/core/desktop/window_close_handler.dart';

/// Canal do plugin `window_manager`, espionado para verificar por qual
/// caminho nativo o fechamento passa em cada plataforma.
const MethodChannel _channel = MethodChannel('window_manager');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);

          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('WindowManagerCloseBridge.destroy', () {
    test('closes through the native WM_CLOSE path on Windows', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await const WindowManagerCloseBridge().destroy();

      // `destroy` no Windows é só `PostQuitMessage(0)` e deixaria a janela na
      // tela durante o desligamento do engine.
      expect(calls.map((call) => call.method), ['setPreventClose', 'close']);
      expect(
        (calls.first.arguments as Map)['isPreventClose'],
        isFalse,
        reason:
            'sem desligar o preventClose o WM_CLOSE seria interceptado '
            'de novo e a janela nunca fecharia',
      );
    });

    test('calls destroy directly on Linux', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await const WindowManagerCloseBridge().destroy();

      expect(calls.map((call) => call.method), ['destroy']);
    });

    test('calls destroy directly on macOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      await const WindowManagerCloseBridge().destroy();

      expect(calls.map((call) => call.method), ['destroy']);
    });
  });
}
