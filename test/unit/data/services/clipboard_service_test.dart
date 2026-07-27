import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decima/data/services/clipboard_service.dart';
import 'package:decima/data/services/clipboard_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClipboardService service;
  String? clipboardData;

  setUp(() {
    clipboardData = null;
    service = ClipboardServiceImpl();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardData = (call.arguments as Map)['text'] as String?;

            return null;
          }
          if (call.method == 'Clipboard.getData') {
            if (clipboardData == null) return null;

            return <String, dynamic>{'text': clipboardData};
          }

          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('ClipboardServiceImpl', () {
    test('should write text to system clipboard', () async {
      await service.copyText('hello');

      expect(clipboardData, equals('hello'));
    });

    test('should read text from system clipboard', () async {
      clipboardData = 'world';

      final result = await service.readText();

      expect(result, equals('world'));
    });

    test('should return null when clipboard is empty', () async {
      final result = await service.readText();

      expect(result, isNull);
    });

    test('should return null when clipboard text is empty string', () async {
      clipboardData = '';

      final result = await service.readText();

      expect(result, isNull);
    });
  });
}
