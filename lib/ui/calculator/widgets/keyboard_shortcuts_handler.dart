import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:decima/ui/calculator/keyboard_shortcuts.dart';
import 'package:decima/ui/calculator/widgets/calculator_keypad.dart';
import 'package:decima/ui/calculator/widgets/key_flash_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Habilita a operação da calculadora por teclado físico.
///
/// Envolve [child] em um [Focus] com `autofocus`, traduz cada evento de tecla
/// via [KeyboardShortcuts] e despacha a ação para o [CalculatorViewModel] —
/// pelos mesmos métodos usados pelo keypad virtual, o que faz a entrada por
/// teclado passar pela fila de toques da ViewModel (nenhum caminho paralelo,
/// nenhuma ação perdida).
///
/// Quando um campo de texto detém o foco (ex.: renomear entrada do histórico),
/// os atalhos são ignorados para não duplicar a digitação.
class KeyboardShortcutsHandler extends StatefulWidget {
  final CalculatorViewModel viewModel;

  /// Notificador usado para reproduzir o feedback visual do botão equivalente
  /// no keypad. Opcional — sem ele os atalhos funcionam sem glow.
  final KeyFlashController? flashController;

  /// Chamado após um `Ctrl/Cmd+C` que efetivamente copiou algo.
  final VoidCallback? onCopied;

  /// Chamado quando um `Ctrl/Cmd+V` não pôde ser interpretado.
  final VoidCallback? onPasteFailed;

  final bool autofocus;
  final Widget child;

  const KeyboardShortcutsHandler({
    super.key,
    required this.viewModel,
    this.flashController,
    this.onCopied,
    this.onPasteFailed,
    this.autofocus = true,
    required this.child,
  });

  @override
  State<KeyboardShortcutsHandler> createState() =>
      _KeyboardShortcutsHandlerState();
}

class _KeyboardShortcutsHandlerState extends State<KeyboardShortcutsHandler> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Aceita down e repeat (segurar Backspace apaga repetidamente); o up já
    // foi contabilizado no down correspondente.
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (_isTextEditingFocused()) return KeyEventResult.ignored;

    final keyboard = HardwareKeyboard.instance;
    final command = KeyboardShortcuts.resolve(
      logicalKey: event.logicalKey,
      character: event.character,
      isControlPressed: keyboard.isControlPressed,
      isMetaPressed: keyboard.isMetaPressed,
    );
    if (command == null) return KeyEventResult.ignored;

    _dispatch(command);

    return KeyEventResult.handled;
  }

  /// True quando o foco primário pertence a um campo de edição de texto.
  /// Nesse caso a digitação é do campo, não da calculadora.
  ///
  /// O `FocusNode` de um `TextField` está ancorado no `Focus` interno do
  /// `EditableText`, por isso a checagem sobe a árvore em busca do
  /// [EditableTextState] em vez de comparar o widget diretamente.
  bool _isTextEditingFocused() {
    final primaryContext = FocusManager.instance.primaryFocus?.context;
    if (primaryContext == null) return false;

    return primaryContext.findAncestorStateOfType<EditableTextState>() != null;
  }

  void _dispatch(CalculatorKeyCommand command) {
    final vm = widget.viewModel;

    switch (command.action) {
      case CalculatorKeyAction.digit:
        vm.inputDigit(command.value!);
      case CalculatorKeyAction.doubleZero:
        vm.inputDoubleZero();
      case CalculatorKeyAction.operator:
        vm.setOperator(command.value!);
      case CalculatorKeyAction.equals:
        vm.equals();
      case CalculatorKeyAction.backspace:
        vm.backspace();
      case CalculatorKeyAction.clearAll:
        vm.clear();
      case CalculatorKeyAction.percent:
        vm.applyPercentage();
      case CalculatorKeyAction.parenthesis:
        vm.inputParenthesis();
      case CalculatorKeyAction.cursorLeft:
        vm.moveCursorLeft();
      case CalculatorKeyAction.cursorRight:
        vm.moveCursorRight();
      case CalculatorKeyAction.copy:
        _copyResult();
      case CalculatorKeyAction.paste:
        _paste();
    }

    final label = _flashLabel(command);
    if (label != null) widget.flashController?.flash(label);
  }

  Future<void> _copyResult() async {
    final vm = widget.viewModel;
    if (!vm.hasResult) return;

    await vm.copyResult();
    if (!mounted) return;
    widget.onCopied?.call();
  }

  Future<void> _paste() async {
    final ok = await widget.viewModel.pasteFromClipboard();
    if (ok || !mounted) return;
    widget.onPasteFailed?.call();
  }

  /// Rótulo do botão do keypad equivalente à ação, usado para reproduzir o
  /// feedback visual. `null` para ações sem botão correspondente (backspace
  /// fica na barra de ícones; cursor e clipboard não têm botão).
  String? _flashLabel(CalculatorKeyCommand command) {
    switch (command.action) {
      case CalculatorKeyAction.digit:
      case CalculatorKeyAction.operator:
        return command.value;
      case CalculatorKeyAction.doubleZero:
        return CalculatorKeypad.doubleZeroLabel;
      case CalculatorKeyAction.equals:
        return CalculatorKeypad.equalsLabel;
      case CalculatorKeyAction.clearAll:
        return CalculatorKeypad.clearLabel;
      case CalculatorKeyAction.percent:
        return CalculatorKeypad.percentLabel;
      case CalculatorKeyAction.parenthesis:
        return CalculatorKeypad.parenthesisLabel;
      case CalculatorKeyAction.backspace:
      case CalculatorKeyAction.cursorLeft:
      case CalculatorKeyAction.cursorRight:
      case CalculatorKeyAction.copy:
      case CalculatorKeyAction.paste:
        return null;
    }
  }
}
