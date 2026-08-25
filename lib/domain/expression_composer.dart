import 'package:decima/domain/add2_engine.dart';

/// Máquina de composição da expressão em digitação (modo append).
///
/// Mantém os tokens confirmados, o operador pendente e o operando ativo no
/// [Add2Engine], espelhando exatamente como a expressão foi digitada. É o
/// contraponto do `ExpressionEditor` (modo edição por cursor): aqui a
/// expressão só cresce/encolhe pela ponta. Dart puro, sem estado de UI,
/// sem persistência e sem formatação de exibição — os tokens trafegam na
/// forma crua `x.yy` (com sufixo `%` opcional), operadores `+ − × ÷` e
/// parênteses.
class ExpressionComposer {
  ExpressionComposer({Add2Engine? engine}) : _engine = engine ?? Add2Engine();

  final Add2Engine _engine;

  /// Tokens confirmados: valor numérico (com `%` opcional), operador
  /// (`+ − × ÷`) ou parêntese.
  final List<String> _committed = [];

  /// Operador digitado ainda não confirmado (aguardando o lado direito).
  String? _pendingOperator;

  /// `true` enquanto o valor do [_engine] é o operando em digitação.
  bool _engineActive = false;

  /// Valor do engine é resultado antigo (pós-`=` ou sessão carregada); o
  /// próximo dígito reseta o engine e começa número novo.
  bool _shouldResetOnInput = false;

  /// Marca o operando ativo como porcentagem literal.
  bool _isPercentage = false;

  // ----- Queries --------------------------------------------------------

  /// Valor cru do operando ativo (ex.: `1250.00`), sem separador de milhar.
  String get currentValue => _engine.formattedValue;

  String? get pendingOperator => _pendingOperator;

  bool get isEngineActive => _engineActive;

  bool get isEngineEmpty => _engine.isEmpty;

  bool get shouldResetOnInput => _shouldResetOnInput;

  /// Parênteses abertos sem fechamento nos tokens confirmados.
  int get openParenCount {
    var n = 0;
    for (final t in _committed) {
      if (t == '(') {
        n++;
      } else if (t == ')') {
        n--;
      }
    }

    return n;
  }

  /// `true` quando há algo digitado: tokens confirmados, operando ativo ou
  /// operador pendente.
  bool get hasExpression {
    if (_committed.isNotEmpty) return true;
    if (_engineActive) return true;
    if (_pendingOperator != null) return true;

    return false;
  }

  bool get lastIsClosingParen =>
      _committed.isNotEmpty && _committed.last == ')';

  List<String> get committedTokens => List.unmodifiable(_committed);

  static bool isOperator(String value) {
    return value == '+' || value == '−' || value == '×' || value == '÷';
  }

  static bool isValueToken(String value) {
    if (value == '(' || value == ')') return false;

    return !isOperator(value);
  }

  /// Token do operando ativo, com o `%` literal quando marcado.
  String engineToken() {
    final value = _engine.formattedValue;

    return _isPercentage ? '$value%' : value;
  }

  /// Tokens crus da expressão como exibida: confirmados + operador pendente
  /// + operando ativo (ou o valor do engine após um operando fechado).
  List<String> displayTokens() {
    final parts = <String>[..._committed];
    if (_pendingOperator != null) {
      parts.add(_pendingOperator!);
    }
    if (_engineActive) {
      parts.add(engineToken());
    } else if (_pendingOperator == null) {
      final last = _committed.isNotEmpty ? _committed.last : null;
      if (last != null && last != '(' && last != ')' && !isOperator(last)) {
        parts.add(_engine.formattedValue);
      }
    }

    return parts;
  }

  /// Expressão completa crua para o avaliador (tokens separados por espaço).
  String buildFullExpression() {
    final parts = <String>[..._committed];
    if (_pendingOperator != null) parts.add(_pendingOperator!);
    if (_engineActive) parts.add(engineToken());

    return parts.join(' ');
  }

  // ----- Commands -------------------------------------------------------

  /// Insere [digit] no operando ativo. Devolve `false` quando a entrada é
  /// ignorada (após `)` sem operador — não há multiplicação implícita).
  bool inputDigit(String digit) {
    if (!_canInputDigit()) return false;
    _prepareForDigitInput();
    _engine.inputDigit(digit);
    _engineActive = true;

    return true;
  }

  bool inputDoubleZero() {
    if (!_canInputDigit()) return false;
    _prepareForDigitInput();
    _engine.inputDoubleZero();
    _engineActive = true;

    return true;
  }

  bool inputTripleZero() {
    if (!_canInputDigit()) return false;
    _prepareForDigitInput();
    _engine.inputTripleZero();
    _engineActive = true;

    return true;
  }

  bool _canInputDigit() {
    // Após `)` sem operador pendente, dígitos são ignorados — não há
    // multiplicação implícita.
    if (!_engineActive && _pendingOperator == null && lastIsClosingParen) {
      return false;
    }

    return true;
  }

  void _prepareForDigitInput() {
    if (_isPercentage) {
      _engine.reset();
      _isPercentage = false;

      return;
    }

    if (_shouldResetOnInput) {
      _engine.reset();
      _shouldResetOnInput = false;

      return;
    }

    if (!_engineActive) {
      _engine.reset();
    }
  }

  void setOperator(String operator) {
    _shouldResetOnInput = false;

    if (_engineActive) {
      if (_pendingOperator != null) {
        _committed.add(_pendingOperator!);
      }
      _committed.add(engineToken());
      _engineActive = false;
    } else if (_pendingOperator == null && _committed.isEmpty) {
      // Sem conteúdo ainda — confirma o valor do engine (ex.: 0.00) para a
      // expressão começar com um operando.
      _committed.add(engineToken());
    }

    _isPercentage = false;
    _pendingOperator = operator;
  }

  /// Marca o operando ativo como porcentagem literal. Devolve `false`
  /// quando não há operando elegível (sem operador pendente, engine vazio
  /// ou `%` já aplicado).
  bool applyPercentage() {
    if (_pendingOperator == null) return false;
    if (!_engineActive) return false;
    if (_engine.isEmpty) return false;
    if (_isPercentage) return false;

    _isPercentage = true;

    return true;
  }

  /// Insere `(` no início, após operador ou após outro `(`; insere `)` com
  /// `(` pendente e operando completo no fim. Devolve `false` quando nenhum
  /// dos dois é possível.
  bool inputParenthesis() {
    if (_canCloseParen()) {
      _insertCloseParen();

      return true;
    }

    if (_canOpenParen()) {
      _insertOpenParen();

      return true;
    }

    return false;
  }

  bool _canCloseParen() {
    if (openParenCount <= 0) return false;
    if (_pendingOperator != null && !_engineActive) return false;
    if (_engineActive) return true;
    if (_committed.isEmpty) return false;

    final last = _committed.last;

    return last != '(' && !isOperator(last);
  }

  bool _canOpenParen() {
    if (_engineActive) return false;
    if (_pendingOperator != null) return true;
    if (_committed.isEmpty) return true;
    if (_committed.last == '(') return true;

    return false;
  }

  void _insertOpenParen() {
    if (_pendingOperator != null) {
      _committed.add(_pendingOperator!);
      _pendingOperator = null;
    }
    _committed.add('(');
    _engine.reset();
    _engineActive = false;
    _isPercentage = false;
    _shouldResetOnInput = false;
  }

  void _insertCloseParen() {
    if (_engineActive) {
      if (_pendingOperator != null) {
        _committed.add(_pendingOperator!);
        _pendingOperator = null;
      }
      _committed.add(engineToken());
      _engineActive = false;
    }
    _committed.add(')');
    _isPercentage = false;
    _shouldResetOnInput = false;
  }

  /// Apaga um passo da expressão (dígito, `%`, operador ou token), na ordem
  /// inversa da digitação. Devolve `false` quando não há o que apagar.
  bool backspace() {
    // O marcador `%` ativo cai primeiro.
    if (_isPercentage) {
      _isPercentage = false;

      return true;
    }

    // Operador pendente sem dígito novo — remove o operador primeiro.
    if (_pendingOperator != null && !_engineActive) {
      _pendingOperator = null;
      if (_committed.isNotEmpty) {
        final last = _committed.last;
        // Após grupo fechado ("( ... ) +"), os tokens estruturais ficam
        // intactos quando o operador é apagado.
        if (last != '(' && last != ')' && !isOperator(last)) {
          _committed.removeLast();
          restoreEngineFromToken(last);
        }
      }

      return true;
    }

    if (_engineActive && !_engine.isEmpty) {
      _engine.deleteLastDigit();
      if (_engine.isEmpty) {
        _engineActive = false;
        // Operando direito esvaziado sem operador pendente: promove o
        // operador confirmado de volta a `_pendingOperator` — senão o
        // display mostraria um "0.00" órfão após o operador.
        if (_pendingOperator == null &&
            _committed.isNotEmpty &&
            isOperator(_committed.last)) {
          _pendingOperator = _committed.removeLast();
        }
      }

      return true;
    }

    // Engine vazio — o backspace consome os tokens confirmados.
    if (_committed.isNotEmpty) {
      final last = _committed.removeLast();
      if (last == ')') {
        // Ao remover `)`, o operando interno do grupo volta ao engine para
        // o usuário continuar editando.
        if (_committed.isNotEmpty && isValueToken(_committed.last)) {
          final value = _committed.removeLast();
          restoreEngineFromToken(value);
        } else {
          _engine.reset();
          _engineActive = false;
          _isPercentage = false;
        }
      } else if (last == '(') {
        // `(` removido estruturalmente — engine permanece vazio.
        _engine.reset();
        _engineActive = false;
        _isPercentage = false;
      } else if (isOperator(last)) {
        if (_committed.isNotEmpty) {
          final value = _committed.removeLast();
          if (value == '(' || value == ')') {
            // Remoção de operador não consome parêntese — devolve-o.
            _committed.add(value);
            _engine.reset();
            _engineActive = false;
            _isPercentage = false;
          } else {
            restoreEngineFromToken(value);
          }
        }
      } else {
        restoreEngineFromToken(last);
      }

      return true;
    }

    return false;
  }

  /// Restaura o engine (e a flag de porcentagem) a partir de um token
  /// confirmado, que pode carregar sufixo `%`. Operadores e parênteses não
  /// são restauráveis — o chamador filtra.
  void restoreEngineFromToken(String token) {
    if (token == '(' || token == ')') {
      _engine.reset();
      _engineActive = false;
      _isPercentage = false;

      return;
    }

    if (token.endsWith('%')) {
      final numeric = token.substring(0, token.length - 1);
      _engine.setValue(_parseToInt(numeric));
      _isPercentage = true;
    } else {
      _engine.setValue(_parseToInt(token));
      _isPercentage = false;
    }
    _engineActive = true;
  }

  /// Distribui tokens colados entre confirmados, operador pendente e
  /// engine, espelhando como a expressão ficaria se tivesse sido digitada.
  void restoreInputTokens(List<String> tokens) {
    final last = tokens.last;
    if (isOperator(last)) {
      _committed.addAll(tokens.sublist(0, tokens.length - 1));
      _pendingOperator = last;
    } else if (last == ')') {
      _committed.addAll(tokens);
    } else {
      // Último token é operando numérico. Operador logo antes vira
      // `_pendingOperator`, deixando o engine como lado direito da
      // expressão em andamento (habilita a prévia de resultado).
      var rest = tokens.sublist(0, tokens.length - 1);
      if (rest.isNotEmpty && isOperator(rest.last)) {
        _pendingOperator = rest.last;
        rest = rest.sublist(0, rest.length - 1);
      }
      _committed.addAll(rest);
      restoreEngineFromToken(last);
    }
  }

  /// Zera toda a composição (tokens, operador, engine e flags).
  void resetAll() {
    _engine.reset();
    _committed.clear();
    _pendingOperator = null;
    _engineActive = false;
    _shouldResetOnInput = false;
    _isPercentage = false;
  }

  /// Deixa a composição no estado pós-`=`: tokens limpos, [rawResult]
  /// (forma `x.yy`) no engine e o próximo dígito iniciando um número novo.
  void setResult(String rawResult) {
    _committed.clear();
    _pendingOperator = null;
    _engineActive = false;
    _isPercentage = false;
    _shouldResetOnInput = true;
    _engine.setValue(_parseToInt(rawResult));
  }

  int _parseToInt(String formattedValue) {
    final parsed = double.tryParse(formattedValue);
    if (parsed == null) return 0;

    return (parsed * 100).round();
  }
}
