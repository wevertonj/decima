import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decima/utils/platform_info.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('PlatformInfo.isDesktop', () {
    test('is true on Windows, Linux and macOS', () {
      for (final platform in [
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      ]) {
        debugDefaultTargetPlatformOverride = platform;

        expect(PlatformInfo.isDesktop, isTrue, reason: '$platform');
      }
    });

    test('is false on Android, iOS and Fuchsia', () {
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.fuchsia,
      ]) {
        debugDefaultTargetPlatformOverride = platform;

        expect(PlatformInfo.isDesktop, isFalse, reason: '$platform');
      }
    });
  });

  group('PlatformInfo.isLinux', () {
    test('is true on Linux', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      expect(PlatformInfo.isLinux, isTrue);
    });

    test('is false on the other desktop platforms', () {
      for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
        debugDefaultTargetPlatformOverride = platform;

        expect(PlatformInfo.isLinux, isFalse, reason: '$platform');
      }
    });

    test('is false on mobile', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;

        expect(PlatformInfo.isLinux, isFalse, reason: '$platform');
      }
    });
  });
}
