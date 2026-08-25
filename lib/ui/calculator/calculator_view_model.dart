import 'dart:collection';

import 'package:decima/data/repositories/history_repository.dart';
import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/data/services/clipboard_service.dart';
import 'package:decima/domain/add2_engine.dart';
import 'package:decima/domain/entities/calculation.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/entities/history_selection.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/expression_composer.dart';
import 'package:decima/domain/expression_editor.dart';
import 'package:decima/domain/expression_evaluator.dart';
import 'package:decima/ui/calculator/controllers/clipboard_controller.dart';
import 'package:decima/ui/calculator/controllers/cursor_controller.dart';
import 'package:decima/ui/calculator/controllers/session_recorder.dart';
import 'package:decima/ui/calculator/controllers/timeline_controller.dart';
import 'package:decima/utils/formatters/number_formatter.dart';
import 'package:flutter/foundation.dart';

/// Fachada da calculadora: única API que os widgets consomem.
///
/// Orquestra composer, editor/cursor, sessão, timeline e clipboard;
/// concentra a formatação de exibição e a notificação dos listeners.
class CalculatorViewModel extends ChangeNotifier {
  CalculatorViewModel({
    required HistoryRepository historyRepository,
    required SettingsRepository settingsRepository,
    required ClipboardService clipboardService,
    Add2Engine? add2Engine,
    ExpressionEvaluator? evaluator,
  }) : _settingsRepository = settingsRepository,
       _evaluator = evaluator ?? ExpressionEvaluator() {
    _composer = ExpressionComposer(engine: add2Engine ?? Add2Engine());
    _recorder = SessionRecorder(historyRepository: historyRepository);
    _clipboard = ClipboardController(
      clipboardService: clipboardService,
      evaluator: _evaluator,
    );
  }

  final SettingsRepository _settingsRepository;
  final ExpressionEvaluator _evaluator;
  late final ExpressionComposer _composer;
  late final SessionRecorder _recorder;
  late final ClipboardController _clipboard;
  final TimelineController _timeline = TimelineController();
  final CursorController _cursor = CursorController();

  /// Fila de ações do usuário — proteção contra reentrância síncrona
  /// (listener que despacha nova ação durante `notifyListeners`).
  final Queue<VoidCallback> _actionQueue = Queue<VoidCallback>();
  bool _isProcessingActions = false;

  DecimalSeparator _decimalSeparator = DecimalSeparator.dot;

  /// Operadores binários como aparecem na expressão. O menos é o sinal
  /// U+2212, nunca o hífen usado na formatação de resultado negativo.
  static final RegExp _operatorRegExp = RegExp(r'[+−×÷]');

  int get maxVisibleEntries => _timeline.maxVisibleEntries;

  DecimalSeparator get decimalSeparator => _decimalSeparator;

  set decimalSeparator(DecimalSeparator value) {
    if (_decimalSeparator == value) return;
    _decimalSeparator = value;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    _decimalSeparator = await _settingsRepository.getDecimalSeparator();
    notifyListeners();
  }

  String get currentDisplayValue => _formatValue(_composer.currentValue);

  String? get currentOperator => _composer.pendingOperator;

  /// Parênteses abertos sem fechamento na expressão atual. Em modo de
  /// edição o buffer de edição é a fonte da verdade — os tokens confirmados
  /// ficam defasados nesse modo.
  int get openParenCount {
    final text = _cursor.editText;
    if (text != null) {
      return ExpressionEditor.countOpenParens(text);
    }

    return _composer.openParenCount;
  }

  /// `true` quando há algo que o usuário possa apagar: tokens confirmados,
  /// operando ativo, operador pendente, resultado pós-`=` ou timeline.
  bool get hasContent {
    final editText = _cursor.editText;
    if (editText != null && editText.isNotEmpty && editText != '0.00') {
      return true;
    }
    if (_composer.hasExpression) return true;
    if (_timeline.hasEntries) return true;
    if (_composer.shouldResetOnInput) return true;

    return false;
  }

  /// Texto completo do display — a expressão inteira em uma linha
  /// (ex.: `7856.00 × 52.00`, `100.00 + 10.00%`).
  String get fullDisplayText {
    final editText = _cursor.editText;
    if (editText != null) return editText;

    final parts = _composer.displayTokens().map(_formatPart).toList();
    if (parts.isEmpty) return currentDisplayValue;

    return parts.join(' ');
  }

  /// Expressão em andamento sem o operando ativo do motor — para widgets
  /// que exibem a expressão digitada separadamente.
  String get expression {
    final parts = <String>[
      for (final t in _composer.committedTokens) _formatPart(t),
      if (_composer.pendingOperator != null) _composer.pendingOperator!,
    ];

    return parts.join(' ');
  }

  String? get previewResult {
    final editText = _cursor.editText;
    if (editText != null) {
      final raw = ExpressionEditor.normalizeForEvaluator(
        editText,
        _decimalSeparator,
      );
      if (raw.trim().isEmpty) return null;
      final result = _evaluator.evaluate(raw);
      if (result == null) return null;

      return _formatValue(result);
    }

    if (_composer.committedTokens.isEmpty) return null;

    final hasActiveInput =
        _composer.isEngineActive && _composer.pendingOperator != null;
    final hasClosedExpression =
        !_composer.isEngineActive &&
        _composer.pendingOperator == null &&
        _composer.lastIsClosingParen;

    if (!hasActiveInput && !hasClosedExpression) return null;

    final result = _evaluator.evaluate(_composer.buildFullExpression());
    if (result == null) return null;

    return _formatValue(result);
  }

  List<Calculation> get timelineEntries => _timeline.entries;

  List<Calculation> get visibleTimelineEntries => _timeline.visibleEntries;

  bool get hasMoreTimelineEntries => _timeline.hasMore;

  /// Despacha uma ação do usuário; reentradas síncronas entram na fila e
  /// rodam após a atual, preservando a ordem dos toques.
  void _runAction(VoidCallback action) {
    if (_isProcessingActions) {
      _actionQueue.add(action);

      return;
    }

    _isProcessingActions = true;
    try {
      action();
      while (_actionQueue.isNotEmpty) {
        _actionQueue.removeFirst()();
      }
    } finally {
      _isProcessingActions = false;
    }
  }

  /// Roteia uma ação de digitação: em modo de edição aplica [editorOp] via
  /// [ExpressionEditor]; fora dele executa [composeOp] no
  /// [ExpressionComposer], notificando apenas quando o estado mudou.
  void _dispatchInput(
    EditorState Function(EditorState state) editorOp,
    bool Function() composeOp,
  ) {
    _runAction(() {
      if (_cursor.isEditing) {
        _cursor.applyEditorState(editorOp(_cursor.editorState));
        notifyListeners();

        return;
      }
      if (composeOp()) notifyListeners();
    });
  }

  void inputDigit(String digit) => _dispatchInput(
    (s) => ExpressionEditor.insertDigits(s, digit, _decimalSeparator),
    () => _composer.inputDigit(digit),
  );

  void inputDoubleZero() => _dispatchInput(
    (s) => ExpressionEditor.insertDigits(s, '00', _decimalSeparator),
    _composer.inputDoubleZero,
  );

  void inputTripleZero() => _dispatchInput(
    (s) => ExpressionEditor.insertDigits(s, '000', _decimalSeparator),
    _composer.inputTripleZero,
  );

  void setOperator(String operator) => _dispatchInput(
    (s) => ExpressionEditor.insertOperator(s, operator, _decimalSeparator),
    () {
      _composer.setOperator(operator);

      return true;
    },
  );

  void applyPercentage() =>
      _dispatchInput(ExpressionEditor.applyPercent, _composer.applyPercentage);

  /// Insere `(` ou `)` conforme o estado atual — ver
  /// [ExpressionComposer.inputParenthesis].
  void inputParenthesis() => _dispatchInput(
    ExpressionEditor.insertParenthesis,
    _composer.inputParenthesis,
  );

  void equals() {
    _runAction(_commitPendingCalculation);
  }

  /// Persiste a sessão em andamento e aguarda a escrita concluir, fechando
  /// a expressão pendente como um `=` faria. Idempotente: sem nada novo,
  /// apenas aguarda escritas já emitidas.
  Future<void> flushSession() {
    // `equals()` já ignora entrada sem operador, auto-fecha parênteses e é
    // no-op quando nada mudou.
    equals();

    return _recorder.pendingWrite;
  }

  /// Fecha o cálculo pendente: avalia, registra a linha na timeline e na
  /// sessão e deixa o estado como um `=`. No-op sem nada avaliável.
  void _commitPendingCalculation() {
    final raw = _pendingRawExpression();
    if (raw == null) return;

    final result = _evaluator.evaluate(raw);
    if (result == null) return;

    _timeline.add(
      Calculation(
        expression: _formatExpression(raw),
        result: _formatValue(result),
        timestamp: DateTime.now(),
      ),
    );

    _recorder.append(HistoryLine(expression: raw, result: result));
    _recorder.persist();

    _cursor.exitEditMode();
    _composer.setResult(result);
    notifyListeners();
  }

  /// Expressão pendente pronta para o avaliador — separadores normalizados,
  /// parênteses auto-fechados — ou `null` sem nada avaliável. Operador
  /// solto no fim ("12.50 +") é mantido; o avaliador o tolera.
  String? _pendingRawExpression() {
    final editText = _cursor.editText;
    final raw = editText != null
        ? ExpressionEditor.normalizeForEvaluator(editText, _decimalSeparator)
        : _composer.buildFullExpression();
    if (raw.trim().isEmpty) return null;
    if (!_operatorRegExp.hasMatch(raw)) return null;

    final open = openParenCount;

    return open > 0 ? '$raw${' )' * open}' : raw;
  }

  void clear() {
    _runAction(() {
      if (!hasContent && !_cursor.isEditing) return;

      // Persiste a sessão atual antes de limpar.
      _recorder.persist();

      _cursor.exitEditMode();
      _composer.resetAll();
      _timeline.clear();
      _recorder.startNewSession();
      notifyListeners();
    });
  }

  void backspace() => _dispatchInput(
    (s) => ExpressionEditor.backspace(s, _decimalSeparator),
    _composer.backspace,
  );

  void loadMoreTimelineEntries() {
    _timeline.loadMore();
    notifyListeners();
  }

  // ----- Cursor / modo de edição ---------------------------------------

  /// Posição do cursor como offset de caractere em [fullDisplayText].
  int get cursorPosition => _cursor.positionIn(fullDisplayText);

  /// `true` quando o cursor está em modo de edição (fora do fim da
  /// expressão).
  bool get isEditingMidExpression => _cursor.isEditing;

  /// `true` quando o cursor está no fim de [fullDisplayText]; nesse estado
  /// ele fica oculto mesmo com o modo de edição ativo.
  bool get isCursorAtEnd => _cursor.isAtEnd;

  void moveCursorLeft() {
    _runAction(() {
      if (_cursor.moveLeft(fullDisplayText)) notifyListeners();
    });
  }

  void moveCursorRight() {
    _runAction(() {
      if (_cursor.moveRight(fullDisplayText)) notifyListeners();
    });
  }

  /// Move o cursor para o fim de [fullDisplayText], ocultando-o sem sair
  /// do modo de edição.
  void moveCursorToEnd() {
    _runAction(() {
      if (_cursor.moveToEnd()) notifyListeners();
    });
  }

  /// Posiciona o cursor num offset explícito de [fullDisplayText];
  /// valores fora do intervalo são clampados.
  void setCursorPosition(int position) {
    _runAction(() {
      if (_cursor.setPosition(fullDisplayText, position)) notifyListeners();
    });
  }

  /// Carrega uma sessão do histórico, restaurando a timeline até a linha
  /// de [HistorySelection.lineIndex] (inclusive); o resultado dela vira o
  /// valor do display, pronto para continuar o cálculo.
  void loadSession(HistorySelection selection) {
    // Persiste a sessão existente antes de sobrescrevê-la.
    _recorder.persist();

    _cursor.exitEditMode();
    _timeline.clear();

    final entry = selection.entry;
    final upToIndex = selection.lineIndex.clamp(0, entry.lines.length - 1);

    final lines = <HistoryLine>[];
    for (var i = 0; i <= upToIndex; i++) {
      final line = entry.lines[i];
      _timeline.add(
        Calculation(
          expression: _formatExpression(line.expression),
          result: _formatValue(line.result),
          timestamp: entry.createdAt,
        ),
      );
      lines.add(line);
    }

    // Linhas carregadas já estão persistidas: os próximos `=` caem no
    // caminho de update da mesma sessão, não de criação.
    _recorder.adoptSession(sessionId: entry.id, lines: lines);

    _composer.setResult(lines.last.result);
    notifyListeners();
  }

  // ----- Formatação de exibição ----------------------------------------

  /// Formata um token para exibição: números passam pelo formatador,
  /// operadores/parênteses passam direto, sufixo `%` é preservado.
  String _formatPart(String value) {
    if (ExpressionComposer.isOperator(value)) return value;
    if (value == '(' || value == ')') return value;

    if (value.endsWith('%')) {
      final numeric = value.substring(0, value.length - 1);

      return '${_formatValue(numeric)}%';
    }

    return _formatValue(value);
  }

  String _formatValue(String plainValue) {
    final parsed = double.tryParse(plainValue);
    if (parsed == null) return plainValue;

    return NumberFormatter.formatDouble(
      parsed,
      separator: _decimalSeparator,
      useThousandsSeparator: true,
    );
  }

  String _formatExpression(String plainExpression) {
    final tokens = plainExpression.split(' ');
    final formatted = tokens.map(_formatPart);

    return formatted.join(' ');
  }

  // ----- Clipboard ------------------------------------------------------

  /// `true` quando há algo digitado que possa ser copiado como expressão.
  bool get hasExpression => _composer.hasExpression;

  /// `true` quando há resultado numérico disponível — prévia ao vivo ou
  /// resultado do último `=`.
  bool get hasResult {
    if (previewResult != null) return true;
    if (_composer.shouldResetOnInput && !_composer.isEngineEmpty) return true;

    return false;
  }

  /// `true` quando há ao menos um cálculo na timeline da sessão.
  bool get hasHistory => _timeline.hasEntries;

  /// Copia a expressão atual (ex.: `1000.00 + 10.00%`) para a área de
  /// transferência. No-op quando [hasExpression] é `false`.
  Future<void> copyExpression() async {
    if (!hasExpression) return;

    await _clipboard.copyText(fullDisplayText);
  }

  /// Copia o resultado atual (prévia ou valor pós-`=`) para a área de
  /// transferência. No-op quando [hasResult] é `false`.
  Future<void> copyResult() async {
    final preview = previewResult;
    if (preview != null) {
      await _clipboard.copyText(preview);

      return;
    }

    if (_composer.shouldResetOnInput && !_composer.isEngineEmpty) {
      await _clipboard.copyText(currentDisplayValue);
    }
  }

  /// Copia a timeline da sessão, uma linha por cálculo no formato
  /// `<expressão> = <resultado>`.
  Future<void> copyHistory() => _clipboard.copyHistory(_timeline.entries);

  /// Lê, interpreta e aplica o conteúdo da área de transferência. Retorna
  /// `false` quando vazia ou inválida. Linhas resolvidas viram timeline;
  /// linha final sem `=` vira a entrada atual.
  Future<bool> pasteFromClipboard() async {
    final pasted = await _clipboard.readPastedSession();
    if (pasted == null) return false;

    _runAction(() => _applyPastedContent(pasted.lines, pasted.inputTokens));

    return true;
  }

  /// `true` quando a área de transferência contém texto — habilita a opção
  /// "Colar" do menu de contexto sem efetivar a colagem.
  Future<bool> clipboardHasText() => _clipboard.hasText();

  /// Substitui o estado da calculadora pelo conteúdo colado: [lines] viram
  /// timeline e sessão pendente; [inputTokens] vira a entrada em andamento
  /// (quando `null`, o display fica no estado pós-`=` da última linha).
  void _applyPastedContent(List<HistoryLine> lines, List<String>? inputTokens) {
    // Persiste a sessão pendente antes de substituí-la — trabalho já
    // confirmado nunca se perde silenciosamente.
    _recorder.persist();
    _cursor.exitEditMode();
    _composer.resetAll();
    _timeline.clear();
    _recorder.startNewSession();

    for (final line in lines) {
      _timeline.add(
        Calculation(
          expression: _formatExpression(line.expression),
          result: _formatValue(line.result),
          timestamp: DateTime.now(),
        ),
      );
      _recorder.append(line);
    }

    if (inputTokens != null) {
      _composer.restoreInputTokens(inputTokens);
    } else if (lines.isNotEmpty) {
      _composer.setResult(lines.last.result);
    }

    notifyListeners();
  }
}
