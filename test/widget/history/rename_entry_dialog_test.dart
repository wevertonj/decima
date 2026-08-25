import 'package:decima/ui/history/widgets/rename_entry_dialog.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<Future<String?>> openDialog(
    WidgetTester tester, {
    String? initialName,
  }) async {
    Future<String?>? result;

    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              result = RenameEntryDialog.show(
                context,
                initialName: initialName,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return result!;
  }

  group('RenameEntryDialog', () {
    testWidgets('exibe o nome inicial no campo de texto', (tester) async {
      final result = await openDialog(tester, initialName: 'Compras');

      expect(find.widgetWithText(TextField, 'Compras'), findsOneWidget);

      // Fecha para não deixar o future pendente.
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await result;
    });

    testWidgets('cancelar devolve null', (tester) async {
      final result = await openDialog(tester);

      final l10n = tester.element(find.byType(AlertDialog)).l10n;
      await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
      await tester.pumpAndSettle();

      expect(await result, isNull);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('salvar devolve o texto digitado', (tester) async {
      final result = await openDialog(tester);

      await tester.enterText(find.byType(TextField), 'Mercado');
      final l10n = tester.element(find.byType(AlertDialog)).l10n;
      await tester.tap(find.widgetWithText(FilledButton, l10n.renameSave));
      await tester.pumpAndSettle();

      expect(await result, 'Mercado');
    });

    testWidgets('salvar com campo vazio devolve string vazia', (tester) async {
      final result = await openDialog(tester, initialName: 'Antigo');

      await tester.enterText(find.byType(TextField), '');
      final l10n = tester.element(find.byType(AlertDialog)).l10n;
      await tester.tap(find.widgetWithText(FilledButton, l10n.renameSave));
      await tester.pumpAndSettle();

      expect(await result, '');
    });

    testWidgets('submeter pelo teclado devolve o texto', (tester) async {
      final result = await openDialog(tester);

      await tester.enterText(find.byType(TextField), 'Viagem');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(await result, 'Viagem');
    });
  });
}
