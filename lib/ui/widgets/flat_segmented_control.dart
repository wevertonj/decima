import 'package:decima/config/theme/app_layout.dart';
import 'package:flutter/material.dart';

/// Segmented control plano inspirado no One UI: animações suaves, sem
/// bordas duras.
class FlatSegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final Widget Function(T) itemBuilder;

  const FlatSegmentedControl({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final int selectedIndex = items.indexOf(value);

    // Alinhamento: -1.0 = extrema esquerda, 1.0 = extrema direita.
    final double alignmentX = items.length <= 1
        ? 0.0
        : -1.0 + (selectedIndex * 2.0 / (items.length - 1));

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppLayout.radius.circular),
      ),
      padding: EdgeInsets.all(AppLayout.padding.xs),
      child: Stack(
        children: [
          // Pílula de fundo deslizante.
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: Alignment(alignmentX, 0),
              child: FractionallySizedBox(
                widthFactor: 1.0 / items.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(
                      AppLayout.radius.circular,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              final isSelected = item == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isSelected) onChanged(item);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    // Transparente para a área de toque preencher o espaço.
                    color: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      vertical: AppLayout.padding.small,
                      horizontal: AppLayout.padding.medium,
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          color: isSelected
                              ? colors.onSurface
                              : colors.onSurface.withValues(alpha: 0.5),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                        child: IconTheme(
                          data: IconThemeData(
                            color: isSelected
                                ? colors.onSurface
                                : colors.onSurface.withValues(alpha: 0.5),
                            size: 18,
                          ),
                          child: itemBuilder(item),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
