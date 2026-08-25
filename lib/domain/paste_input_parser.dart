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

/// Converte texto cru da área de transferência em tokens internos da
/// calculadora (números `x.yy` com `%` opcional, operadores `+ − × ÷`,
/// parênteses). Números valem o que dizem: inteiro ganha `.00`, decimal
/// preserva as casas — a conversão Add2 de centavos não se aplica aqui.
class PasteInputParser {
  /// Decompõe o texto colado em linhas resolvidas (`<expressão> = <resultado>`)
  /// e, opcionalmente, uma entrada em aberto na última linha. Retorna `null`
  /// quando alguma linha é inválida ou fora de ordem.
  ///
  /// O lado direito do `=` é apenas **validado**: quem consome recalcula a
  /// expressão, para nunca gravar no histórico um resultado que não
  /// corresponde a ela.
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
      // Linha resolvida é um cálculo: exige operador, igual à regra do `=`.
      // Sem isso, `10 = 5` viraria `10.00 = 10.00` (resultado recalculado).
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

      // Lê um literal numérico (dígitos, pontos, vírgulas).
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

    // Segunda passada: formata os números pelo valor de face.
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

  /// Converte um literal numérico (`1.000,00`, `12,5`, `1250`) para a forma
  /// interna `xx.yy`. Retorna `null` quando a interpretação é ambígua.
  static String? _formatNumber(String literal) {
    final hasDot = literal.contains('.');
    final hasComma = literal.contains(',');

    String? decimalPart;
    String integerPart;

    if (hasDot && hasComma) {
      // O separador que aparece por último é o decimal.
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
      for (final p in parts) {
        if (p.isEmpty) return null;
        if (!RegExp(r'^[0-9]+$').hasMatch(p)) return null;
      }

      final last = parts.last;
      // Heurística: ocorrência única com 1–2 dígitos finais é separador
      // decimal; senão (`1.000`, `1,234,567`) é milhar e o literal é
      // inteiro.
      if (parts.length == 2 && last.length <= 2) {
        integerPart = parts.first;
        decimalPart = last;
      } else {
        // Todo grupo além do primeiro precisa ter exatamente 3 dígitos.
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
      // Inteiro puro — valor de face com `.00`.
      final intVal = int.tryParse(integerPart);
      if (intVal == null) return null;

      return _formatCents(intVal * 100);
    }

    // Com decimal: completa/arredonda para exatamente 2 casas.
    if (!RegExp(r'^[0-9]+$').hasMatch(decimalPart)) return null;

    String paddedDecimal;
    if (decimalPart.length == 1) {
      paddedDecimal = '${decimalPart}0';
    } else if (decimalPart.length == 2) {
      paddedDecimal = decimalPart;
    } else {
      // Arredondamento half-up para 2 casas.
      final keep = decimalPart.substring(0, 2);
      final next = int.parse(decimalPart[2]);
      var rounded = int.parse(keep);
      if (next >= 5) rounded++;
      if (rounded == 100) {
        // Vai-um para a parte inteira.
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
