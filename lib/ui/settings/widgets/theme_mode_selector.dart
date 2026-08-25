import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:decima/ui/widgets/flat_segmented_control.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Seletor plano do modo do tema (claro, escuro, sistema).
class ThemeModeSelector extends StatelessWidget {
  final ThemeModeOption selected;
  final ValueChanged<ThemeModeOption> onChanged;

  const ThemeModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FlatSegmentedControl<ThemeModeOption>(
      value: selected,
      items: ThemeModeOption.values,
      onChanged: onChanged,
      itemBuilder: (option) {
        final String label;
        final IconData icon;

        switch (option) {
          case ThemeModeOption.light:
            label = l10n.themeLight;
            icon = Icons.light_mode_rounded;
            break;
          case ThemeModeOption.dark:
            label = l10n.themeDark;
            icon = Icons.dark_mode_rounded;
            break;
          case ThemeModeOption.system:
            label = l10n.themeSystem;
            icon = Icons.settings_brightness_rounded;
            break;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 4),
            // Flexible + ellipsis: salvaguarda para rótulos longos em
            // qualquer idioma.
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        );
      },
    );
  }
}
