import 'package:decima/config/theme/app_layout.dart';
import 'package:decima/ui/calculator/widgets/key_flash_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Variantes visuais do botão da calculadora.
/// - [numeric]: dígitos 0-9, 00, 000 — cor onSurface, LED glow branco ao digitar
/// - [functional]: operadores e ações (C, %, ⌫, ÷, ×, −, +, =) — cor primary
enum ButtonVariant { numeric, functional }

class CalculatorButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final ButtonVariant variant;

  /// Quando `true`, um botão [ButtonVariant.functional] usa onSurface
  /// esmaecido no lugar do primary, com transição animada (usado pelo `C`
  /// contextual).
  final bool isDimmed;

  /// Sinal de acionamento por teclado físico. Quando o rótulo notificado é
  /// igual a [label], o botão reproduz a mesma animação de feedback do toque.
  final ValueListenable<KeyFlash?>? keyFlash;

  const CalculatorButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.variant = ButtonVariant.numeric,
    this.isDimmed = false,
    this.keyFlash,
  });

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton>
    with TickerProviderStateMixin {
  // LED glow (reactive typing): acende no tap, apaga em ~600ms.
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  // Flash de fundo: destaque sutil de superfície que some rápido.
  late final AnimationController _bgController;
  late final Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0, // inicia sem glow (totalmente apagado)
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInCubic,
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 40),
      value: 0.0,
    );
    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeOut,
    );

    widget.keyFlash?.addListener(_onKeyFlash);
  }

  @override
  void didUpdateWidget(covariant CalculatorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyFlash != widget.keyFlash) {
      oldWidget.keyFlash?.removeListener(_onKeyFlash);
      widget.keyFlash?.addListener(_onKeyFlash);
    }
  }

  @override
  void dispose() {
    widget.keyFlash?.removeListener(_onKeyFlash);
    _glowController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  /// Reproduz o feedback de um acionamento vindo do teclado físico. Como não
  /// existe "soltar o dedo", o fade out começa imediatamente.
  void _onKeyFlash() {
    if (widget.keyFlash?.value?.label != widget.label) return;

    _glowController.value = 0.0;
    _glowController.forward();
    _bgController.forward().then((_) {
      if (mounted) _bgController.reverse();
    });
  }

  void _handleTapDown(TapDownDetails _) {
    // Despacha IMEDIATAMENTE no toque, sem aguardar tapUp nem animação —
    // nenhum toque se perde em digitação rápida.
    widget.onPressed();

    _glowController.value = 0.0;
    _bgController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _glowController.forward();
    _bgController.reverse();
  }

  void _handleTap() {
    // A ação já foi despachada no tapDown.
  }

  void _handleTapCancel() {
    _glowController.forward();
    _bgController.reverse();
  }

  Color _baseTextColor(ColorScheme colors) {
    if (widget.variant == ButtonVariant.functional) {
      return colors.primary;
    }

    return colors.onSurface;
  }

  Color _dimmedTextColor(ColorScheme colors) {
    return colors.onSurface.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activeBase = _baseTextColor(colors);
    final dimmedBase = _dimmedTextColor(colors);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.isDimmed ? 0.0 : 1.0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.fastOutSlowIn,
      builder: (context, t, _) {
        final baseTextColor = Color.lerp(dimmedBase, activeBase, t)!;

        return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTap: _handleTap,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              // bgAnimation: 0 = apagado, 1 = aceso.
              final bgOpacity = _bgAnimation.value * 0.12;

              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: bgOpacity),
                  borderRadius: BorderRadius.circular(AppLayout.radius.small),
                ),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: widget.icon != null
                ? _buildIconContent(baseTextColor)
                : _buildTextContent(baseTextColor),
          ),
        );
      },
    );
  }

  Widget _buildIconContent(Color baseColor) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        final intensity = 1.0 - _glowAnimation.value;
        final color = Color.lerp(baseColor, Colors.white, intensity)!;

        return Icon(
          widget.icon,
          color: color,
          size: AppLayout.spacing.large,
          shadows: intensity > 0.01
              ? _buildGlowShadows(baseColor, intensity)
              : null,
        );
      },
    );
  }

  Widget _buildTextContent(Color baseColor) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        final intensity = 1.0 - _glowAnimation.value;
        final color = Color.lerp(baseColor, Colors.white, intensity)!;

        return Text(
          widget.label,
          style: TextStyle(
            color: color,
            fontSize: 26.0,
            fontWeight: FontWeight.w400,
            shadows: intensity > 0.01
                ? _buildGlowShadows(baseColor, intensity)
                : null,
          ),
        );
      },
    );
  }

  /// Cria o halo luminoso do LED — duas camadas de sombra (interna focada +
  /// externa difusa) que dão a sensação de luz se apagando gradativamente.
  List<Shadow> _buildGlowShadows(Color baseColor, double intensity) {
    return [
      Shadow(
        color: baseColor.withValues(alpha: intensity * 0.8),
        blurRadius: 16.0 * intensity,
      ),
      Shadow(
        color: baseColor.withValues(alpha: intensity * 0.4),
        blurRadius: 32.0 * intensity,
      ),
    ];
  }
}
