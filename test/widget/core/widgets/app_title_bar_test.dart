import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

import 'package:decima/ui/core/desktop/desktop_window_config.dart';
import 'package:decima/ui/core/widgets/app_logo.dart';
import 'package:decima/ui/core/widgets/app_title_bar.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Widget buildTitleBar({VoidCallback? onMinimize, VoidCallback? onClose}) {
    return Scaffold(
      body: Column(
        children: [AppTitleBar(onMinimize: onMinimize, onClose: onClose)],
      ),
    );
  }

  Color? buttonColor(WidgetTester tester, IconData icon) {
    final container = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.byIcon(icon),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    return (container.decoration as BoxDecoration?)?.color;
  }

  Future<TestGesture> hoverAt(WidgetTester tester, Offset location) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(location);
    await tester.pumpAndSettle();

    return gesture;
  }

  group('AppTitleBar', () {
    testWidgets('renders logo, app name and window buttons', (tester) async {
      await tester.pumpApp(buildTitleBar());

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('Decima'), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('has the configured title bar height', (tester) async {
      await tester.pumpApp(buildTitleBar());

      final size = tester.getSize(find.byType(AppTitleBar));
      expect(size.height, DesktopWindowConfig.titleBarHeight);
    });

    testWidgets('renders a drag-to-move area for the window', (tester) async {
      await tester.pumpApp(buildTitleBar());

      expect(find.byType(DragToMoveArea), findsOneWidget);
    });

    testWidgets('close button fires onClose callback', (tester) async {
      var closeCalled = 0;
      var minimizeCalled = 0;
      await tester.pumpApp(
        buildTitleBar(
          onClose: () => closeCalled++,
          onMinimize: () => minimizeCalled++,
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(closeCalled, 1);
      expect(minimizeCalled, 0);
    });

    testWidgets('minimize button fires onMinimize callback', (tester) async {
      var closeCalled = 0;
      var minimizeCalled = 0;
      await tester.pumpApp(
        buildTitleBar(
          onClose: () => closeCalled++,
          onMinimize: () => minimizeCalled++,
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();

      expect(minimizeCalled, 1);
      expect(closeCalled, 0);
    });

    testWidgets('hover animates the close button background', (tester) async {
      await tester.pumpApp(buildTitleBar());

      final idleColor = buttonColor(tester, Icons.close_rounded);
      expect(idleColor, isNotNull);
      expect(idleColor!.a, 0.0);

      await hoverAt(tester, tester.getCenter(find.byIcon(Icons.close_rounded)));

      final hoveredColor = buttonColor(tester, Icons.close_rounded);
      expect(hoveredColor, isNotNull);
      expect(hoveredColor!.a, greaterThan(0.0));
      expect(hoveredColor, isNot(equals(idleColor)));
    });

    testWidgets('hover animates the minimize button background', (
      tester,
    ) async {
      await tester.pumpApp(buildTitleBar());

      final idleColor = buttonColor(tester, Icons.remove_rounded);
      expect(idleColor, isNotNull);
      expect(idleColor!.a, 0.0);

      await hoverAt(
        tester,
        tester.getCenter(find.byIcon(Icons.remove_rounded)),
      );

      final hoveredColor = buttonColor(tester, Icons.remove_rounded);
      expect(hoveredColor, isNotNull);
      expect(hoveredColor!.a, greaterThan(0.0));
    });

    testWidgets('leaving hover returns the button to idle color', (
      tester,
    ) async {
      await tester.pumpApp(buildTitleBar());

      final gesture = await hoverAt(
        tester,
        tester.getCenter(find.byIcon(Icons.close_rounded)),
      );
      expect(buttonColor(tester, Icons.close_rounded)!.a, greaterThan(0.0));

      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();

      expect(buttonColor(tester, Icons.close_rounded)!.a, 0.0);
    });
  });

  group('AppTitleBar on macOS', () {
    // O binding verifica que debugDefaultTargetPlatformOverride foi
    // restaurado ANTES dos tearDowns — o reset precisa acontecer no corpo
    // do teste, logo após o último pump.
    Future<void> pumpOnMacOS(WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await tester.pumpApp(buildTitleBar());
      debugDefaultTargetPlatformOverride = null;
    }

    testWidgets('hides the custom window buttons', (tester) async {
      await pumpOnMacOS(tester);

      expect(find.byIcon(Icons.remove_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('renders logo and app name centered', (tester) async {
      await pumpOnMacOS(tester);

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('Decima'), findsOneWidget);

      final barCenter = tester.getCenter(find.byType(AppTitleBar)).dx;
      final logoLeft = tester.getTopLeft(find.byType(AppLogo)).dx;
      final titleRight = tester.getTopRight(find.text('Decima')).dx;
      final contentCenter = (logoLeft + titleRight) / 2;
      expect(contentCenter, moreOrLessEquals(barCenter, epsilon: 1.0));
    });

    testWidgets('keeps the drag-to-move area and configured height', (
      tester,
    ) async {
      await pumpOnMacOS(tester);

      expect(find.byType(DragToMoveArea), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppTitleBar)).height,
        DesktopWindowConfig.titleBarHeight,
      );
    });
  });
}
