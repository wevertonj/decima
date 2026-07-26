import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:wevacalc/config/theme/app_layout.dart';
import 'package:wevacalc/ui/calculator/widgets/calculator_button.dart';
import 'package:wevacalc/ui/calculator/widgets/key_flash_controller.dart';

class CalculatorKeypad extends StatelessWidget {
  /// Rótulos dos botões não numéricos. Compartilhados com o
  /// `KeyboardShortcutsHandler`, que os usa para acender o botão equivalente
  /// quando a ação vem do teclado físico.
  static const String clearLabel = 'C';
  static const String percentLabel = '%';
  static const String parenthesisLabel = '( )';
  static const String equalsLabel = '=';
  static const String doubleZeroLabel = '00';
  static const String tripleZeroLabel = '000';

  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onEquals;
  final VoidCallback onClear;
  final VoidCallback onParenthesis;
  final VoidCallback onPercent;
  final VoidCallback onDoubleZero;
  final VoidCallback onTripleZero;

  /// Sinal de acionamento por teclado físico. Cada botão reproduz sua própria
  /// animação de feedback quando o rótulo notificado é o seu.
  final ValueListenable<KeyFlash?>? keyFlash;

  const CalculatorKeypad({
    super.key,
    required this.onDigit,
    required this.onOperator,
    required this.onEquals,
    required this.onClear,
    required this.onParenthesis,
    required this.onPercent,
    required this.onDoubleZero,
    required this.onTripleZero,
    this.keyFlash,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppLayout.padding.medium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow([
            _action(clearLabel, onClear),
            _action(percentLabel, onPercent),
            _action(parenthesisLabel, onParenthesis),
            _operator('÷'),
          ]),
          SizedBox(height: AppLayout.spacing.small),
          _buildRow([
            _numeric('7'),
            _numeric('8'),
            _numeric('9'),
            _operator('×'),
          ]),
          SizedBox(height: AppLayout.spacing.small),
          _buildRow([
            _numeric('4'),
            _numeric('5'),
            _numeric('6'),
            _operator('−'),
          ]),
          SizedBox(height: AppLayout.spacing.small),
          _buildRow([
            _numeric('1'),
            _numeric('2'),
            _numeric('3'),
            _operator('+'),
          ]),
          SizedBox(height: AppLayout.spacing.small),
          _buildRow([
            _numeric(tripleZeroLabel, onPressed: onTripleZero),
            _numeric(doubleZeroLabel, onPressed: onDoubleZero),
            _numeric('0'),
            _equals(),
          ]),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  Widget _numeric(String label, {VoidCallback? onPressed}) {
    return CalculatorButton(
      label: label,
      variant: ButtonVariant.numeric,
      keyFlash: keyFlash,
      onPressed: onPressed ?? () => onDigit(label),
    );
  }

  Widget _operator(String symbol) {
    return CalculatorButton(
      label: symbol,
      variant: ButtonVariant.functional,
      keyFlash: keyFlash,
      onPressed: () => onOperator(symbol),
    );
  }

  Widget _action(
    String label,
    VoidCallback onPressed, {
    bool isDimmed = false,
  }) {
    return CalculatorButton(
      label: label,
      variant: ButtonVariant.functional,
      isDimmed: isDimmed,
      keyFlash: keyFlash,
      onPressed: onPressed,
    );
  }

  Widget _equals() {
    return CalculatorButton(
      label: equalsLabel,
      variant: ButtonVariant.functional,
      keyFlash: keyFlash,
      onPressed: onEquals,
    );
  }
}
