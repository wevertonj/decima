import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/ui/widgets/flat_segmented_control.dart';
import 'package:flutter/material.dart';

/// A flat selector for the decimal separator (dot or comma).
class DecimalSeparatorSelector extends StatelessWidget {
  final DecimalSeparator selected;
  final ValueChanged<DecimalSeparator> onChanged;

  const DecimalSeparatorSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FlatSegmentedControl<DecimalSeparator>(
      value: selected,
      items: DecimalSeparator.values,
      onChanged: onChanged,
      itemBuilder: (option) {
        return Text(option == DecimalSeparator.dot ? '1,000.00' : '1.000,00');
      },
    );
  }
}
