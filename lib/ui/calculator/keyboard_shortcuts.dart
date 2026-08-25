import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ações da calculadora que podem ser acionadas por uma tecla física.
/// Cada valor corresponde a um método do `CalculatorViewModel` — o despacho
/// acontece no `KeyboardShortcutsHandler`, passando pela mesma fila de toques
/// usada pelo keypad virtual.
enum CalculatorKeyAction {
  digit,
  doubleZero,
  operator,
  equals,
  backspace,
  clearAll,
  percent,
  parenthesis,
  cursorLeft,
  cursorRight,
  copy,
  paste,
}

/// Ação resolvida a partir de um evento de teclado, com o payload opcional
/// necessário para executá-la.
@immutable
class CalculatorKeyCommand {
  final CalculatorKeyAction action;

  /// Dígito (`0`–`9`) para [CalculatorKeyAction.digit] ou símbolo do operador
  /// (`+`, `−`, `×`, `÷`) para [CalculatorKeyAction.operator]. `null` nas
  /// demais ações.
  final String? value;

  const CalculatorKeyCommand(this.action, [this.value]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CalculatorKeyCommand &&
        other.action == action &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(action, value);

  @override
  String toString() => 'CalculatorKeyCommand($action, $value)';
}

/// Tradutor de eventos de teclado físico em ações da calculadora.
///
/// Resolve em três camadas: combinações `Ctrl`/`Cmd` (só copiar/colar),
/// teclas nomeadas por [LogicalKeyboardKey] (Enter, setas, numpad) e
/// caractere impresso — fonte primária porque o `logicalKey` de `%`, `*`,
/// `(` varia por plataforma e layout; o caractere não.
abstract final class KeyboardShortcuts {
  /// Caracteres de operador aceitos → símbolo tipográfico usado pelo
  /// `CalculatorViewModel`.
  static const Map<String, String> _operators = <String, String>{
    '+': '+',
    '-': '−',
    '−': '−',
    '*': '×',
    'x': '×',
    'X': '×',
    '×': '×',
    '/': '÷',
    '÷': '÷',
  };

  /// Teclas do bloco numérico, que em várias plataformas não expõem um
  /// caractere utilizável.
  static final Map<LogicalKeyboardKey, CalculatorKeyCommand> _numpadKeys =
      <LogicalKeyboardKey, CalculatorKeyCommand>{
        LogicalKeyboardKey.numpad0: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '0',
        ),
        LogicalKeyboardKey.numpad1: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '1',
        ),
        LogicalKeyboardKey.numpad2: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '2',
        ),
        LogicalKeyboardKey.numpad3: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '3',
        ),
        LogicalKeyboardKey.numpad4: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '4',
        ),
        LogicalKeyboardKey.numpad5: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '5',
        ),
        LogicalKeyboardKey.numpad6: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '6',
        ),
        LogicalKeyboardKey.numpad7: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '7',
        ),
        LogicalKeyboardKey.numpad8: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '8',
        ),
        LogicalKeyboardKey.numpad9: CalculatorKeyCommand(
          CalculatorKeyAction.digit,
          '9',
        ),
        LogicalKeyboardKey.numpadAdd: CalculatorKeyCommand(
          CalculatorKeyAction.operator,
          '+',
        ),
        LogicalKeyboardKey.numpadSubtract: CalculatorKeyCommand(
          CalculatorKeyAction.operator,
          '−',
        ),
        LogicalKeyboardKey.numpadMultiply: CalculatorKeyCommand(
          CalculatorKeyAction.operator,
          '×',
        ),
        LogicalKeyboardKey.numpadDivide: CalculatorKeyCommand(
          CalculatorKeyAction.operator,
          '÷',
        ),
        LogicalKeyboardKey.numpadEnter: CalculatorKeyCommand(
          CalculatorKeyAction.equals,
        ),
        LogicalKeyboardKey.numpadEqual: CalculatorKeyCommand(
          CalculatorKeyAction.equals,
        ),
        LogicalKeyboardKey.numpadDecimal: CalculatorKeyCommand(
          CalculatorKeyAction.doubleZero,
        ),
      };

  /// Teclas de controle mapeadas diretamente pelo [LogicalKeyboardKey].
  static final Map<LogicalKeyboardKey, CalculatorKeyCommand> _namedKeys =
      <LogicalKeyboardKey, CalculatorKeyCommand>{
        LogicalKeyboardKey.enter: CalculatorKeyCommand(
          CalculatorKeyAction.equals,
        ),
        LogicalKeyboardKey.backspace: CalculatorKeyCommand(
          CalculatorKeyAction.backspace,
        ),
        LogicalKeyboardKey.escape: CalculatorKeyCommand(
          CalculatorKeyAction.clearAll,
        ),
        LogicalKeyboardKey.delete: CalculatorKeyCommand(
          CalculatorKeyAction.clearAll,
        ),
        LogicalKeyboardKey.arrowLeft: CalculatorKeyCommand(
          CalculatorKeyAction.cursorLeft,
        ),
        LogicalKeyboardKey.arrowRight: CalculatorKeyCommand(
          CalculatorKeyAction.cursorRight,
        ),
      };

  /// Resolve a ação correspondente ao evento de teclado, ou `null` quando a
  /// tecla não tem equivalente na calculadora.
  static CalculatorKeyCommand? resolve({
    required LogicalKeyboardKey logicalKey,
    String? character,
    bool isControlPressed = false,
    bool isMetaPressed = false,
  }) {
    if (isControlPressed || isMetaPressed) {
      return _resolveModified(logicalKey);
    }

    final named = _namedKeys[logicalKey] ?? _numpadKeys[logicalKey];
    if (named != null) return named;

    return _resolvePrintable(character) ??
        _resolvePrintable(logicalKey.keyLabel);
  }

  /// Combinações com `Ctrl`/`Cmd`. Apenas copiar e colar são reconhecidas —
  /// o resto retorna `null` para que atalhos do sistema (ex.: `Ctrl+X`) não
  /// sejam interpretados como entrada da calculadora.
  static CalculatorKeyCommand? _resolveModified(LogicalKeyboardKey logicalKey) {
    if (logicalKey == LogicalKeyboardKey.keyC) {
      return const CalculatorKeyCommand(CalculatorKeyAction.copy);
    }
    if (logicalKey == LogicalKeyboardKey.keyV) {
      return const CalculatorKeyCommand(CalculatorKeyAction.paste);
    }

    return null;
  }

  /// Resolve um único caractere impresso. Strings com tamanho diferente de 1
  /// (rótulos de debug como `Shift Left`, ou vazios) são descartadas.
  static CalculatorKeyCommand? _resolvePrintable(String? character) {
    if (character == null || character.length != 1) return null;

    if (character.codeUnitAt(0) >= 0x30 && character.codeUnitAt(0) <= 0x39) {
      return CalculatorKeyCommand(CalculatorKeyAction.digit, character);
    }

    final operator = _operators[character];
    if (operator != null) {
      return CalculatorKeyCommand(CalculatorKeyAction.operator, operator);
    }

    switch (character) {
      case '=':
        return const CalculatorKeyCommand(CalculatorKeyAction.equals);
      case '%':
        return const CalculatorKeyCommand(CalculatorKeyAction.percent);
      case '(':
      case ')':
        return const CalculatorKeyCommand(CalculatorKeyAction.parenthesis);
      // Add2 não tem ponto literal — o separador decimal é implícito. Ambas as
      // teclas de separador viram o atalho `00`, que é a forma natural de
      // completar os centavos (ex.: `1` + `.` → `1.00`).
      case '.':
      case ',':
        return const CalculatorKeyCommand(CalculatorKeyAction.doubleZero);
    }

    return null;
  }
}
