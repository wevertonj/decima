import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:decima/config/theme/app_layout.dart';
import 'package:decima/ui/core/desktop/desktop_window_config.dart';
import 'package:decima/ui/core/widgets/app_logo.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';

/// Barra de título customizada para plataformas desktop.
///
/// Substitui a barra do sistema (oculta via `TitleBarStyle.hidden`):
/// logo + nome do app à esquerda em uma área arrastável, botões de
/// minimizar e fechar à direita. Sem botão de maximizar — a janela
/// tem tamanho fixo.
class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key, this.onMinimize, this.onClose});

  /// Callback do botão minimizar. Quando null, minimiza via [windowManager].
  final VoidCallback? onMinimize;

  /// Callback do botão fechar. Quando null, fecha via [windowManager].
  final VoidCallback? onClose;

  static const double _logoSize = 20.0;
  static const double _iconSize = 18.0;
  static const double _buttonWidth = 46.0;
  static const Duration _animationDuration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SizedBox(
        height: DesktopWindowConfig.titleBarHeight,
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                child: Row(
                  children: [
                    SizedBox(width: AppLayout.padding.medium),
                    const AppLogo(size: _logoSize),
                    SizedBox(width: AppLayout.spacing.small),
                    Text(
                      context.l10n.appTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _TitleBarButton(
              icon: Icons.remove_rounded,
              onPressed: onMinimize ?? windowManager.minimize,
              idleIconColor: colorScheme.onSurface.withValues(alpha: 0.7),
              hoverIconColor: colorScheme.onSurface,
              hoverBackgroundColor:
                  colorScheme.onSurface.withValues(alpha: 0.08),
              pressedBackgroundColor:
                  colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            _TitleBarButton(
              icon: Icons.close_rounded,
              onPressed: onClose ?? windowManager.close,
              idleIconColor: colorScheme.onSurface.withValues(alpha: 0.7),
              hoverIconColor: colorScheme.onError,
              hoverBackgroundColor: colorScheme.error,
              pressedBackgroundColor: colorScheme.error.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão da title bar com feedback animado de hover e press.
class _TitleBarButton extends StatefulWidget {
  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    required this.idleIconColor,
    required this.hoverIconColor,
    required this.hoverBackgroundColor,
    required this.pressedBackgroundColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color idleIconColor;
  final Color hoverIconColor;
  final Color hoverBackgroundColor;
  final Color pressedBackgroundColor;

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hovered = false;
  bool _pressed = false;

  Color get _backgroundColor {
    if (_pressed) return widget.pressedBackgroundColor;
    if (_hovered) return widget.hoverBackgroundColor;

    return Colors.transparent;
  }

  Color get _iconColor {
    if (_hovered || _pressed) return widget.hoverIconColor;

    return widget.idleIconColor;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTitleBar._animationDuration,
          curve: Curves.easeOutCubic,
          width: AppTitleBar._buttonWidth,
          height: double.infinity,
          color: _backgroundColor,
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: _iconColor),
              duration: AppTitleBar._animationDuration,
              curve: Curves.easeOutCubic,
              builder: (context, color, _) {
                return Icon(
                  widget.icon,
                  size: AppTitleBar._iconSize,
                  color: color,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
