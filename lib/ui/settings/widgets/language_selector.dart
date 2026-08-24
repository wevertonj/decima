import 'package:decima/config/theme/app_layout.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// A selector for the app language. Offers English, Portuguese, Spanish,
/// and a "System" option that follows the device locale.
class LanguageSelector extends StatelessWidget {
  /// The currently selected locale code, or null for system default.
  final String? selected;
  final ValueChanged<String?> onChanged;

  const LanguageSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    final options = <_LanguageOption>[
      _LanguageOption(code: null, label: l10n.languageSystem),
      _LanguageOption(code: 'en', label: l10n.languageEnglish),
      _LanguageOption(code: 'pt', label: l10n.languagePortuguese),
      _LanguageOption(code: 'es', label: l10n.languageSpanish),
    ];

    return Wrap(
      spacing: AppLayout.spacing.small,
      runSpacing: AppLayout.spacing.small,
      children: options.map((option) {
        final isSelected = selected == option.code;

        return GestureDetector(
          onTap: () {
            if (!isSelected) onChanged(option.code);
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.padding.medium,
              vertical: AppLayout.padding.small,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.surfaceContainerHighest.withValues(alpha: 0.8)
                  : colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppLayout.radius.circular),
              border: Border.all(
                color: isSelected
                    ? colors.onSurface.withValues(alpha: 0.1)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_rounded, size: 16, color: colors.onSurface),
                  const SizedBox(width: 6),
                ],
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: isSelected
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.6),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                  child: Text(option.label),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LanguageOption {
  final String? code;
  final String label;

  const _LanguageOption({required this.code, required this.label});
}
