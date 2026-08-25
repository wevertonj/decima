import 'package:decima/config/theme/app_colors.dart';
import 'package:decima/config/theme/app_layout.dart';
import 'package:flutter/material.dart';

/// Fileira de círculos coloridos para escolher a seed color, com check na
/// cor selecionada.
class ColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.spacing.medium,
      runSpacing: AppLayout.spacing.medium,
      children: List.generate(
        AppColors.seedColors.length,
        (index) => _ColorCircle(
          color: AppColors.seedColors[index],
          isSelected: index == selectedIndex,
          onTap: () => onChanged(index),
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: isSelected
              ? Icon(
                  Icons.check_rounded,
                  key: const ValueKey('check'),
                  color: _contrastColor(color),
                  size: 20,
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ),
    );
  }

  /// Preto ou branco conforme a luminância de [color].
  Color _contrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
