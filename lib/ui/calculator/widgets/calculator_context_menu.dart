import 'package:flutter/material.dart';

import 'package:decima/config/theme/app_layout.dart';
import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';

/// Long-press context menu attached to the calculator display. Exposes
/// copy/paste actions whose visibility is driven by the [viewModel] state.
///
/// The menu animates in via a smooth fade + scale and dismisses on outside
/// tap, item selection, or back gesture.
class CalculatorContextMenu {
  CalculatorContextMenu._();

  /// Opens the context menu anchored at [position] (global coordinates).
  ///
  /// Returns once the menu closes. Snackbars for paste failures are shown
  /// using the closest [ScaffoldMessenger] to [context].
  static Future<void> show({
    required BuildContext context,
    required CalculatorViewModel viewModel,
    required Offset position,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox = overlay.context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final relative = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      size.width - position.dx,
      size.height - position.dy,
    );

    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    final canPaste = await _clipboardHasText(viewModel);

    if (!context.mounted) return;

    final selected = await showMenu<_MenuAction>(
      context: context,
      position: relative,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radius.large),
      ),
      items: [
        if (viewModel.hasExpression)
          PopupMenuItem(
            value: _MenuAction.copyExpression,
            child: _MenuRow(
              icon: Icons.content_copy_rounded,
              label: l10n.copyExpression,
            ),
          ),
        if (viewModel.hasResult)
          PopupMenuItem(
            value: _MenuAction.copyResult,
            child: _MenuRow(
              icon: Icons.content_copy_rounded,
              label: l10n.copyResult,
            ),
          ),
        if (viewModel.hasHistory)
          PopupMenuItem(
            value: _MenuAction.copyHistory,
            child: _MenuRow(
              icon: Icons.content_copy_rounded,
              label: l10n.copyHistory,
            ),
          ),
        PopupMenuItem(
          value: _MenuAction.paste,
          enabled: canPaste,
          child: _MenuRow(
            icon: Icons.content_paste_rounded,
            label: l10n.paste,
            enabled: canPaste,
          ),
        ),
      ],
    );

    if (selected == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);

    switch (selected) {
      case _MenuAction.copyExpression:
        await viewModel.copyExpression();
        _showSnack(messenger, l10n.copied);
      case _MenuAction.copyResult:
        await viewModel.copyResult();
        _showSnack(messenger, l10n.copied);
      case _MenuAction.copyHistory:
        await viewModel.copyHistory();
        _showSnack(messenger, l10n.copied);
      case _MenuAction.paste:
        final ok = await viewModel.pasteFromClipboard();
        if (!ok) _showSnack(messenger, l10n.pasteInvalid);
    }
  }

  static Future<bool> _clipboardHasText(CalculatorViewModel viewModel) async {
    // Avoid synchronous platform reads during build by deferring the menu
    // construction to whoever calls `show`. The menu enables paste based on
    // a quick clipboard probe via the view model — null means empty.
    return viewModel.clipboardHasText();
  }

  static void _showSnack(ScaffoldMessengerState? messenger, String message) {
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum _MenuAction { copyExpression, copyResult, copyHistory, paste }

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = enabled
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: AppLayout.spacing.small),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
