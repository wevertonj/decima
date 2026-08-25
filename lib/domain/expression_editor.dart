import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/utils/formatters/number_formatter.dart';

/// Snapshot imutável do texto em edição e da posição do cursor.
///
/// Cada operação do [ExpressionEditor] recebe um estado e devolve o novo,
/// sem efeitos colaterais.
class EditorState {
  const EditorState({required this.text, required this.cursor});

  /// Texto formatado da expressão em edição.
  final String text;

  /// Posição do cursor como offset de caractere em [text].
  final int cursor;
}

/// Motor de edição por cursor da expressão da calculadora.
///
/// Manipulação pura de string, Add2-aware: inserções e remoções de dígito
/// reaplicam a formatação ao bloco numérico sob o cursor, preservando a
/// reancoragem do cursor pela contagem de dígitos à direita. Não conhece
/// Settings — o [DecimalSeparator] chega por parâmetro.
class ExpressionEditor {
  static final RegExp _digitRegExp = RegExp(r'[0-9]');
  static final RegExp _numberCharRegExp = RegExp(r'[0-9.,%]');

  /// Insere [digits] (apenas `0-9`) na posição do cursor, reaplicando a
  /// formatação Add2 ao bloco numérico ao redor.
  static EditorState insertDigits(
    EditorState state,
    String digits,
    DecimalSeparator separator,
  ) {
    final text = state.text;
    final block = _findNumberBlock(text, state.cursor);
    final raw = _stripToDigits(text.substring(block.start, block.end));
    final hasPercent = block.end > block.start && text[block.end - 1] == '%';
    final digitsBeforeCursor = _countDigits(text, block.start, state.cursor);
    final digitsAfterCursor = raw.length - digitsBeforeCursor;

    final newRaw =
        raw.substring(0, digitsBeforeCursor) +
        digits +
        raw.substring(digitsBeforeCursor);
    // Cursor cai logo após os dígitos inseridos: mesma contagem de dígitos
    // à direita de antes — imune ao zero à esquerda do Add2.
    final newDigitsAfterCursor = digitsAfterCursor;

    return _replaceBlockWithFormatted(
      text,
      block.start,
      block.end,
      newRaw,
      hasPercent,
      newDigitsAfterCursor,
      separator,
    );
  }

  /// Remove um dígito do bloco sob o cursor (reformatando via Add2). Sobre
  /// um operador ` op `, remove-o inteiro e mescla os dois blocos vizinhos;
  /// fora de bloco numérico, apaga o caractere literal.
  static EditorState backspace(EditorState state, DecimalSeparator separator) {
    if (state.cursor <= 0) return state;
    final text = state.text;
    final block = _findNumberBlock(text, state.cursor);
    final raw = _stripToDigits(text.substring(block.start, block.end));
    final digitsBeforeCursor = _countDigits(text, block.start, state.cursor);

    if (raw.isEmpty || digitsBeforeCursor == 0) {
      // Fronteira sem dígito antes do cursor: tenta o merge de blocos
      // (padrão ` op ` imediatamente antes); senão, apaga o literal.
      final merged = _tryMergeBlocksAtCursor(state, separator);
      if (merged != null) return merged;

      return EditorState(
        text:
            text.substring(0, state.cursor - 1) + text.substring(state.cursor),
        cursor: state.cursor - 1,
      );
    }

    final hasPercent = block.end > block.start && text[block.end - 1] == '%';
    final digitsAfterCursor = raw.length - digitsBeforeCursor;
    final newRaw =
        raw.substring(0, digitsBeforeCursor - 1) +
        raw.substring(digitsBeforeCursor);
    // Remover um dígito ANTES do cursor não muda quantos ficam DEPOIS —
    // o cursor segue ancorado ao mesmo dígito à direita.
    final newDigitsAfterCursor = digitsAfterCursor;

    return _replaceBlockWithFormatted(
      text,
      block.start,
      block.end,
      newRaw,
      hasPercent,
      newDigitsAfterCursor,
      separator,
    );
  }

  /// Insere um operador no cursor. No meio de um bloco numérico, divide o
  /// bloco em duas metades formatadas com ` op ` entre elas; em fronteira,
  /// insere o literal sem dividir. O cursor cai logo após o operador.
  static EditorState insertOperator(
    EditorState state,
    String operator,
    DecimalSeparator separator,
  ) {
    final text = state.text;
    final block = _findNumberBlock(text, state.cursor);
    final raw = _stripToDigits(text.substring(block.start, block.end));
    final digitsBeforeCursor = _countDigits(text, block.start, state.cursor);
    final digitsAfterCursor = raw.length - digitsBeforeCursor;

    // Sem bloco ao redor ou cursor em fronteira — insere o literal.
    if (raw.isEmpty || digitsBeforeCursor == 0 || digitsAfterCursor == 0) {
      return _insertLiteral(state, ' $operator ');
    }

    final hasPercent = block.end > block.start && text[block.end - 1] == '%';
    final leftRaw = raw.substring(0, digitsBeforeCursor);
    final rightRaw = raw.substring(digitsBeforeCursor);

    final leftCore = NumberFormatter.format(
      int.parse(leftRaw),
      separator: separator,
      useThousandsSeparator: true,
    );
    final rightCore = NumberFormatter.format(
      int.parse(rightRaw),
      separator: separator,
      useThousandsSeparator: true,
    );

    // O sufixo `%` estava na cauda do bloco original — fica com a metade
    // direita.
    final rightBlock = rightCore + (hasPercent ? '%' : '');
    final replacement = '$leftCore $operator $rightBlock';

    // Cursor logo após o operador: block.start + leftCore + ' op ' (3).
    return EditorState(
      text:
          text.substring(0, block.start) +
          replacement +
          text.substring(block.end),
      cursor: block.start + leftCore.length + 3,
    );
  }

  /// Insere `(` ou `)` no modo de edição. Fecha apenas com `(` pendente e
  /// operando completo à esquerda — o `)` cai no fim do bloco sob o cursor,
  /// nunca dividindo um número; senão abre `(` antes do bloco, agrupando o
  /// número que o cursor toca.
  static EditorState insertParenthesis(EditorState state) {
    final text = state.text;
    final block = _findNumberBlock(text, state.cursor);
    final hasBlock = block.end > block.start;

    if (countOpenParens(text) > 0) {
      final closeAt = hasBlock ? block.end : state.cursor;
      final before = closeAt > 0 ? text[closeAt - 1] : ' ';
      if (before == ')' || before == '%' || _digitRegExp.hasMatch(before)) {
        return _insertLiteral(EditorState(text: text, cursor: closeAt), ' )');
      }
    }

    final insertAt = hasBlock ? block.start : state.cursor;

    return EditorState(
      text: '${text.substring(0, insertAt)}( ${text.substring(insertAt)}',
      cursor: state.cursor + 2,
    );
  }

  /// Anexa `%` literal ao fim do bloco numérico sob o cursor. No-op sem
  /// bloco ou com `%` já presente.
  static EditorState applyPercent(EditorState state) {
    final text = state.text;
    final block = _findNumberBlock(text, state.cursor);
    if (block.end == block.start) return state;
    if (text[block.end - 1] == '%') return state;

    return EditorState(
      text: '${text.substring(0, block.end)}%${text.substring(block.end)}',
      cursor: block.end + 1,
    );
  }

  /// Parênteses abertos sem fechamento em [text].
  static int countOpenParens(String text) {
    var n = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '(') {
        n++;
      } else if (text[i] == ')') {
        n--;
      }
    }

    return n;
  }

  /// Normaliza o texto formatado para o `ExpressionEvaluator`: remove o
  /// separador de milhar e converte o separador decimal de volta ao ponto.
  static String normalizeForEvaluator(String text, DecimalSeparator separator) {
    final thousands = separator == DecimalSeparator.dot ? ',' : '.';
    final decimal = separator.character;
    var t = text.replaceAll(thousands, '');
    if (decimal != '.') {
      t = t.replaceAll(decimal, '.');
    }

    return t;
  }

  /// Insere o literal [s] (operadores, parênteses, espaços) no cursor, sem
  /// reformatar.
  static EditorState _insertLiteral(EditorState state, String s) {
    final text = state.text;

    return EditorState(
      text: text.substring(0, state.cursor) + s + text.substring(state.cursor),
      cursor: state.cursor + s.length,
    );
  }

  /// Se logo antes do cursor há ` op ` entre dois blocos numéricos, remove
  /// o operador e mescla os blocos (dígitos concatenados + Add2). Devolve o
  /// estado mesclado, ou `null` quando não há merge.
  static EditorState? _tryMergeBlocksAtCursor(
    EditorState state,
    DecimalSeparator separator,
  ) {
    final text = state.text;
    final cursor = state.cursor;
    // Padrão ` op ` terminando exatamente no cursor: cursor-3 = ' ',
    // cursor-2 = op, cursor-1 = ' '.
    if (cursor < 3) return null;
    if (text[cursor - 1] != ' ') return null;
    final op = text[cursor - 2];
    if (!(op == '+' || op == '−' || op == '×' || op == '÷')) return null;
    if (text[cursor - 3] != ' ') return null;

    final leftBlock = _findNumberBlock(text, cursor - 3);
    final rightBlock = _findNumberBlock(text, cursor);
    if (leftBlock.end == leftBlock.start) return null;
    if (rightBlock.end == rightBlock.start) return null;

    final leftRawPadded = _stripToDigits(
      text.substring(leftBlock.start, leftBlock.end),
    );
    final rightRawPadded = _stripToDigits(
      text.substring(rightBlock.start, rightBlock.end),
    );
    if (leftRawPadded.isEmpty && rightRawPadded.isEmpty) return null;

    // Cada lado é normalizado ao valor inteiro (sem o zero à esquerda do
    // Add2): concatenar sem padding dá o merge intuitivo —
    // '0.12' + '0.50' → '12.50'.
    final leftDigits = leftRawPadded.isEmpty
        ? ''
        : int.parse(leftRawPadded).toString();
    final rightDigits = rightRawPadded.isEmpty
        ? ''
        : int.parse(rightRawPadded).toString();

    final rightHasPercent =
        rightBlock.end > rightBlock.start && text[rightBlock.end - 1] == '%';
    final mergedRaw = leftDigits + rightDigits;
    // Cursor ancorado na fronteira entre as metades: a posição com
    // `rightDigits.length` dígitos à direita.
    final newDigitsAfterCursor = rightDigits.length;

    return _replaceBlockWithFormatted(
      text,
      leftBlock.start,
      rightBlock.end,
      mergedRaw,
      rightHasPercent,
      newDigitsAfterCursor,
      separator,
    );
  }

  /// Substitui [start..end) de [text] pela forma Add2 de [newRaw],
  /// restaurando o `%` opcional e posicionando o cursor com exatamente
  /// [newDigitsAfterCursor] dígitos à sua direita — a âncora estável
  /// quando o Add2 acrescenta zero à esquerda.
  static EditorState _replaceBlockWithFormatted(
    String text,
    int start,
    int end,
    String newRaw,
    bool hasPercent,
    int newDigitsAfterCursor,
    DecimalSeparator separator,
  ) {
    final newCore = newRaw.isEmpty
        ? ''
        : NumberFormatter.format(
            int.parse(newRaw),
            separator: separator,
            useThousandsSeparator: true,
          );
    final newBlock = newCore + (hasPercent ? '%' : '');

    final cursorOffsetInBlock = newCore.isEmpty
        ? 0
        : _positionWithDigitsAfter(newCore, newDigitsAfterCursor);

    return EditorState(
      text: text.substring(0, start) + newBlock + text.substring(end),
      cursor: start + cursorOffsetInBlock,
    );
  }

  /// Maior intervalo de caracteres numéricos contíguos contendo [pos];
  /// intervalo vazio em [pos] quando não há vizinho numérico.
  static ({int start, int end}) _findNumberBlock(String text, int pos) {
    var s = pos;
    var e = pos;
    while (s > 0 && _numberCharRegExp.hasMatch(text[s - 1])) {
      s--;
    }
    while (e < text.length && _numberCharRegExp.hasMatch(text[e])) {
      e++;
    }

    return (start: s, end: e);
  }

  static String _stripToDigits(String s) {
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (_digitRegExp.hasMatch(s[i])) buffer.write(s[i]);
    }

    return buffer.toString();
  }

  static int _countDigits(String text, int start, int end) {
    var n = 0;
    for (var i = start; i < end; i++) {
      if (_digitRegExp.hasMatch(text[i])) n++;
    }

    return n;
  }

  /// Offset em [formatted] com exatamente [digitCount] dígitos à direita.
  /// Clampado a `[0, formatted.length]`.
  static int _positionWithDigitsAfter(String formatted, int digitCount) {
    if (digitCount <= 0) return formatted.length;
    var seen = 0;
    for (var i = formatted.length - 1; i >= 0; i--) {
      if (_digitRegExp.hasMatch(formatted[i])) {
        seen++;
        if (seen >= digitCount) return i;
      }
    }

    return 0;
  }
}
