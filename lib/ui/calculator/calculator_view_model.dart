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

/// Fachada da calculadora para a UI: única API que os widgets consomem.
///
/// Orquestra os colaboradores — [ExpressionComposer] (composição por
/// digitação), [ExpressionEditor] via [CursorController] (edição por
/// cursor), [SessionRecorder] (persistência da sessão), [TimelineController]
/// (linhas visíveis) e [ClipboardController] (copiar/colar) — e concentra a
/// formatação de exibição e a notificação dos listeners.
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

  /// Fila de ações do usuário.
  ///
  /// Garante que toques disparados durante o processamento de outra ação
  /// (por exemplo, via `notifyListeners` que reentra na ViewModel) sejam
  /// processados em ordem, sem perda. Dart é single-threaded, então a fila
  /// serve apenas como proteção contra reentrância síncrona.
  final Queue<VoidCallback> _actionQueue = Queue<VoidCallback>();
  bool _isProcessingActions = false;

  DecimalSeparator _decimalSeparator = DecimalSeparator.dot;

  /// Binary operators as they appear in an expression. Note the minus is the
  /// U+2212 sign, never the hyphen a negative result is formatted with.
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

  /// Number of unmatched opening parentheses in the current expression.
  ///
  /// While editing mid-expression, the edit buffer is the source of truth —
  /// the committed token list is stale in that mode, so counting it would
  /// report a balance that does not match what the user sees.
  int get openParenCount {
    final text = _cursor.editText;
    if (text != null) {
      return ExpressionEditor.countOpenParens(text);
    }

    return _composer.openParenCount;
  }

  /// True when there is anything in the calculator that the user could clear:
  /// committed tokens, an active operand, a pending operator, an in-flight
  /// post-equals result, or session timeline entries.
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

  /// Full display text — the entire expression on a single line.
  /// e.g., "7856.00", "7856.00 ×", "7856.00 × 52.00", "100.00 + 10.00%".
  String get fullDisplayText {
    final editText = _cursor.editText;
    if (editText != null) return editText;

    final parts = _composer.displayTokens().map(_formatPart).toList();
    if (parts.isEmpty) return currentDisplayValue;

    return parts.join(' ');
  }

  /// In-progress expression without the active engine value.
  /// Used by widgets that show the typed expression separately.
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

  /// Despacha uma ação do usuário. Se já houver outra ação em execução
  /// (cenário de reentrância síncrona via listener), enfileira para ser
  /// processada logo após a atual terminar, preservando a ordem dos toques.
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

  /// Toggle insertion of an opening or closing parenthesis depending on
  /// the current state — see [ExpressionComposer.inputParenthesis].
  void inputParenthesis() => _dispatchInput(
    ExpressionEditor.insertParenthesis,
    _composer.inputParenthesis,
  );

  void equals() {
    _runAction(_commitPendingCalculation);
  }

  /// Persists the in-progress session and waits for the write to land.
  ///
  /// Called when the desktop window is closing and when the app goes to the
  /// background on mobile. The pending expression is closed exactly as a `=`
  /// press would close it — unbalanced parentheses auto-closed, the result
  /// appended to the timeline. A number typed without any operator is **not**
  /// a calculation and never becomes a history entry.
  ///
  /// Idempotent: with nothing new to write it only awaits the writes already
  /// issued, including an `add` still in flight.
  Future<void> flushSession() {
    // `equals()` já é a operação "fecha o cálculo pendente": ignora entradas
    // sem operador, auto-fecha parênteses e é no-op quando nada mudou.
    equals();

    return _recorder.pendingWrite;
  }

  /// Closes the in-progress calculation: evaluates the pending expression,
  /// records the line in the timeline and in the session, and leaves the
  /// state exactly as a `=` press does. No-op when there is nothing
  /// evaluable — empty display, or no operator typed.
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

    // Store the raw expression/result pair for session-based saving, then
    // persist: create on the first =, update on subsequent ones.
    _recorder.append(HistoryLine(expression: raw, result: result));
    _recorder.persist();

    _cursor.exitEditMode();
    _composer.setResult(result);
    notifyListeners();
  }

  /// The pending expression ready for the evaluator — separators normalized
  /// and unbalanced parentheses auto-closed — or `null` when there is
  /// nothing to evaluate: empty display, or no operator typed anywhere.
  ///
  /// A trailing operator with no right-hand side ("12.50 +") is kept as is;
  /// the evaluator handles it gracefully.
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

      // Save/update the current session to history before clearing.
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

  // ----- Cursor / edit mode --------------------------------------------

  /// Current cursor position as a character offset in [fullDisplayText].
  int get cursorPosition => _cursor.positionIn(fullDisplayText);

  /// True when the cursor is in "edit mode" (positioned somewhere other
  /// than the end of the expression).
  bool get isEditingMidExpression => _cursor.isEditing;

  /// True when the cursor is at the end of [fullDisplayText]. The cursor is
  /// hidden in this state even while edit mode is active.
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

  /// Moves the cursor to the end of [fullDisplayText], hiding it without
  /// exiting edit mode.
  void moveCursorToEnd() {
    _runAction(() {
      if (_cursor.moveToEnd()) notifyListeners();
    });
  }

  /// Sets the cursor to an explicit character offset in [fullDisplayText].
  /// Out-of-range values are clamped.
  void setCursorPosition(int position) {
    _runAction(() {
      if (_cursor.setPosition(fullDisplayText, position)) notifyListeners();
    });
  }

  /// Loads a history session into the calculator, restoring the timeline
  /// up to (and including) the specified [selection.lineIndex].
  ///
  /// The last loaded line's expression is placed into the display field
  /// as if the user had just typed it, ready for editing or continuation.
  void loadSession(HistorySelection selection) {
    // Save any existing session before overwriting.
    _recorder.persist();

    _cursor.exitEditMode();
    _timeline.clear();

    final entry = selection.entry;
    final upToIndex = selection.lineIndex.clamp(0, entry.lines.length - 1);

    // Load the lines up to (and including) the selected one into the
    // timeline; the selected line's result becomes the display value.
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

    // Track the loaded session so subsequent = presses update it. Loaded
    // lines are already persisted, so the next saves hit the update branch.
    _recorder.adoptSession(sessionId: entry.id, lines: lines);

    _composer.setResult(lines.last.result);
    notifyListeners();
  }

  // ----- Display formatting --------------------------------------------

  /// Formats a single committed (or active) token for display: numbers go
  /// through the configured number formatter, operators and parentheses pass
  /// through, and `%`-suffixed values keep the literal percent sign.
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

  /// True when there is anything currently typed (committed tokens, an
  /// active operand, or a pending operator) that could be copied as an
  /// expression.
  bool get hasExpression => _composer.hasExpression;

  /// True when there is a numeric result available — either a live preview
  /// or the result of the most recent `=`.
  bool get hasResult {
    if (previewResult != null) return true;
    if (_composer.shouldResetOnInput && !_composer.isEngineEmpty) return true;

    return false;
  }

  /// True when there is at least one calculation in the session timeline.
  bool get hasHistory => _timeline.hasEntries;

  /// Copies the current expression text (e.g., `1000.00 + 10.00%`) to the
  /// clipboard. No-op when [hasExpression] is false.
  Future<void> copyExpression() async {
    if (!hasExpression) return;

    await _clipboard.copyText(fullDisplayText);
  }

  /// Copies the current result (preview or post-`=` value) to the clipboard.
  /// No-op when [hasResult] is false.
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

  /// Copies all session timeline entries to the clipboard, one per line in
  /// the format `<expression> = <result>`.
  Future<void> copyHistory() => _clipboard.copyHistory(_timeline.entries);

  /// Reads text from the clipboard, parses and applies it to the calculator
  /// state. Returns `true` on success, `false` when the clipboard is empty
  /// or its contents cannot be interpreted as a number/expression.
  ///
  /// Lines already resolved (`<expressão> = <resultado>`) become timeline
  /// entries; a trailing line without `=` becomes the current input. The
  /// pasted results are **recalculated** from their expressions, so a stale
  /// or wrong value in the clipboard never reaches the history.
  Future<bool> pasteFromClipboard() async {
    final pasted = await _clipboard.readPastedSession();
    if (pasted == null) return false;

    _runAction(() => _applyPastedContent(pasted.lines, pasted.inputTokens));

    return true;
  }

  /// True when the clipboard currently contains text. Used by the context
  /// menu to enable/disable the paste entry without committing to a paste.
  Future<bool> clipboardHasText() => _clipboard.hasText();

  /// Replaces the whole calculator state with the pasted content: [lines]
  /// become timeline entries (and pending session lines, persisted on the
  /// next `=`/`clear()`), and [inputTokens] becomes the in-progress input.
  ///
  /// When [inputTokens] is null the display shows the last line's result in
  /// the same state a `=` press leaves behind — the next digit starts a new
  /// number instead of appending to it.
  void _applyPastedContent(List<HistoryLine> lines, List<String>? inputTokens) {
    // Replace existing in-progress state. Persist any pending session first
    // so the user does not silently lose committed work.
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
