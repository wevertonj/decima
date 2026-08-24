/// Texto colado decomposto em linhas já resolvidas e uma entrada em aberto.
///
/// Reproduz o formato produzido por `CalculatorViewModel.copyHistory()`
/// (`<expressão> = <resultado>`, uma por linha), o que fecha o ciclo
/// copiar histórico → colar de volta.
class PastedContent {
  /// Tokens das expressões que vinham à esquerda de um `=`, na ordem original.
  /// Cada item vira uma linha da timeline.
  final List<List<String>> resolvedLines;

  /// Tokens da entrada em aberto (linha final sem `=`). `null` quando o texto
  /// termina em uma linha resolvida — nesse caso o display recebe o resultado
  /// da última linha, como acontece após pressionar `=`.
  final List<String>? input;

  const PastedContent({required this.resolvedLines, this.input});
}

/// Parses raw text from the clipboard into a list of normalized calculator
/// tokens. Returns null when the input is empty or syntactically invalid.
///
/// Output tokens use the same shape as the calculator's internal expression
/// tokens: numbers as fixed `x.yy` strings (optionally suffixed with `%`),
/// operators as `+ − × ÷`, and parentheses as `(` / `)`.
///
/// Numbers are taken at face value: integers are padded to two decimal
/// places (`1250` → `1250.00`); decimals preserve their fractional digits
/// (`12.5` → `12.50`); the Add2 cents conversion does not apply here.
class PasteInputParser {
  /// Decompõe o texto colado em linhas resolvidas (`<expressão> = <resultado>`)
  /// e, opcionalmente, uma entrada em aberto na última linha.
  ///
  /// Retorna `null` quando qualquer linha é inválida, quando uma linha em
  /// aberto aparece antes de uma resolvida, quando falta o resultado depois
  /// do `=` ou quando o resultado não é um número isolado.
  ///
  /// O lado direito do `=` é apenas **validado**: quem consome recalcula a
  /// expressão, para nunca gravar no histórico um resultado que não
  /// corresponde à expressão.
  static PastedContent? parseContent(String input) {
    final lines = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    final resolvedLines = <List<String>>[];
    List<String>? pendingInput;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final separator = line.indexOf('=');

      if (separator < 0) {
        // Uma linha sem `=` é a entrada em aberto — só pode ser a última.
        if (i != lines.length - 1) return null;
        final tokens = parse(line);
        if (tokens == null) return null;
        pendingInput = tokens;

        continue;
      }

      final left = line.substring(0, separator);
      final right = line.substring(separator + 1);
      if (right.contains('=')) return null;

      final leftTokens = parse(left);
      if (leftTokens == null) return null;
      // Uma linha resolvida é um cálculo: exige operador, igual à regra do
      // `=` na calculadora. Sem isso, `10 = 5` viraria a linha sem sentido
      // `10.00 = 10.00` (o resultado colado é sempre recalculado).
      if (!leftTokens.any(_isOperator)) return null;

      // O lado direito precisa ser um número isolado (o resultado).
      final rightTokens = parse(right);
      if (rightTokens == null || rightTokens.length != 1) return null;
      final result = rightTokens.first;
      if (_isOperator(result) || result == '(' || result == ')') return null;

      resolvedLines.add(leftTokens);
    }

    if (resolvedLines.isEmpty && pendingInput == null) return null;

    return PastedContent(resolvedLines: resolvedLines, input: pendingInput);
  }

  static List<String>? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final raw = _stripWhitespace(trimmed);
    final normalized = _normalizeOperators(raw);

    final rawTokens = <String>[];
    var i = 0;
    var openParens = 0;

    while (i < normalized.length) {
      final ch = normalized[i];

      if (_isOperator(ch)) {
        if (rawTokens.isEmpty) return null;
        final last = rawTokens.last;
        if (_isOperator(last) || last == '(') return null;
        rawTokens.add(ch);
        i++;

        continue;
      }

      if (ch == '(') {
        if (rawTokens.isNotEmpty) {
          final last = rawTokens.last;
          if (!_isOperator(last) && last != '(') return null;
        }
        rawTokens.add('(');
        openParens++;
        i++;

        continue;
      }

      if (ch == ')') {
        if (openParens <= 0) return null;
        if (rawTokens.isEmpty) return null;
        final last = rawTokens.last;
        if (_isOperator(last) || last == '(') return null;
        rawTokens.add(')');
        openParens--;
        i++;

        continue;
      }

      if (ch == '%') {
        if (rawTokens.isEmpty) return null;
        final last = rawTokens.last;
        if (_isOperator(last) ||
            last == '(' ||
            last == ')' ||
            last.endsWith('%')) {
          return null;
        }
        rawTokens[rawTokens.length - 1] = '$last%';
        i++;

        continue;
      }

      // Read a number literal (digits, dots, commas).
      final start = i;
      while (i < normalized.length && _isNumberChar(normalized[i])) {
        i++;
      }
      if (start == i) return null;
      final numberLiteral = normalized.substring(start, i);

      if (rawTokens.isNotEmpty) {
        final last = rawTokens.last;
        if (!_isOperator(last) && last != '(') return null;
      }
      rawTokens.add(numberLiteral);
    }

    if (openParens != 0) return null;
    if (rawTokens.isEmpty) return null;

    final lastRaw = rawTokens.last;
    if (_isOperator(lastRaw) || lastRaw == '(') return null;

    // Second pass: format numbers. All numbers use face value: integers
    // are padded with `.00`, decimals keep their fractional digits.
    final tokens = <String>[];
    for (final t in rawTokens) {
      if (_isOperator(t) || t == '(' || t == ')') {
        tokens.add(t);

        continue;
      }

      final hasPercent = t.endsWith('%');
      final literal = hasPercent ? t.substring(0, t.length - 1) : t;
      final formatted = _formatNumber(literal);
      if (formatted == null) return null;
      tokens.add(hasPercent ? '$formatted%' : formatted);
    }

    return tokens;
  }

  static String _stripWhitespace(String s) {
    return s.replaceAll(RegExp(r'\s+'), '');
  }

  static String _normalizeOperators(String s) {
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      switch (ch) {
        case '*':
        case 'x':
        case 'X':
          buffer.write('×');
        case '/':
          buffer.write('÷');
        case '-':
          buffer.write('−');
        default:
          buffer.write(ch);
      }
    }

    return buffer.toString();
  }

  static bool _isOperator(String token) {
    return token == '+' || token == '−' || token == '×' || token == '÷';
  }

  static bool _isNumberChar(String ch) {
    if (ch == '.' || ch == ',') return true;
    final code = ch.codeUnitAt(0);

    return code >= 0x30 && code <= 0x39;
  }

  /// Converts a number literal (e.g., `1.000,00`, `12,5`, `1250`) into the
  /// internal fixed-decimal form (`xx.yy`). Returns null if the literal
  /// cannot be interpreted unambiguously.
  static String? _formatNumber(String literal) {
    final hasDot = literal.contains('.');
    final hasComma = literal.contains(',');

    String? decimalPart;
    String integerPart;

    if (hasDot && hasComma) {
      // Whichever appears last is the decimal separator.
      final lastDot = literal.lastIndexOf('.');
      final lastComma = literal.lastIndexOf(',');
      final decimalSep = lastDot > lastComma ? '.' : ',';
      final thousandsSep = decimalSep == '.' ? ',' : '.';
      final parts = literal.split(decimalSep);
      if (parts.length != 2) return null;
      integerPart = parts[0].replaceAll(thousandsSep, '');
      decimalPart = parts[1];
    } else if (hasDot || hasComma) {
      final sep = hasDot ? '.' : ',';
      final parts = literal.split(sep);
      // Reject if any non-digit slipped through.
      for (final p in parts) {
        if (p.isEmpty) return null;
        if (!RegExp(r'^[0-9]+$').hasMatch(p)) return null;
      }

      final last = parts.last;
      // Heuristic: a single occurrence with 1 or 2 trailing digits is the
      // decimal separator. Otherwise (e.g., `1.000`, `1,234,567`) it is a
      // thousands separator and the literal is an integer.
      if (parts.length == 2 && last.length <= 2) {
        integerPart = parts.first;
        decimalPart = last;
      } else {
        // Validate: every chunk except the first must have exactly 3 digits.
        for (var i = 1; i < parts.length; i++) {
          if (parts[i].length != 3) return null;
        }
        integerPart = parts.join();
        decimalPart = null;
      }
    } else {
      integerPart = literal;
      decimalPart = null;
    }

    if (integerPart.isEmpty) integerPart = '0';
    if (!RegExp(r'^[0-9]+$').hasMatch(integerPart)) return null;

    if (decimalPart == null) {
      // Pure integer — face value, padded with `.00`.
      final intVal = int.tryParse(integerPart);
      if (intVal == null) return null;

      return _formatCents(intVal * 100);
    }

    // Decimal present: pad/round to exactly 2 fractional digits.
    if (!RegExp(r'^[0-9]+$').hasMatch(decimalPart)) return null;

    String paddedDecimal;
    if (decimalPart.length == 1) {
      paddedDecimal = '${decimalPart}0';
    } else if (decimalPart.length == 2) {
      paddedDecimal = decimalPart;
    } else {
      // Round half-up to 2 digits.
      final keep = decimalPart.substring(0, 2);
      final next = int.parse(decimalPart[2]);
      var rounded = int.parse(keep);
      if (next >= 5) rounded++;
      if (rounded == 100) {
        // Carry into integer part.
        final intVal = (int.tryParse(integerPart) ?? 0) + 1;
        integerPart = intVal.toString();
        paddedDecimal = '00';
      } else {
        paddedDecimal = rounded.toString().padLeft(2, '0');
      }
    }

    final intVal = int.tryParse(integerPart);
    if (intVal == null) return null;
    final cents = intVal * 100 + int.parse(paddedDecimal);

    return _formatCents(cents);
  }

  static String _formatCents(int cents) {
    final whole = cents ~/ 100;
    final frac = (cents % 100).toString().padLeft(2, '0');

    return '$whole.$frac';
  }
}
