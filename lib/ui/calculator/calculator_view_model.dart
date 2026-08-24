import 'dart:collection';

import 'package:decima/data/repositories/history_repository.dart';
import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/data/services/clipboard_service.dart';
import 'package:decima/domain/add2_engine.dart';
import 'package:decima/domain/entities/calculation.dart';
import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/entities/history_selection.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/expression_editor.dart';
import 'package:decima/domain/expression_evaluator.dart';
import 'package:decima/domain/paste_input_parser.dart';
import 'package:decima/utils/formatters/number_formatter.dart';
import 'package:flutter/foundation.dart';

class CalculatorViewModel extends ChangeNotifier {
  CalculatorViewModel({
    required HistoryRepository historyRepository,
    required SettingsRepository settingsRepository,
    required ClipboardService clipboardService,
  }) : _historyRepository = historyRepository,
       _settingsRepository = settingsRepository,
       _clipboardService = clipboardService;

  final HistoryRepository _historyRepository;
  final SettingsRepository _settingsRepository;
  final ClipboardService _clipboardService;
  final Add2Engine _add2Engine = Add2Engine();
  final ExpressionEvaluator _evaluator = ExpressionEvaluator();

  final List<Calculation> _timelineEntries = [];

  /// Raw expression/result pairs accumulated during the current session.
  /// These are persisted as a single [HistoryEntry] on each `=` press
  /// (created the first time, updated on subsequent presses) and on `clear()`.
  final List<HistoryLine> _sessionLines = [];

  /// Committed tokens of the in-progress expression. Each entry is one of:
  /// a numeric value (optionally suffixed with `%`), an operator
  /// (`+`, `−`, `×`, `÷`), or a parenthesis (`(`, `)`).
  final List<String> _committed = [];

  /// Fila de ações do usuário.
  ///
  /// Garante que toques disparados durante o processamento de outra ação
  /// (por exemplo, via `notifyListeners` que reentra na ViewModel) sejam
  /// processados em ordem, sem perda. Dart é single-threaded, então a fila
  /// serve apenas como proteção contra reentrância síncrona.
  final Queue<VoidCallback> _actionQueue = Queue<VoidCallback>();
  bool _isProcessingActions = false;

  /// Database ID of the current session. `null` when no session has been
  /// persisted yet. Set after the first `=` press and reset on `clear()`.
  int? _currentSessionId;

  /// Number of session lines already persisted. Used to skip redundant
  /// save calls (e.g., `clear()` right after `=` should not re-add).
  int _persistedLineCount = 0;

  /// In-flight `add` for the current session, resolving with the id assigned
  /// by the database. `null` when no creation is pending. Subsequent saves
  /// chain onto it instead of issuing a second `add`.
  Future<int?>? _pendingAdd;

  /// Chain of every write already issued. [flushSession] awaits it so the
  /// app shutting down never interrupts a persistence call in progress.
  Future<void> _pendingWrite = Future<void>.value();

  /// Incremented whenever the session is reset (clear, load, paste). Lets an
  /// in-flight `add` know its id belongs to a session that no longer exists.
  int _sessionGeneration = 0;

  /// Operator typed but not yet committed (waiting for the right-hand side).
  String? _pendingOperator;

  /// True while the value held by [_add2Engine] represents the operand
  /// currently being typed (uncommitted).
  bool _engineActive = false;

  /// Indicates the engine value is a stale result (post `=` or session load)
  /// and the next digit input should reset the engine to start fresh.
  bool _shouldResetOnInput = false;

  /// Marks the active engine value as a literal percentage operand.
  bool _currentIsPercentage = false;

  int _visibleCount = 20;
  DecimalSeparator _decimalSeparator = DecimalSeparator.dot;

  /// Editable text buffer used when the cursor is positioned somewhere
  /// other than the end of the expression. While non-null, this string
  /// is the source of truth for [fullDisplayText] and operations route
  /// through string-level edits.
  String? _editText;

  /// Cursor character offset inside [_editText]. Only valid while
  /// [_editText] is non-null. When [_atEnd] is true, the visible cursor
  /// follows the end of [fullDisplayText] regardless of this value.
  int _cursorPos = 0;

  /// True when the cursor virtually follows the end of [fullDisplayText].
  /// When false, [_cursorPos] (or [_editText]'s offset) is authoritative.
  bool _atEnd = true;

  static const int _loadMoreCount = 20;

  int get maxVisibleEntries => _visibleCount;

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

  String get currentDisplayValue => _formatValue(_add2Engine.formattedValue);

  String? get currentOperator => _pendingOperator;

  /// Number of unmatched opening parentheses in the current expression.
  ///
  /// While editing mid-expression, [_editText] is the source of truth — the
  /// committed token list is stale in that mode, so counting it would report
  /// a balance that does not match what the user sees.
  int get openParenCount {
    final text = _editText;
    if (text != null) {
      return ExpressionEditor.countOpenParens(text);
    }

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

  /// True when there is anything in the calculator that the user could clear:
  /// committed tokens, an active operand, a pending operator, an in-flight
  /// post-equals result, or session timeline entries.
  bool get hasContent {
    if (_editText != null && _editText!.isNotEmpty && _editText != '0.00') {
      return true;
    }
    if (_committed.isNotEmpty) return true;
    if (_engineActive) return true;
    if (_pendingOperator != null) return true;
    if (_timelineEntries.isNotEmpty) return true;
    if (_shouldResetOnInput) return true;

    return false;
  }

  /// Full display text — the entire expression on a single line.
  /// e.g., "7856.00", "7856.00 ×", "7856.00 × 52.00", "100.00 + 10.00%".
  String get fullDisplayText {
    if (_editText != null) return _editText!;

    final parts = <String>[];
    for (final t in _committed) {
      parts.add(_formatPart(t));
    }
    if (_pendingOperator != null) {
      parts.add(_pendingOperator!);
    }
    if (_engineActive) {
      parts.add(_formatPart(_engineToken()));
    } else if (_pendingOperator == null) {
      final last = _committed.isNotEmpty ? _committed.last : null;
      if (last != null && last != '(' && last != ')' && !_isOperator(last)) {
        parts.add(currentDisplayValue);
      }
    }

    if (parts.isEmpty) return currentDisplayValue;

    return parts.join(' ');
  }

  /// In-progress expression without the active engine value.
  /// Used by widgets that show the typed expression separately.
  String get expression {
    final parts = <String>[];
    for (final t in _committed) {
      parts.add(_formatPart(t));
    }
    if (_pendingOperator != null) {
      parts.add(_pendingOperator!);
    }

    return parts.join(' ');
  }

  String? get previewResult {
    if (_editText != null) {
      final raw = ExpressionEditor.normalizeForEvaluator(
        _editText!,
        _decimalSeparator,
      );
      if (raw.trim().isEmpty) return null;
      final result = _evaluator.evaluate(raw);
      if (result == null) return null;

      return _formatValue(result);
    }

    if (_committed.isEmpty) return null;

    final hasActiveInput = _engineActive && _pendingOperator != null;
    final hasClosedExpression =
        !_engineActive && _pendingOperator == null && _lastIsClosingParen();

    if (!hasActiveInput && !hasClosedExpression) return null;

    final raw = _buildFullExpression();
    final result = _evaluator.evaluate(raw);
    if (result == null) return null;

    return _formatValue(result);
  }

  List<Calculation> get timelineEntries => List.unmodifiable(_timelineEntries);

  List<Calculation> get visibleTimelineEntries {
    if (_timelineEntries.length <= _visibleCount) {
      return List.unmodifiable(_timelineEntries);
    }

    final start = _timelineEntries.length - _visibleCount;

    return List.unmodifiable(_timelineEntries.sublist(start));
  }

  bool get hasMoreTimelineEntries => _timelineEntries.length > _visibleCount;

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

  void inputDigit(String digit) {
    _runAction(() {
      if (_editText != null) {
        _applyEditorState(
          ExpressionEditor.insertDigits(_editorState, digit, _decimalSeparator),
        );
        notifyListeners();

        return;
      }
      if (!_canInputDigit()) return;
      _prepareForDigitInput();
      _add2Engine.inputDigit(digit);
      _engineActive = true;
      notifyListeners();
    });
  }

  void inputDoubleZero() {
    _runAction(() {
      if (_editText != null) {
        _applyEditorState(
          ExpressionEditor.insertDigits(_editorState, '00', _decimalSeparator),
        );
        notifyListeners();

        return;
      }
      if (!_canInputDigit()) return;
      _prepareForDigitInput();
      _add2Engine.inputDoubleZero();
      _engineActive = true;
      notifyListeners();
    });
  }

  void inputTripleZero() {
    _runAction(() {
      if (_editText != null) {
        _applyEditorState(
          ExpressionEditor.insertDigits(_editorState, '000', _decimalSeparator),
        );
        notifyListeners();

        return;
      }
      if (!_canInputDigit()) return;
      _prepareForDigitInput();
      _add2Engine.inputTripleZero();
      _engineActive = true;
      notifyListeners();
    });
  }

  bool _canInputDigit() {
    // After ')' with no pending operator, digits are ignored — the user must
    // press an operator first (no implicit multiplication).
    if (!_engineActive && _pendingOperator == null && _lastIsClosingParen()) {
      return false;
    }

    return true;
  }

  void _prepareForDigitInput() {
    if (_currentIsPercentage) {
      _add2Engine.reset();
      _currentIsPercentage = false;

      return;
    }

    if (_shouldResetOnInput) {
      _add2Engine.reset();
      _shouldResetOnInput = false;

      return;
    }

    if (!_engineActive) {
      _add2Engine.reset();
    }
  }

  void setOperator(String operator) {
    _runAction(() {
      if (_editText != null) {
        _applyEditorState(
          ExpressionEditor.insertOperator(
            _editorState,
            operator,
            _decimalSeparator,
          ),
        );
        notifyListeners();

        return;
      }
      _shouldResetOnInput = false;

      if (_engineActive) {
        if (_pendingOperator != null) {
          _committed.add(_pendingOperator!);
        }
        _committed.add(_engineToken());
        _engineActive = false;
      } else if (_pendingOperator == null && _committed.isEmpty) {
        // No content yet — commit current engine value (e.g., 0.00) so the
        // expression starts with an operand.
        _committed.add(_engineToken());
      }

      _currentIsPercentage = false;
      _pendingOperator = operator;
      notifyListeners();
    });
  }

  void applyPercentage() {
    _runAction(() {
      if (_editText != null) {
        _applyEditorState(ExpressionEditor.applyPercent(_editorState));
        notifyListeners();

        return;
      }
      if (_pendingOperator == null) return;
      if (!_engineActive) return;
      if (_add2Engine.isEmpty) return;
      if (_currentIsPercentage) return;

      _currentIsPercentage = true;
      notifyListeners();
    });
  }

  /// Toggle insertion of an opening or closing parenthesis depending on
  /// the current state. Inserts `(` when at start, after an operator, or
  /// after another `(`. Inserts `)` when there is at least one unmatched
  /// `(` and the last token is a complete operand.
  void inputParenthesis() {
    _runAction(() {
      if (_editText != null) {
        _applyEditorState(ExpressionEditor.insertParenthesis(_editorState));
        notifyListeners();

        return;
      }
      if (_canCloseParen()) {
        _insertCloseParen();
        notifyListeners();

        return;
      }

      if (_canOpenParen()) {
        _insertOpenParen();
        notifyListeners();
      }
    });
  }

  bool _canCloseParen() {
    if (openParenCount <= 0) return false;
    if (_pendingOperator != null && !_engineActive) return false;
    if (_engineActive) return true;
    if (_committed.isEmpty) return false;

    final last = _committed.last;

    return last != '(' && !_isOperator(last);
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
    _add2Engine.reset();
    _engineActive = false;
    _currentIsPercentage = false;
    _shouldResetOnInput = false;
  }

  void _insertCloseParen() {
    if (_engineActive) {
      if (_pendingOperator != null) {
        _committed.add(_pendingOperator!);
        _pendingOperator = null;
      }
      _committed.add(_engineToken());
      _engineActive = false;
    }
    _committed.add(')');
    _currentIsPercentage = false;
    _shouldResetOnInput = false;
  }

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

    return _pendingWrite;
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

    _timelineEntries.add(
      Calculation(
        expression: _formatExpression(raw),
        result: _formatValue(result),
        timestamp: DateTime.now(),
      ),
    );

    // Store the raw expression/result pair for session-based saving, then
    // persist: create on the first =, update on subsequent ones.
    _sessionLines.add(HistoryLine(expression: raw, result: result));
    _saveOrUpdateSession();

    _exitEditMode();
    _committed.clear();
    _pendingOperator = null;
    _engineActive = false;
    _shouldResetOnInput = true;
    _currentIsPercentage = false;
    _add2Engine.setValue(_parseToInt(result));
    _atEnd = true;
    notifyListeners();
  }

  /// The pending expression ready for the evaluator — separators normalized
  /// and unbalanced parentheses auto-closed — or `null` when there is
  /// nothing to evaluate: empty display, or no operator typed anywhere.
  ///
  /// A trailing operator with no right-hand side ("12.50 +") is kept as is;
  /// the evaluator handles it gracefully.
  String? _pendingRawExpression() {
    final raw = _editText != null
        ? ExpressionEditor.normalizeForEvaluator(_editText!, _decimalSeparator)
        : _buildFullExpression();
    if (raw.trim().isEmpty) return null;
    if (!_operatorRegExp.hasMatch(raw)) return null;

    final open = openParenCount;

    return open > 0 ? '$raw${' )' * open}' : raw;
  }

  void clear() {
    _runAction(() {
      if (!hasContent && _editText == null) return;

      // Save/update the current session to history before clearing.
      _saveOrUpdateSession();

      _exitEditMode();
      _atEnd = true;
      _add2Engine.reset();
      _committed.clear();
      _pendingOperator = null;
      _engineActive = false;
      _shouldResetOnInput = false;
      _currentIsPercentage = false;
      _timelineEntries.clear();
      _sessionLines.clear();
      _resetSessionTracking();
      notifyListeners();
    });
  }

  void backspace() {
    _runAction(() {
      if (_editText != null) {
        _applyEditorState(
          ExpressionEditor.backspace(_editorState, _decimalSeparator),
        );
        notifyListeners();

        return;
      }
      // Drop the literal `%` marker first if active.
      if (_currentIsPercentage) {
        _currentIsPercentage = false;
        notifyListeners();

        return;
      }

      // Pending operator with no new digits — remove the operator first.
      if (_pendingOperator != null && !_engineActive) {
        _pendingOperator = null;
        if (_committed.isNotEmpty) {
          final last = _committed.last;
          // Keep structural expression tokens intact when the trailing
          // operator is deleted after a closed group, e.g. "( ... ) +".
          if (last != '(' && last != ')' && !_isOperator(last)) {
            _committed.removeLast();
            _restoreEngineFromToken(last);
          }
        }
        notifyListeners();

        return;
      }

      if (_engineActive && !_add2Engine.isEmpty) {
        _add2Engine.deleteLastDigit();
        if (_add2Engine.isEmpty) {
          _engineActive = false;
          // If we just emptied the right-hand operand AND there is no
          // pending operator, promote a dangling committed operator back
          // to `_pendingOperator`. Otherwise the display would show an
          // orphan "0.00" after the operator.
          if (_pendingOperator == null &&
              _committed.isNotEmpty &&
              _isOperator(_committed.last)) {
            _pendingOperator = _committed.removeLast();
          }
        }
        notifyListeners();

        return;
      }

      // Engine empty — backspace into committed tokens.
      if (_committed.isNotEmpty) {
        final last = _committed.removeLast();
        if (last == ')') {
          // Removing a closing paren: restore the operand just inside the
          // group (if any) to the engine so the user can keep editing it.
          if (_committed.isNotEmpty && _isValueToken(_committed.last)) {
            final value = _committed.removeLast();
            _restoreEngineFromToken(value);
          } else {
            _add2Engine.reset();
            _engineActive = false;
            _currentIsPercentage = false;
          }
        } else if (last == '(') {
          // Opening paren removed structurally — engine stays empty.
          _add2Engine.reset();
          _engineActive = false;
          _currentIsPercentage = false;
        } else if (_isOperator(last)) {
          if (_committed.isNotEmpty) {
            final value = _committed.removeLast();
            if (value == '(' || value == ')') {
              // Don't pop a paren when removing an operator — put it back.
              _committed.add(value);
              _add2Engine.reset();
              _engineActive = false;
              _currentIsPercentage = false;
            } else {
              _restoreEngineFromToken(value);
            }
          }
        } else {
          _restoreEngineFromToken(last);
        }
        notifyListeners();
      }
    });
  }

  void loadMoreTimelineEntries() {
    _visibleCount += _loadMoreCount;
    notifyListeners();
  }

  // ----- Cursor / edit mode --------------------------------------------

  /// Current cursor position as a character offset in [fullDisplayText].
  /// Defaults to the end of the text and follows it as the text grows.
  int get cursorPosition {
    if (_atEnd) return fullDisplayText.length;

    return _cursorPos;
  }

  /// True when the cursor is in "edit mode" (positioned somewhere other
  /// than the end of the expression). Used by getters that need to switch
  /// behavior in this mode.
  bool get isEditingMidExpression => _editText != null;

  /// True when the cursor is at the end of [fullDisplayText] (either the
  /// virtual at-end position or explicitly at [fullDisplayText.length]).
  /// The cursor is hidden in this state even while edit mode is active.
  bool get isCursorAtEnd => _atEnd;

  /// Moves the cursor one character to the left, entering edit mode if
  /// the cursor was previously at the end of the expression.
  void moveCursorLeft() {
    _runAction(() {
      _enterEditMode();
      if (_cursorPos > 0) {
        _cursorPos--;
        _atEnd = false;
      }
      notifyListeners();
    });
  }

  /// Moves the cursor one character to the right. When the cursor reaches
  /// the end of the text in edit mode, it snaps to the at-end position
  /// (cursor becomes hidden) without exiting edit mode — so the user's
  /// edits are preserved.
  void moveCursorRight() {
    _runAction(() {
      final text = fullDisplayText;
      if (_atEnd) return;
      if (_cursorPos < text.length) {
        _cursorPos++;
      }
      _atEnd = _cursorPos >= text.length;
      notifyListeners();
    });
  }

  /// Moves the cursor to the end of [fullDisplayText], hiding it without
  /// exiting edit mode. Called when the user taps the empty area around
  /// the display.
  void moveCursorToEnd() {
    _runAction(() {
      if (_editText == null) return;
      _atEnd = true;
      _cursorPos = _editText!.length;
      notifyListeners();
    });
  }

  /// Sets the cursor to an explicit character offset in [fullDisplayText].
  /// Out-of-range values are clamped. Edit mode is entered the first time
  /// the cursor is moved away from the end and persists until the session
  /// is reset (equals, clear, loadSession, paste).
  void setCursorPosition(int position) {
    _runAction(() {
      final text = fullDisplayText;
      var clamped = position;
      if (clamped < 0) clamped = 0;
      if (clamped > text.length) clamped = text.length;

      if (clamped == text.length) {
        // Tapping at/past the end always moves cursor to the at-end
        // (hidden) position, whether or not edit mode is active.
        _atEnd = true;
        _cursorPos = clamped;
        notifyListeners();

        return;
      }

      _enterEditMode();
      _cursorPos = clamped;
      _atEnd = false;
      notifyListeners();
    });
  }

  void _enterEditMode() {
    if (_editText != null) return;
    _editText = fullDisplayText;
    _cursorPos = _editText!.length;
  }

  void _exitEditMode() {
    _editText = null;
    _cursorPos = 0;
  }

  /// Snapshot do modo de edição para o [ExpressionEditor]. Só é válido
  /// enquanto [_editText] é não-nulo.
  EditorState get _editorState =>
      EditorState(text: _editText!, cursor: _cursorPos);

  /// Aplica o estado devolvido por uma operação do [ExpressionEditor].
  void _applyEditorState(EditorState state) {
    _editText = state.text;
    _cursorPos = state.cursor;
    _atEnd = _cursorPos >= state.text.length;
  }

  /// Binary operators as they appear in an expression. Note the minus is the
  /// U+2212 sign, never the hyphen a negative result is formatted with.
  static final RegExp _operatorRegExp = RegExp(r'[+−×÷]');

  /// Loads a history session into the calculator, restoring the timeline
  /// up to (and including) the specified [selection.lineIndex].
  ///
  /// The last loaded line's expression is placed into the display field
  /// as if the user had just typed it, ready for editing or continuation.
  void loadSession(HistorySelection selection) {
    // Save any existing session before overwriting.
    _saveOrUpdateSession();

    _exitEditMode();
    _atEnd = true;
    _timelineEntries.clear();
    _sessionLines.clear();

    final entry = selection.entry;
    final upToIndex = selection.lineIndex.clamp(0, entry.lines.length - 1);

    // Track the loaded session so subsequent = presses update it.
    _resetSessionTracking();
    _currentSessionId = entry.id;
    _persistedLineCount = 0; // Updated after lines are added below.

    // Load all lines up to (but not including) the selected line into timeline.
    for (var i = 0; i < upToIndex; i++) {
      final line = entry.lines[i];
      _timelineEntries.add(
        Calculation(
          expression: _formatExpression(line.expression),
          result: _formatValue(line.result),
          timestamp: entry.createdAt,
        ),
      );
      _sessionLines.add(line);
    }

    // The selected line: put its expression into the display field
    // and its result into the engine.
    final selectedLine = entry.lines[upToIndex];
    _timelineEntries.add(
      Calculation(
        expression: _formatExpression(selectedLine.expression),
        result: _formatValue(selectedLine.result),
        timestamp: entry.createdAt,
      ),
    );
    _sessionLines.add(selectedLine);
    _add2Engine.setValue(_parseToInt(selectedLine.result));

    // Loaded lines are already persisted in the database, so subsequent
    // saves should hit the update branch (or no-op if no new lines).
    _persistedLineCount = _sessionLines.length;

    _committed.clear();
    _pendingOperator = null;
    _engineActive = false;
    _currentIsPercentage = false;
    _shouldResetOnInput = true;
    notifyListeners();
  }

  // ----- Helpers --------------------------------------------------------

  /// Persists or updates the current session lines as a single [HistoryEntry].
  ///
  /// On the first call within a session, creates a new row in the database
  /// and stores its ID in [_currentSessionId]. Subsequent calls update the
  /// existing row with the latest lines and result. No-op when there are
  /// no new lines since the last persist.
  ///
  /// Returns a future that completes once every write issued so far has
  /// landed — [flushSession] awaits it so a shutting-down app never cuts a
  /// write short.
  Future<void> _saveOrUpdateSession() {
    if (_sessionLines.isEmpty) return _pendingWrite;
    if (_sessionLines.length == _persistedLineCount) return _pendingWrite;

    final lines = List.of(_sessionLines);
    final lastResult = lines.last.result;
    _persistedLineCount = lines.length;

    final sessionId = _currentSessionId;
    if (sessionId != null) {
      return _trackWrite(
        _historyRepository.update(_sessionEntry(sessionId, lines, lastResult)),
      );
    }

    final pendingAdd = _pendingAdd;
    if (pendingAdd != null) {
      // The `add` for the first line has not returned an id yet. Chain the
      // update onto the id it produces instead of creating a second session.
      return _trackWrite(
        pendingAdd.then<void>((id) async {
          if (id == null) return;

          await _historyRepository.update(_sessionEntry(id, lines, lastResult));
        }),
      );
    }

    final generation = _sessionGeneration;
    final add = _historyRepository
        .add(_sessionEntry(null, lines, lastResult))
        .then((saved) {
          // The session may have been reset (clear/load/paste) while the add
          // was in flight — the id then belongs to a session that is gone.
          if (_sessionGeneration == generation) {
            _pendingAdd = null;
            _currentSessionId = saved.id;
          }

          return saved.id;
        });
    _pendingAdd = add;

    return _trackWrite(add);
  }

  HistoryEntry _sessionEntry(int? id, List<HistoryLine> lines, String result) {
    return HistoryEntry(
      id: id,
      lines: lines,
      result: result,
      createdAt: DateTime.now(),
    );
  }

  /// Appends [write] to the chain of pending writes and returns a future
  /// completing when it lands. A failed write never poisons the chain: later
  /// waits still complete, so the app is always able to close.
  Future<void> _trackWrite(Future<void> write) {
    final chained = _pendingWrite.then((_) => write);
    _pendingWrite = chained.catchError((_) {});

    return chained;
  }

  /// Drops every trace of the current session so the next lines start a new
  /// one. An `add` still in flight is detached: its id no longer lands in
  /// [_currentSessionId], but the update chained onto it still writes to the
  /// session those lines belong to.
  void _resetSessionTracking() {
    _sessionGeneration++;
    _currentSessionId = null;
    _persistedLineCount = 0;
    _pendingAdd = null;
  }

  String _engineToken() {
    final value = _add2Engine.formattedValue;

    return _currentIsPercentage ? '$value%' : value;
  }

  bool _lastIsClosingParen() {
    return _committed.isNotEmpty && _committed.last == ')';
  }

  bool _isOperator(String value) {
    return value == '+' || value == '−' || value == '×' || value == '÷';
  }

  bool _isValueToken(String value) {
    if (value == '(' || value == ')') return false;

    return !_isOperator(value);
  }

  /// Formats a single committed (or active) token for display: numbers go
  /// through the configured number formatter, operators and parentheses pass
  /// through, and `%`-suffixed values keep the literal percent sign.
  String _formatPart(String value) {
    if (_isOperator(value)) return value;
    if (value == '(' || value == ')') return value;

    if (value.endsWith('%')) {
      final numeric = value.substring(0, value.length - 1);

      return '${_formatValue(numeric)}%';
    }

    return _formatValue(value);
  }

  /// Restores the engine state (and the percentage flag) from a committed
  /// token, which may carry a literal `%` suffix. Operators and parens are
  /// not restorable as engine values; the caller is responsible for filtering.
  void _restoreEngineFromToken(String token) {
    if (token == '(' || token == ')') {
      _add2Engine.reset();
      _engineActive = false;
      _currentIsPercentage = false;

      return;
    }

    if (token.endsWith('%')) {
      final numeric = token.substring(0, token.length - 1);
      _add2Engine.setValue(_parseToInt(numeric));
      _currentIsPercentage = true;
    } else {
      _add2Engine.setValue(_parseToInt(token));
      _currentIsPercentage = false;
    }
    _engineActive = true;
  }

  String _buildFullExpression() {
    final parts = <String>[..._committed];
    if (_pendingOperator != null) parts.add(_pendingOperator!);
    if (_engineActive) parts.add(_engineToken());

    return parts.join(' ');
  }

  int _parseToInt(String formattedValue) {
    final parsed = double.tryParse(formattedValue);
    if (parsed == null) return 0;

    return (parsed * 100).round();
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
  bool get hasExpression {
    if (_committed.isNotEmpty) return true;
    if (_engineActive) return true;
    if (_pendingOperator != null) return true;

    return false;
  }

  /// True when there is a numeric result available — either a live preview
  /// or the result of the most recent `=`.
  bool get hasResult {
    if (previewResult != null) return true;
    if (_shouldResetOnInput && !_add2Engine.isEmpty) return true;

    return false;
  }

  /// True when there is at least one calculation in the session timeline.
  bool get hasHistory => _timelineEntries.isNotEmpty;

  /// Copies the current expression text (e.g., `1000.00 + 10.00%`) to the
  /// clipboard. No-op when [hasExpression] is false.
  Future<void> copyExpression() async {
    if (!hasExpression) return;

    await _clipboardService.copyText(fullDisplayText);
  }

  /// Copies the current result (preview or post-`=` value) to the clipboard.
  /// No-op when [hasResult] is false.
  Future<void> copyResult() async {
    final preview = previewResult;
    if (preview != null) {
      await _clipboardService.copyText(preview);

      return;
    }

    if (_shouldResetOnInput && !_add2Engine.isEmpty) {
      await _clipboardService.copyText(currentDisplayValue);
    }
  }

  /// Copies all session timeline entries to the clipboard, one per line in
  /// the format `<expression> = <result>`.
  Future<void> copyHistory() async {
    if (_timelineEntries.isEmpty) return;

    final buffer = StringBuffer();
    for (var i = 0; i < _timelineEntries.length; i++) {
      if (i > 0) buffer.writeln();
      final entry = _timelineEntries[i];
      buffer.write('${entry.expression} = ${entry.result}');
    }

    await _clipboardService.copyText(buffer.toString());
  }

  /// Reads text from the clipboard, parses and applies it to the calculator
  /// state. Returns `true` on success, `false` when the clipboard is empty
  /// or its contents cannot be interpreted as a number/expression.
  ///
  /// Lines already resolved (`<expressão> = <resultado>`) become timeline
  /// entries; a trailing line without `=` becomes the current input. The
  /// pasted results are **recalculated** from their expressions, so a stale
  /// or wrong value in the clipboard never reaches the history.
  Future<bool> pasteFromClipboard() async {
    final raw = await _clipboardService.readText();
    if (raw == null) return false;

    final content = PasteInputParser.parseContent(raw);
    if (content == null) return false;

    // Avalia todas as linhas antes de tocar no estado, para que uma linha
    // inavaliável (ex.: divisão por zero) não deixe a calculadora pela metade.
    final lines = <HistoryLine>[];
    for (final tokens in content.resolvedLines) {
      final expression = tokens.join(' ');
      final result = _evaluator.evaluate(expression);
      if (result == null) return false;
      lines.add(HistoryLine(expression: expression, result: result));
    }

    _runAction(() => _applyPastedContent(lines, content.input));

    return true;
  }

  /// True when the clipboard currently contains text. Used by the context
  /// menu to enable/disable the paste entry without committing to a paste.
  Future<bool> clipboardHasText() async {
    final raw = await _clipboardService.readText();

    return raw != null && raw.isNotEmpty;
  }

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
    _saveOrUpdateSession();
    _exitEditMode();
    _atEnd = true;
    _add2Engine.reset();
    _committed.clear();
    _pendingOperator = null;
    _engineActive = false;
    _shouldResetOnInput = false;
    _currentIsPercentage = false;
    _timelineEntries.clear();
    _sessionLines.clear();
    _resetSessionTracking();

    for (final line in lines) {
      _timelineEntries.add(
        Calculation(
          expression: _formatExpression(line.expression),
          result: _formatValue(line.result),
          timestamp: DateTime.now(),
        ),
      );
      _sessionLines.add(line);
    }

    if (inputTokens != null) {
      _restoreInputTokens(inputTokens);
    } else if (lines.isNotEmpty) {
      _add2Engine.setValue(_parseToInt(lines.last.result));
      _shouldResetOnInput = true;
    }

    notifyListeners();
  }

  /// Distributes pasted expression tokens across the committed list, the
  /// pending operator and the Add2 engine, mirroring how the same expression
  /// would look had the user typed it.
  void _restoreInputTokens(List<String> tokens) {
    final last = tokens.last;
    if (_isOperator(last)) {
      _committed.addAll(tokens.sublist(0, tokens.length - 1));
      _pendingOperator = last;
    } else if (last == ')') {
      _committed.addAll(tokens);
    } else {
      // Last token is a numeric operand (possibly suffixed with `%`).
      // If the token before it is an operator, promote that operator to
      // `_pendingOperator` so the engine value represents the right-hand
      // side of an in-progress binary expression (enables previewResult).
      var rest = tokens.sublist(0, tokens.length - 1);
      if (rest.isNotEmpty && _isOperator(rest.last)) {
        _pendingOperator = rest.last;
        rest = rest.sublist(0, rest.length - 1);
      }
      _committed.addAll(rest);
      _restoreEngineFromToken(last);
    }
  }
}
