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

  /// Inserts the digit string [digits] (only `0-9` chars) at the current
  /// cursor position, applying Add2 formatting to the surrounding number
  /// block. The block is detected from contiguous number-like chars
  /// (digits, decimal/thousand separators, optional trailing `%`).
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
    // Preserve digitsAfterCursor: the cursor lands immediately after the
    // newly inserted digits, keeping the same number of digits to its right
    // as before the insertion. This is robust to Add2's leading-zero padding.
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

  /// Removes one digit from the surrounding number block (re-formatting
  /// the block via Add2). When the char immediately before the cursor is an
  /// operator (` op `), removes the entire operator-with-spaces and merges
  /// the two surrounding number blocks via Add2 (concatenated raw digits).
  /// Outside number blocks, falls back to deleting the literal char.
  static EditorState backspace(EditorState state, DecimalSeparator separator) {
    if (state.cursor <= 0) return state;
    final text = state.text;
    final block = _findNumberBlock(text, state.cursor);
    final raw = _stripToDigits(text.substring(block.start, block.end));
    final digitsBeforeCursor = _countDigits(text, block.start, state.cursor);

    if (raw.isEmpty || digitsBeforeCursor == 0) {
      // Cursor is at a non-digit boundary. Detect the operator-with-spaces
      // pattern (` op ` where op ∈ +−×÷) immediately before the cursor and
      // merge the surrounding blocks if present.
      final merged = _tryMergeBlocksAtCursor(state, separator);
      if (merged != null) return merged;

      // Plain literal char delete.
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
    // Preserve digitsAfterCursor: removing a digit BEFORE the cursor does
    // not change how many digits are AFTER it, so the cursor stays anchored
    // to the same trailing digit (immune to Add2's leading-zero padding).
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

  /// Inserts an operator at the current cursor position. When the cursor
  /// lies in the middle of a number block (digits on both sides), the block
  /// is split into two Add2-formatted halves with ` op ` between them.
  /// At block boundaries (start, end, or outside any block), the operator
  /// is inserted as a literal ` op ` without splitting.
  ///
  /// Cursor lands immediately after the inserted operator.
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

    // No surrounding block, or cursor at a boundary — append literally.
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

    // Percent suffix (if any) belongs to the right half — it was at the
    // tail of the original block.
    final rightBlock = rightCore + (hasPercent ? '%' : '');
    final replacement = '$leftCore $operator $rightBlock';

    // Cursor lands immediately after the inserted operator (after the
    // trailing space): position = block.start + leftCore.length + 3
    // (' ' + op + ' ').
    return EditorState(
      text:
          text.substring(0, block.start) +
          replacement +
          text.substring(block.end),
      cursor: block.start + leftCore.length + 3,
    );
  }

  /// Inserts `(` or `)` at the cursor while editing mid-expression.
  ///
  /// Closes only when there is an unmatched `(` in the text **and** the token
  /// to the left of the closing point is a complete operand (digit, `%` or
  /// `)`); the `)` lands at the end of the number block under the cursor so a
  /// number is never split. Otherwise it opens a `(` immediately **before**
  /// that block, grouping the number the cursor is touching — inserting at the
  /// end of the block instead would produce an unmatched `)` and break the
  /// expression.
  ///
  /// When opening, the cursor keeps its position relative to the surrounding
  /// text (it does not jump), since the insertion happens to its left.
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

  /// Appends a literal `%` to the end of the number block surrounding the
  /// cursor. No-op when there is no block, or when the block already ends
  /// with `%`.
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

  /// Number of unmatched opening parentheses in [text].
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

  /// Normalizes the formatted edit text into a string the
  /// `ExpressionEvaluator` can parse: removes thousand separators and
  /// converts the configured decimal separator back to a dot.
  static String normalizeForEvaluator(String text, DecimalSeparator separator) {
    final thousands = separator == DecimalSeparator.dot ? ',' : '.';
    final decimal = separator.character;
    var t = text.replaceAll(thousands, '');
    if (decimal != '.') {
      t = t.replaceAll(decimal, '.');
    }

    return t;
  }

  /// Inserts the literal string [s] (operators, parentheses, spaces) at the
  /// current cursor position without re-formatting. Used for non-digit input.
  static EditorState _insertLiteral(EditorState state, String s) {
    final text = state.text;

    return EditorState(
      text: text.substring(0, state.cursor) + s + text.substring(state.cursor),
      cursor: state.cursor + s.length,
    );
  }

  /// Detects whether the chars immediately before the cursor form an
  /// operator-with-spaces sequence (` op `) sandwiched between two number
  /// blocks. If so, removes the operator (and its surrounding spaces) and
  /// merges the two blocks by concatenating their raw digits and re-applying
  /// Add2. Returns the merged state, or `null` when there is no merge.
  static EditorState? _tryMergeBlocksAtCursor(
    EditorState state,
    DecimalSeparator separator,
  ) {
    final text = state.text;
    final cursor = state.cursor;
    // Pattern is " op " ending exactly at the cursor: chars at
    // cursor-3 = ' ', cursor-2 = op, cursor-1 = ' '.
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

    // Normalize each side to its integer value (drops Add2's mandatory
    // leading-zero padding). Concatenating the un-padded digit strings
    // gives the user's intuitive merge: '0.12' + '0.50' -> '12.50'.
    final leftDigits = leftRawPadded.isEmpty
        ? ''
        : int.parse(leftRawPadded).toString();
    final rightDigits = rightRawPadded.isEmpty
        ? ''
        : int.parse(rightRawPadded).toString();

    final rightHasPercent =
        rightBlock.end > rightBlock.start && text[rightBlock.end - 1] == '%';
    final mergedRaw = leftDigits + rightDigits;
    // Cursor anchors to the boundary between left and right halves —
    // i.e., the position with `rightDigits.length` digits to its right.
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

  /// Replaces the substring [text] [start..end) with the Add2-formatted
  /// representation of [newRaw] (digit-only string), restoring the optional
  /// `%` suffix and positioning the cursor so that exactly
  /// [newDigitsAfterCursor] digit characters of the new block lie after it.
  ///
  /// Anchoring the cursor by digits-after (rather than digits-before) keeps
  /// it visually stable when Add2 pads the block with a leading zero — the
  /// trailing digits are the stable reference, not the volatile leading edge.
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

  /// Finds the maximal range of contiguous number-like characters
  /// containing position [pos] in [text]. Returns a zero-length range at
  /// [pos] when the cursor is not adjacent to any number-like char.
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

  /// Returns the offset in [formatted] such that exactly [digitCount] digit
  /// characters follow it. Clamps to `[0, formatted.length]`.
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
