class ExpressionEvaluator {
  /// Resultado sentinela para expressões que avaliam para um valor não
  /// finito (divisão por zero). Exposto para quem precisa distinguir um
  /// resultado inavaliável de um numérico (ex.: validação de colagem).
  static const errorResult = 'Error';

  String? evaluate(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;

    final tokens = _tokenize(trimmed);
    if (tokens == null || tokens.isEmpty) return null;

    final flat = _resolveParens(tokens);
    if (flat == null) return null;

    final resolved = _resolvePercentages(flat);
    if (resolved == null) return null;

    final result = _evaluateTokens(resolved);
    if (result == null) return null;

    return _formatResult(result);
  }

  /// Resolves all parenthesized sub-expressions by repeatedly evaluating
  /// the innermost group and replacing it with the resulting numeric token.
  /// Returns null if parentheses are unbalanced or empty.
  List<String>? _resolveParens(List<String> input) {
    var tokens = input;

    while (true) {
      var lastOpen = -1;
      var matchingClose = -1;

      for (var i = 0; i < tokens.length; i++) {
        if (tokens[i] == '(') {
          lastOpen = i;
        } else if (tokens[i] == ')') {
          if (lastOpen == -1) return null;
          matchingClose = i;
          break;
        }
      }

      if (lastOpen == -1 && matchingClose == -1) {
        return tokens;
      }
      if (lastOpen != -1 && matchingClose == -1) {
        return null;
      }

      final inner = tokens.sublist(lastOpen + 1, matchingClose);
      if (inner.isEmpty) return null;

      final percentResolved = _resolvePercentages(inner);
      if (percentResolved == null) return null;

      final innerResult = _evaluateTokens(percentResolved);
      if (innerResult == null) return null;

      tokens = [
        ...tokens.sublist(0, lastOpen),
        innerResult.toString(),
        ...tokens.sublist(matchingClose + 1),
      ];
    }
  }

  List<String>? _tokenize(String expression) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];

      if (char == ' ') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }

        continue;
      }

      if (_isOperator(char)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
      } else if (char == '%') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add('%');
      } else if (char == '(' || char == ')') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    // Remove trailing operator
    while (tokens.isNotEmpty && _isOperator(tokens.last)) {
      tokens.removeLast();
    }

    if (tokens.isEmpty) return null;

    // Validate: must start with a number or an opening parenthesis
    if (_isOperator(tokens.first) ||
        tokens.first == '%' ||
        tokens.first == ')') {
      return null;
    }

    return tokens;
  }

  bool _isOperator(String token) {
    return token == '+' || token == '−' || token == '×' || token == '÷';
  }

  List<String>? _resolvePercentages(List<String> tokens) {
    final result = <String>[];

    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i] == '%') {
        if (result.isEmpty) return null;

        final percentValue = double.tryParse(result.removeLast());
        if (percentValue == null) return null;

        // Find the base value (the number before the operator)
        String? operator;
        double? baseValue;

        for (var j = result.length - 1; j >= 0; j--) {
          if (_isOperator(result[j])) {
            operator = result[j];
            if (j > 0) {
              baseValue = double.tryParse(result[j - 1]);
            }

            break;
          }
        }

        if (operator != null && baseValue != null) {
          if (operator == '+' || operator == '−') {
            // percentage of base: 100 + 10% means 100 + (100 * 10/100)
            final percentAmount = baseValue * percentValue / 100.0;
            result.add(percentAmount.toString());
          } else {
            // For × and ÷, just convert to fraction
            result.add((percentValue / 100.0).toString());
          }
        } else {
          // No context — just convert to fraction
          result.add((percentValue / 100.0).toString());
        }
      } else {
        result.add(tokens[i]);
      }
    }

    return result;
  }

  double? _evaluateTokens(List<String> tokens) {
    if (tokens.isEmpty) return null;

    // Parse into numbers and operators lists
    final numbers = <double>[];
    final operators = <String>[];

    for (var i = 0; i < tokens.length; i++) {
      if (i.isEven) {
        final num = double.tryParse(tokens[i]);
        if (num == null) return null;
        numbers.add(num);
      } else {
        if (!_isOperator(tokens[i])) return null;
        operators.add(tokens[i]);
      }
    }

    if (numbers.isEmpty) return null;

    // First pass: handle × and ÷ (higher precedence)
    var i = 0;
    while (i < operators.length) {
      if (operators[i] == '×' || operators[i] == '÷') {
        if (i + 1 >= numbers.length) return null;
        final left = numbers[i];
        final right = numbers[i + 1];
        double result;

        if (operators[i] == '×') {
          result = left * right;
        } else {
          if (right == 0) return double.infinity;
          result = left / right;
        }

        numbers[i] = result;
        numbers.removeAt(i + 1);
        operators.removeAt(i);
      } else {
        i++;
      }
    }

    // Second pass: handle + and − (lower precedence)
    var result = numbers[0];
    for (i = 0; i < operators.length; i++) {
      if (i + 1 >= numbers.length) return null;
      if (operators[i] == '+') {
        result += numbers[i + 1];
      } else if (operators[i] == '−') {
        result -= numbers[i + 1];
      }
    }

    return result;
  }

  String _formatResult(double value) {
    if (value.isInfinite || value.isNaN) return errorResult;

    return value.toStringAsFixed(2);
  }
}
