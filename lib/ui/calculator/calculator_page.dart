import 'package:flutter/material.dart';

import 'package:wevacalc/config/routes.dart';
import 'package:wevacalc/config/theme/app_layout.dart';
import 'package:wevacalc/domain/entities/history_selection.dart';
import 'package:wevacalc/ui/calculator/calculator_view_model.dart';
import 'package:wevacalc/ui/calculator/widgets/calculator_context_menu.dart';
import 'package:wevacalc/ui/calculator/widgets/calculator_keypad.dart';
import 'package:wevacalc/ui/calculator/widgets/key_flash_controller.dart';
import 'package:wevacalc/ui/calculator/widgets/keyboard_shortcuts_handler.dart';
import 'package:wevacalc/ui/calculator/widgets/timeline_display.dart';
import 'package:wevacalc/utils/extensions/l10n_extension.dart';

class CalculatorPage extends StatefulWidget {
  final CalculatorViewModel viewModel;

  const CalculatorPage({super.key, required this.viewModel});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  late final TextEditingController _displayController;

  /// Ponte entre o teclado físico e o feedback visual do keypad — cada tecla
  /// reconhecida acende o botão equivalente.
  final KeyFlashController _keyFlash = KeyFlashController();

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController(
      text: widget.viewModel.fullDisplayText,
    );
    widget.viewModel.addListener(_onViewModelChanged);
    widget.viewModel.loadSettings();
  }

  @override
  void didUpdateWidget(covariant CalculatorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _displayController.dispose();
    _keyFlash.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final text = widget.viewModel.fullDisplayText;
    final oldText = _displayController.text;
    final oldOffset = _displayController.selection.baseOffset;

    if (oldText != text) {
      // Calculate new cursor position based on the diff
      final lengthDiff = text.length - oldText.length;
      final newOffset = (oldOffset + lengthDiff).clamp(0, text.length);

      _displayController.text = text;
      _displayController.selection = TextSelection.collapsed(offset: newOffset);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vm = widget.viewModel;

    return KeyboardShortcutsHandler(
      viewModel: vm,
      flashController: _keyFlash,
      onCopied: () => _showSnack(context.l10n.copied),
      onPasteFailed: () => _showSnack(context.l10n.pasteInvalid),
      child: _buildScaffold(colors, vm),
    );
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
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

  Widget _buildScaffold(ColorScheme colors, CalculatorViewModel vm) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: (details) => CalculatorContextMenu.show(
                  context: context,
                  viewModel: vm,
                  position: details.globalPosition,
                ),
                child: TimelineDisplay(
                  entries: vm.visibleTimelineEntries,
                  displayText: vm.fullDisplayText,
                  previewResult: vm.previewResult,
                  hasMore: vm.hasMoreTimelineEntries,
                  onLoadMore: vm.loadMoreTimelineEntries,
                  displayController: _displayController,
                  cursorPosition:
                      (vm.isEditingMidExpression && !vm.isCursorAtEnd)
                      ? vm.cursorPosition
                      : null,
                  onCharTap: vm.setCursorPosition,
                  onSwipeLeft: vm.moveCursorLeft,
                  onSwipeRight: vm.moveCursorRight,
                  onTapOutside: vm.moveCursorToEnd,
                ),
              ),
            ),
            _buildIconBar(colors),
            Container(
              color: colors.surfaceContainer,
              padding: EdgeInsets.only(
                top: AppLayout.padding.medium,
                bottom:
                    AppLayout.padding.medium +
                    MediaQuery.paddingOf(context).bottom,
              ),
              child: CalculatorKeypad(
                keyFlash: _keyFlash,
                onDigit: vm.inputDigit,
                onOperator: vm.setOperator,
                onEquals: vm.equals,
                onClear: vm.clear,
                onParenthesis: vm.inputParenthesis,
                onPercent: vm.applyPercentage,
                onDoubleZero: vm.inputDoubleZero,
                onTripleZero: vm.inputTripleZero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBar(ColorScheme colors) {
    final iconStyle = IconButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radius.small),
      ),
    );

    final dimmedColor = colors.onSurface.withValues(alpha: 0.5);
    final activeColor = colors.primary;
    final hasContent = widget.viewModel.hasContent;
    final backspaceColor = hasContent ? activeColor : dimmedColor;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppLayout.padding.large),
      child: Row(
        children: [
          IconButton(
            style: iconStyle,
            icon: Icon(Icons.history_rounded, color: dimmedColor),
            onPressed: () async {
              final result = await Navigator.of(
                context,
              ).pushNamed(AppRoutes.history);
              if (result is HistorySelection) {
                widget.viewModel.loadSession(result);
              }
            },
          ),
          IconButton(
            style: iconStyle,
            icon: Icon(Icons.settings_rounded, color: dimmedColor),
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.settings);
              widget.viewModel.loadSettings();
            },
          ),
          const Spacer(),
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: backspaceColor),
            duration: const Duration(milliseconds: 280),
            curve: Curves.fastOutSlowIn,
            builder: (context, color, _) {
              return IconButton(
                style: iconStyle,
                icon: Icon(Icons.backspace_rounded, color: color),
                onPressed: hasContent ? widget.viewModel.backspace : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
