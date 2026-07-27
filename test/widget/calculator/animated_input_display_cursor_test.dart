import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decima/ui/calculator/widgets/animated_input_display.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, height: 100, child: child)),
  );

  group('AnimatedInputDisplay cursor', () {
    testWidgets('does not render cursor when cursorPosition is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AnimatedInputDisplay(
            text: '12.50',
            textColor: Colors.white,
            operatorColor: Colors.blue,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('display-cursor')), findsNothing);
    });

    testWidgets('renders cursor when cursorPosition is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AnimatedInputDisplay(
            text: '12.50',
            textColor: Colors.white,
            operatorColor: Colors.blue,
            cursorPosition: 2,
            cursorColor: Colors.amber,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('display-cursor')), findsOneWidget);
    });

    testWidgets('invokes onCharTap with the tapped character index', (
      tester,
    ) async {
      var tappedIndex = -1;
      await tester.pumpWidget(
        wrap(
          AnimatedInputDisplay(
            text: '12.50',
            textColor: Colors.white,
            operatorColor: Colors.blue,
            cursorPosition: 5,
            cursorColor: Colors.amber,
            onCharTap: (i) => tappedIndex = i,
          ),
        ),
      );

      // Tap the first character (index 0).
      final firstChar = find.byType(GestureDetector).first;
      await tester.tap(firstChar);
      await tester.pump();

      expect(tappedIndex, 0);
    });

    testWidgets('renders cursor in multiline mode', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AnimatedInputDisplay(
            text: '12.50 + 34.00',
            textColor: Colors.white,
            operatorColor: Colors.blue,
            cursorPosition: 5,
            cursorColor: Colors.amber,
            multiline: true,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('display-cursor')), findsOneWidget);
    });

    testWidgets('renders cursor at end of text in multiline mode', (
      tester,
    ) async {
      const text = '12.50 + 34.00';
      await tester.pumpWidget(
        wrap(
          const AnimatedInputDisplay(
            text: text,
            textColor: Colors.white,
            operatorColor: Colors.blue,
            cursorPosition: text.length,
            cursorColor: Colors.amber,
            multiline: true,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('display-cursor')), findsOneWidget);
    });
  });
}
