import 'package:decima/ui/core/widgets/app_title_bar.dart';
import 'package:decima/ui/core/widgets/desktop_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  const content = Scaffold(body: Center(child: Text('content')));

  // O binding verifica que debugDefaultTargetPlatformOverride foi restaurado
  // ANTES dos tearDowns — o reset precisa acontecer no corpo do teste,
  // logo após o último pump.
  Future<void> pumpShellOn(WidgetTester tester, TargetPlatform platform) async {
    debugDefaultTargetPlatformOverride = platform;
    await tester.pumpApp(const DesktopShell(child: content));
    debugDefaultTargetPlatformOverride = null;
  }

  group('DesktopShell', () {
    group('isDesktop', () {
      tearDown(() {
        debugDefaultTargetPlatformOverride = null;
      });

      test('is true on Windows, Linux and macOS', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        expect(DesktopShell.isDesktop, isTrue);

        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        expect(DesktopShell.isDesktop, isTrue);

        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        expect(DesktopShell.isDesktop, isTrue);
      });

      test('is false on Android and iOS', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        expect(DesktopShell.isDesktop, isFalse);

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        expect(DesktopShell.isDesktop, isFalse);
      });
    });

    testWidgets('wraps content with AppTitleBar on Windows', (tester) async {
      await pumpShellOn(tester, TargetPlatform.windows);

      expect(find.byType(AppTitleBar), findsOneWidget);
      expect(find.text('content'), findsOneWidget);

      final titleBarBottom = tester.getBottomLeft(find.byType(AppTitleBar)).dy;
      final contentTop = tester.getTopLeft(find.byType(Scaffold)).dy;
      expect(contentTop, greaterThanOrEqualTo(titleBarBottom));
    });

    testWidgets('wraps content with AppTitleBar on Linux', (tester) async {
      await pumpShellOn(tester, TargetPlatform.linux);

      expect(find.byType(AppTitleBar), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('wraps content with AppTitleBar on macOS', (tester) async {
      await pumpShellOn(tester, TargetPlatform.macOS);

      expect(find.byType(AppTitleBar), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('does not add AppTitleBar on Android', (tester) async {
      await pumpShellOn(tester, TargetPlatform.android);

      expect(find.byType(AppTitleBar), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('does not add AppTitleBar on iOS', (tester) async {
      await pumpShellOn(tester, TargetPlatform.iOS);

      expect(find.byType(AppTitleBar), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
