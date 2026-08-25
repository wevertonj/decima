import 'package:decima/ui/calculator/widgets/animated_input_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// Regressão do bug de deslocamento vertical no Windows: caracteres que
/// passaram por animação de roll ficavam presos em uma caixa de altura
/// `fontSize * 1.2`, deslocando o glifo verticalmente em fontes cuja
/// line-height difere desse fator (ex: Segoe UI ≈ 1.33). A fonte de teste
/// do Flutter tem line-height = fontSize, expondo o mesmo descolamento.
void main() {
  Widget buildDisplay(String text) {
    return Scaffold(
      body: Center(
        child: AnimatedInputDisplay(
          text: text,
          textColor: Colors.white,
          operatorColor: Colors.blue,
        ),
      ),
    );
  }

  /// Centros verticais (dy global) de todos os caracteres visíveis do
  /// display — ignora os chars antigos das animações de roll (opacity 0).
  List<double> visibleCharCenters(WidgetTester tester) {
    final centers = <double>[];
    final elements = find
        .descendant(
          of: find.byType(AnimatedInputDisplay),
          matching: find.byType(RichText),
        )
        .evaluate();

    for (final element in elements) {
      var opacity = 1.0;
      element.visitAncestorElements((ancestor) {
        final w = ancestor.widget;
        if (w is Opacity) opacity *= w.opacity;

        return w is! AnimatedInputDisplay;
      });
      if (opacity < 0.5) continue;

      final box = element.renderObject! as RenderBox;
      centers.add(box.localToGlobal(box.size.center(Offset.zero)).dy);
    }

    return centers;
  }

  void expectAligned(List<double> centers) {
    expect(centers, isNotEmpty);
    final first = centers.first;
    for (final dy in centers) {
      expect(
        (dy - first).abs(),
        lessThan(0.5),
        reason: 'caracteres desalinhados verticalmente: $centers',
      );
    }
  }

  group('AnimatedInputDisplay — alinhamento vertical', () {
    testWidgets('chars após roll ficam alinhados aos estáticos', (
      tester,
    ) async {
      await tester.pumpApp(buildDisplay('0.10'));
      // Atualização que gera rolls no meio + popIn + sufixo estático
      // (mesmo diff de uma digitação com frames coalescidos).
      await tester.pumpApp(buildDisplay('10.00'));

      expectAligned(visibleCharCenters(tester));
    });

    testWidgets('digitação Add2 passo a passo mantém alinhamento', (
      tester,
    ) async {
      await tester.pumpApp(buildDisplay('0.00'));
      for (final text in ['0.01', '0.10', '1.00', '10.00', '100.00']) {
        await tester.pumpApp(buildDisplay(text));
      }

      expectAligned(visibleCharCenters(tester));
    });

    testWidgets('expressão com operador mantém alinhamento após rolls', (
      tester,
    ) async {
      await tester.pumpApp(buildDisplay('12.34'));
      await tester.pumpApp(buildDisplay('12.34 + 0.05'));
      await tester.pumpApp(buildDisplay('12.34 + 0.56'));

      expectAligned(visibleCharCenters(tester));
    });

    testWidgets('slots animados decaem para texto puro após a animação', (
      tester,
    ) async {
      // Roll + popIn no meio do texto (diff de digitação coalescida).
      await tester.pumpApp(buildDisplay('0.10'));
      await tester.pumpApp(buildDisplay('10.00'));

      // Com as animações concluídas, nenhum wrapper (ClipRect dos chars
      // de roll/popIn) pode permanecer abaixo da Row de caracteres — o
      // estado de repouso é 100% texto puro, imune a diferenças de
      // métrica de fonte (ex: Segoe UI no Windows deslocava o glifo em
      // ~3px). O ClipRect do próprio Scrollable fica ACIMA da Row e não
      // conta.
      final charRow = find.descendant(
        of: find.byType(AnimatedInputDisplay),
        matching: find.byType(Row),
      );
      expect(charRow, findsOneWidget);
      expect(
        find.descendant(of: charRow, matching: find.byType(ClipRect)),
        findsNothing,
      );

      // E cada char visível aparece exatamente uma vez (os chars antigos
      // dos rolls foram removidos junto com o wrapper).
      final texts = find
          .descendant(
            of: find.byType(AnimatedInputDisplay),
            matching: find.byType(RichText),
          )
          .evaluate()
          .map((e) => (e.widget as RichText).text.toPlainText())
          .toList();
      expect(texts.join(), '10.00');
    });
  });
}
