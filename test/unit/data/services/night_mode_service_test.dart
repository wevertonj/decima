import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decima/data/services/night_mode_service.dart';
import 'package:decima/data/services/night_mode_service_impl.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.wevasoft.decima/night_mode');

  late NightModeService service;
  MethodCall? lastCall;

  setUp(() {
    lastCall = null;
    service = NightModeServiceImpl();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          lastCall = call;

          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NightModeServiceImpl', () {
    test('should sync dark=true for ThemeModeOption.dark', () async {
      await service.syncThemeMode(ThemeModeOption.dark);

      expect(lastCall?.method, 'setApplicationNightMode');
      expect(lastCall?.arguments, {'dark': true});
    });

    test('should sync dark=false for ThemeModeOption.light', () async {
      await service.syncThemeMode(ThemeModeOption.light);

      expect(lastCall?.arguments, {'dark': false});
    });

    test(
      'should resolve ThemeModeOption.system using platform brightness '
      '(dark)',
      () async {
        final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
        dispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(dispatcher.clearPlatformBrightnessTestValue);

        await service.syncThemeMode(ThemeModeOption.system);

        expect(lastCall?.arguments, {'dark': true});
      },
    );

    test(
      'should resolve ThemeModeOption.system using platform brightness '
      '(light)',
      () async {
        final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
        dispatcher.platformBrightnessTestValue = Brightness.light;
        addTearDown(dispatcher.clearPlatformBrightnessTestValue);

        await service.syncThemeMode(ThemeModeOption.system);

        expect(lastCall?.arguments, {'dark': false});
      },
    );

    test('should be a no-op on unsupported platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await service.syncThemeMode(ThemeModeOption.dark);

      expect(lastCall, isNull);
    });

    test('should swallow PlatformException from the channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'error');
          });

      await expectLater(
        service.syncThemeMode(ThemeModeOption.dark),
        completes,
      );
    });

    test('should swallow MissingPluginException when unhandled', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      await expectLater(
        service.syncThemeMode(ThemeModeOption.dark),
        completes,
      );
    });
  });
}
