import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:decima/ui/core/desktop/desktop_window_config.dart';
import 'package:decima/ui/settings/widgets/theme_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ThemeModeSelector', () {
    /// Reproduz a largura útil da janela desktop (fixa em 360px) descontando
    /// o padding lateral da página de configurações.
    final double availableWidth = DesktopWindowConfig.windowSize.width - 48;

    Future<void> pumpSelector(WidgetTester tester, Locale locale) async {
      await tester.pumpApp(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: availableWidth,
              child: ThemeModeSelector(
                selected: ThemeModeOption.system,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
        locale: locale,
      );
    }

    for (final locale in const [Locale('pt'), Locale('en'), Locale('es')]) {
      testWidgets('should not overflow in ${locale.languageCode}', (
        tester,
      ) async {
        await pumpSelector(tester, locale);

        expect(tester.takeException(), isNull);
        expect(find.byType(ThemeModeSelector), findsOneWidget);
      });
    }

    testWidgets('should notify the tapped option', (tester) async {
      ThemeModeOption? tapped;

      await tester.pumpApp(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: availableWidth,
              child: ThemeModeSelector(
                selected: ThemeModeOption.system,
                onChanged: (option) => tapped = option,
              ),
            ),
          ),
        ),
        locale: const Locale('es'),
      );

      await tester.tap(find.byIcon(Icons.dark_mode_rounded));
      await tester.pumpAndSettle();

      expect(tapped, ThemeModeOption.dark);
    });
  });
}
