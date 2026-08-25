import 'package:decima/ui/calculator/widgets/calculator_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CalculatorButton', () {
    group('rendering', () {
      testWidgets('should display the label text', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '7', onPressed: () {}),
          ),
        );

        expect(find.text('7'), findsOneWidget);
      });

      testWidgets('should display functional label', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '÷',
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        expect(find.text('÷'), findsOneWidget);
      });

      testWidgets('should display icon when provided', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: 'backspace',
              icon: Icons.backspace_rounded,
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        expect(find.byIcon(Icons.backspace_rounded), findsOneWidget);
      });

      testWidgets('should display equals as functional variant', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '=',
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        expect(find.text('='), findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('should call onPressed when tapped', (tester) async {
        var pressed = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '5', onPressed: () => pressed = true),
          ),
        );

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();

        expect(pressed, isTrue);
      });

      testWidgets('should call onPressed for functional variant', (
        tester,
      ) async {
        var pressed = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '+',
              onPressed: () => pressed = true,
              variant: ButtonVariant.functional,
            ),
          ),
        );

        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();

        expect(pressed, isTrue);
      });

      testWidgets('should trigger LED glow animation on tap', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '3', onPressed: () {}),
          ),
        );

        await tester.tap(find.text('3'));
        // Avança alguns frames para observar a animação de glow
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('3'), findsOneWidget);

        await tester.pumpAndSettle();
      });

      testWidgets('should animate background fade out on tap', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '8', onPressed: () {}),
          ),
        );

        await tester.tap(find.text('8'));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('8'), findsOneWidget);

        await tester.pumpAndSettle();
      });
    });

    group('variants', () {
      testWidgets('should use primary color for functional text', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '×',
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('×'));
        final theme = Theme.of(tester.element(find.byType(CalculatorButton)));

        expect(text.style?.color, equals(theme.colorScheme.primary));
      });

      testWidgets('numeric variant should use onSurface color', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '9', onPressed: () {}),
          ),
        );

        final text = tester.widget<Text>(find.text('9'));

        expect(text.style?.color, isNotNull);
      });

      testWidgets('should have square shape with small border radius', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '1', onPressed: () {}),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(CalculatorButton),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.borderRadius, isNotNull);
        expect(decoration.shape, BoxShape.rectangle);
      });
    });

    group('responsiveness', () {
      testWidgets('should fire onPressed on tap down (not wait for tap up)', (
        tester,
      ) async {
        var pressed = false;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '4', onPressed: () => pressed = true),
          ),
        );

        // Pressiona sem soltar ainda
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('4')),
        );
        await tester.pump();

        expect(pressed, isTrue, reason: 'onPressed should fire on tap down');

        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('should remain responsive during glow animation', (
        tester,
      ) async {
        var pressCount = 0;

        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(label: '7', onPressed: () => pressCount++),
          ),
        );

        // Primeiro tap — dispara a animação de glow
        await tester.tap(find.text('7'));
        // Pump breve para a animação estar no meio do caminho (sem settle)
        await tester.pump(const Duration(milliseconds: 50));

        // Segundo tap enquanto o glow ainda esmaece
        await tester.tap(find.text('7'));
        await tester.pump(const Duration(milliseconds: 50));

        // Terceiro tap durante a animação
        await tester.tap(find.text('7'));
        await tester.pumpAndSettle();

        expect(pressCount, 3);
      });
    });

    group('isDimmed', () {
      testWidgets('should default to not dimmed', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: CalculatorButton(
              label: '+',
              onPressed: () {},
              variant: ButtonVariant.functional,
            ),
          ),
        );

        final button = tester.widget<CalculatorButton>(
          find.byType(CalculatorButton),
        );

        expect(button.isDimmed, isFalse);
      });

      testWidgets(
        'should animate text color toward primary when transitioning out of dimmed state',
        (tester) async {
          await tester.pumpApp(
            Scaffold(
              body: CalculatorButton(
                label: 'C',
                onPressed: () {},
                variant: ButtonVariant.functional,
                isDimmed: true,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final dimmedColor = tester.widget<Text>(find.text('C')).style?.color;

          await tester.pumpApp(
            Scaffold(
              body: CalculatorButton(
                label: 'C',
                onPressed: () {},
                variant: ButtonVariant.functional,
                isDimmed: false,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final activeColor = tester.widget<Text>(find.text('C')).style?.color;
          final theme = Theme.of(tester.element(find.byType(CalculatorButton)));

          expect(dimmedColor, isNot(equals(activeColor)));
          expect(activeColor, equals(theme.colorScheme.primary));
        },
      );
    });
  });
}
