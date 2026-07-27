import 'package:flutter/material.dart';

/// Widget que exibe o logo do Decima a partir do asset de branding.
///
/// Usa [Image.asset] para que o Flutter resolva automaticamente a variante
/// de densidade correta (1.0x, 2.0x, 3.0x) de acordo com o [devicePixelRatio].
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size});

  /// Tamanho padrão do logo quando nenhum [size] é fornecido.
  static const double defaultSize = 48.0;

  /// Tamanho (largura e altura) do logo em pixels lógicos.
  /// Se não fornecido, usa [defaultSize].
  final double? size;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? defaultSize;

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Image.asset(
        'assets/branding/logo.png',
        width: dimension,
        height: dimension,
        fit: BoxFit.contain,
      ),
    );
  }
}
