import 'package:decima/ui/history/widgets/animated_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  double fadeOpacity(WidgetTester tester) {
    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(AnimatedListItem),
        matching: find.byType(FadeTransition),
      ),
    );

    return fade.opacity.value;
  }

  group('AnimatedListItem', () {
    testWidgets('começa invisível e termina totalmente visível', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AnimatedListItem(index: 0, child: Text('item'))),
      );

      expect(fadeOpacity(tester), 0.0);

      await tester.pumpAndSettle();

      expect(fadeOpacity(tester), 1.0);
      final slide = tester.widget<SlideTransition>(
        find.descendant(
          of: find.byType(AnimatedListItem),
          matching: find.byType(SlideTransition),
        ),
      );
      expect(slide.position.value, Offset.zero);
    });

    testWidgets('stagger: item de índice maior começa depois', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              AnimatedListItem(index: 0, child: Text('primeiro')),
              AnimatedListItem(index: 3, child: Text('quarto')),
            ],
          ),
        ),
      );

      double opacityOf(String text) {
        final item = find.ancestor(
          of: find.text(text),
          matching: find.byType(AnimatedListItem),
        );

        return tester
            .widget<FadeTransition>(
              find.descendant(of: item, matching: find.byType(FadeTransition)),
            )
            .opacity
            .value;
      }

      // Após o delay do índice 0 (0 ms) + dois frames (o controller só
      // ancora o tempo no primeiro tick), o primeiro já anima enquanto o
      // quarto (delay 120 ms) segue invisível.
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 30));

      expect(opacityOf('primeiro'), greaterThan(0.0));
      expect(opacityOf('quarto'), 0.0);

      await tester.pumpAndSettle();
      expect(opacityOf('primeiro'), 1.0);
      expect(opacityOf('quarto'), 1.0);
    });

    testWidgets('índice alto tem o delay limitado pelo clamp', (tester) async {
      await tester.pumpWidget(
        wrap(const AnimatedListItem(index: 99, child: Text('fundo'))),
      );

      // Clamp em 10 → delay máximo de 400 ms.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));

      expect(fadeOpacity(tester), 1.0);
    });

    testWidgets('renderiza o child', (tester) async {
      await tester.pumpWidget(
        wrap(const AnimatedListItem(index: 0, child: Text('conteúdo'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('conteúdo'), findsOneWidget);
    });
  });
}
