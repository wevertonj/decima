import 'package:decima/ui/calculator/widgets/blinking_cursor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  group('BlinkingCursor', () {
    testWidgets('renderiza a barra visível com a altura configurada', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const BlinkingCursor(height: 48, color: Colors.amber)),
      );

      final bar = find.descendant(
        of: find.byType(BlinkingCursor),
        matching: find.byType(DecoratedBox),
      );
      expect(bar, findsOneWidget);

      final size = tester.getSize(
        find.descendant(
          of: find.byType(BlinkingCursor),
          matching: find.byType(SizedBox),
        ),
      );
      expect(size.height, 48);
      expect(size.width, 2);
    });

    testWidgets('pisca: some após um período e volta no seguinte', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const BlinkingCursor(height: 48, color: Colors.amber)),
      );

      final bar = find.descendant(
        of: find.byType(BlinkingCursor),
        matching: find.byType(DecoratedBox),
      );
      expect(bar, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 530));
      expect(bar, findsNothing);

      await tester.pump(const Duration(milliseconds: 530));
      expect(bar, findsOneWidget);
    });

    testWidgets('cancela o timer no dispose sem timers pendentes', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const BlinkingCursor(height: 48, color: Colors.amber)),
      );
      await tester.pumpWidget(wrap(const SizedBox.shrink()));

      // O framework de teste falha sozinho se algum Timer ficar pendente.
      expect(find.byType(BlinkingCursor), findsNothing);
    });
  });
}
