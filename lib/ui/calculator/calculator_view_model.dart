import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:decima/data/repositories/history_repository.dart';
import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/data/services/clipboard_service.dart';
import 'package:decima/domain/add2_engine.dart';
import 'package:decima/domain/entities/calculation.dart';
import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/domain/entities/history_selection.dart';
import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/expression_evaluator.dart';
import 'package:decima/utils/formatters/number_formatter.dart';
import 'package:decima/utils/paste_input_parser.dart';

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

  /// True once an `add` has been issued for the current session, even before
  /// the asynchronous future resolves with the new id. Prevents duplicate
  /// `add` calls when subsequent persistence happens synchronously after `=`.
  bool _addInFlight = false;

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
      final raw = _normalizeForEvaluator(_editText!);
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
        _editInsertDigits(digit);
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
        _editInsertDigits('00');
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
        _editInsertDigits('000');
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
        _editSplitBlockWithOperator(operator);
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
        _editApplyPercentInBlock();
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
        _editInsertParenthesis();
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
    _runAction(() {
      if (_editText != null) {
        var raw = _normalizeForEvaluator(_editText!);
        if (raw.trim().isEmpty) return;
        // Need at least one operator anywhere to be evaluable.
        if (!RegExp(r'[+\u2212\u00d7\u00f7]').hasMatch(raw)) return;
        // Auto-close any unbalanced parentheses, same as the committed path.
        final open = openParenCount;
        if (open > 0) {
          raw = '$raw${' )' * open}';
        }
        final result = _evaluator.evaluate(raw);
        if (result == null) return;

        final formattedExpression = _formatExpression(raw);
        final formattedResult = _formatValue(result);

        final calculation = Calculation(
          expression: formattedExpression,
          result: formattedResult,
          timestamp: DateTime.now(),
        );
        _timelineEntries.add(calculation);
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

        return;
      }
      // Need at least one operator anywhere to be evaluable.
      final hasOperator =
          _pendingOperator != null || _committed.any(_isOperator);
      if (!hasOperator) return;

      if (_pendingOperator != null && !_engineActive) {
        // "12.50 +" with no RHS — evaluator handles trailing operator
        // gracefully, so we still proceed.
      }

      var raw = _buildFullExpression();
      // Auto-close any unbalanced parentheses before evaluation.
      final open = openParenCount;
      if (open > 0) {
        raw = '$raw${' )' * open}';
      }

      final result = _evaluator.evaluate(raw);
      if (result == null) return;

      final formattedExpression = _formatExpression(raw);
      final formattedResult = _formatValue(result);

      final calculation = Calculation(
        expression: formattedExpression,
        result: formattedResult,
        timestamp: DateTime.now(),
      );

      _timelineEntries.add(calculation);

      // Store the raw expression/result pair for session-based saving.
      _sessionLines.add(HistoryLine(expression: raw, result: result));

      // Persist the session: create on first =, update on subsequent.
      _saveOrUpdateSession();

      _committed.clear();
      _pendingOperator = null;
      _engineActive = false;
      _shouldResetOnInput = true;
      _currentIsPercentage = false;
      _add2Engine.setValue(_parseToInt(result));

      notifyListeners();
    });
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
      _currentSessionId = null;
      _persistedLineCount = 0;
      notifyListeners();
    });
  }

  void backspace() {
    _runAction(() {
      if (_editText != null) {
        _editBackspace();
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

  static final RegExp _digitRegExp = RegExp(r'[0-9]');
  static final RegExp _numberCharRegExp = RegExp(r'[0-9.,%]');

  /// Inserts the digit string [digits] (only `0-9` chars) at the current
  /// cursor position, applying Add2 formatting to the surrounding number
  /// block. The block is detected from contiguous number-like chars
  /// (digits, decimal/thousand separators, optional trailing `%`).
  void _editInsertDigits(String digits) {
    final text = _editText!;
    final block = _findNumberBlock(text, _cursorPos);
    final raw = _stripToDigits(text.substring(block.start, block.end));
    final hasPercent = block.end > block.start && text[block.end - 1] == '%';
    final digitsBeforeCursor = _countDigits(text, block.start, _cursorPos);
    final digitsAfterCursor = raw.length - digitsBeforeCursor;

    final newRaw =
        raw.substring(0, digitsBeforeCursor) +
        digits +
        raw.substring(digitsBeforeCursor);
    // Preserve digitsAfterCursor: the cursor lands immediately after the
    // newly inserted digits, keeping the same number of digits to its right
    // as before the insertion. This is robust to Add2's leading-zero padding.
    final newDigitsAfterCursor = digitsAfterCursor;

    _replaceBlockWithFormatted(
      text,
      block.start,
      block.end,
      newRaw,
      hasPercent,
      newDigitsAfterCursor,
    );
  }

  /// Inserts the literal string [s] (operators, parentheses, spaces) at the
  /// current cursor position without re-formatting. Used for non-digit input.
  void _editInsertLiteral(String s) {
    final text = _editText!;
    _editText = text.substring(0, _cursorPos) + s + text.substring(_cursorPos);
    _cursorPos += s.length;
    _atEnd = _cursorPos >= _editText!.length;
  }

  /// Removes one digit from the surrounding number block (re-formatting
  /// the block via Add2). When the char immediately before the cursor is an
  /// operator (` op `), removes the entire operator-with-spaces and merges
  /// the two surrounding number blocks via Add2 (concatenated raw digits).
  /// Outside number blocks, falls back to deleting the literal char.
  void _editBackspace() {
    if (_cursorPos <= 0) return;
    final text = _editText!;
    final block = _findNumberBlock(text, _cursorPos);
    final raw = _stripToDigits(text.substring(block.start, block.end));
    final digitsBeforeCursor = _countDigits(text, block.start, _cursorPos);

    if (raw.isEmpty || digitsBeforeCursor == 0) {
      // Cursor is at a non-digit boundary. Detect the operator-with-spaces
      // pattern (` op ` where op ∈ +−×÷) immediately before the cursor and
      // merge the surrounding blocks if present.
      final merged = _tryMergeBlocksAtCursor();
      if (merged) return;

      // Plain literal char delete.
      _editText =
          text.substring(0, _cursorPos - 1) + text.substring(_cursorPos);
      _cursorPos--;
      _atEnd = _cursorPos >= _editText!.length;

      return;
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

    _replaceBlockWithFormatted(
      text,
      block.start,
      block.end,
      newRaw,
      hasPercent,
      newDigitsAfterCursor,
    );
  }

  /// Inserts an operator at the current cursor position. When the cursor
  /// lies in the middle of a number block (digits on both sides), the block
  /// is split into two Add2-formatted halves with ` op ` between them.
  /// At block boundaries (start, end, or outside any block), the operator
  /// is inserted as a literal ` op ` without splitting.
  ///
  /// Cursor lands immediately after the inserted operator.
  void _editSplitBlockWithOperator(String operator) {
    final text = _editText!;
    final block = _findNumberBlock(text, _cursorPos);
    final raw = _stripToDigits(text.substring(block.start, block.end));
    final digitsBeforeCursor = _countDigits(text, block.start, _cursorPos);
    final digitsAfterCursor = raw.length - digitsBeforeCursor;

    // No surrounding block, or cursor at a boundary — append literally.
    if (raw.isEmpty || digitsBeforeCursor == 0 || digitsAfterCursor == 0) {
      _editInsertLiteral(' $operator ');

      return;
    }

    final hasPercent = block.end > block.start && text[block.end - 1] == '%';
    final leftRaw = raw.substring(0, digitsBeforeCursor);
    final rightRaw = raw.substring(digitsBeforeCursor);

    final leftCore = NumberFormatter.format(
      int.parse(leftRaw),
      separator: _decimalSeparator,
      useThousandsSeparator: true,
    );
    final rightCore = NumberFormatter.format(
      int.parse(rightRaw),
      separator: _decimalSeparator,
      useThousandsSeparator: true,
    );

    // Percent suffix (if any) belongs to the right half — it was at the
    // tail of the original block.
    final rightBlock = rightCore + (hasPercent ? '%' : '');
    final replacement = '$leftCore $operator $rightBlock';

    _editText =
        text.substring(0, block.start) +
        replacement +
        text.substring(block.end);

    // Cursor lands immediately after the inserted operator (after the
    // trailing space): position = block.start + leftCore.length + 3
    // (' ' + op + ' ').
    _cursorPos = block.start + leftCore.length + 3;
    _atEnd = _cursorPos >= _editText!.length;
  }

  /// Detects whether the chars immediately before the cursor form an
  /// operator-with-spaces sequence (` op `) sandwiched between two number
  /// blocks. If so, removes the operator (and its surrounding spaces) and
  /// merges the two blocks by concatenating their raw digits and re-applying
  /// Add2. Returns true on a successful merge, false otherwise.
  bool _tryMergeBlocksAtCursor() {
    final text = _editText!;
    // Pattern is " op " ending exactly at _cursorPos: chars at
    // _cursorPos-3 = ' ', _cursorPos-2 = op, _cursorPos-1 = ' '.
    if (_cursorPos < 3) return false;
    if (text[_cursorPos - 1] != ' ') return false;
    final op = text[_cursorPos - 2];
    if (!(op == '+' || op == '−' || op == '×' || op == '÷')) return false;
    if (text[_cursorPos - 3] != ' ') return false;

    final leftBlock = _findNumberBlock(text, _cursorPos - 3);
    final rightBlock = _findNumberBlock(text, _cursorPos);
    if (leftBlock.end == leftBlock.start) return false;
    if (rightBlock.end == rightBlock.start) return false;

    final leftRawPadded = _stripToDigits(
      text.substring(leftBlock.start, leftBlock.end),
    );
    final rightRawPadded = _stripToDigits(
      text.substring(rightBlock.start, rightBlock.end),
    );
    if (leftRawPadded.isEmpty && rightRawPadded.isEmpty) return false;

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

    _replaceBlockWithFormatted(
      text,
      leftBlock.start,
      rightBlock.end,
      mergedRaw,
      rightHasPercent,
      newDigitsAfterCursor,
    );

    return true;
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
  void _editInsertParenthesis() {
    final text = _editText!;
    final block = _findNumberBlock(text, _cursorPos);
    final hasBlock = block.end > block.start;

    if (openParenCount > 0) {
      final closeAt = hasBlock ? block.end : _cursorPos;
      final before = closeAt > 0 ? text[closeAt - 1] : ' ';
      if (before == ')' || before == '%' || _digitRegExp.hasMatch(before)) {
        _cursorPos = closeAt;
        _editInsertLiteral(' )');

        return;
      }
    }

    final insertAt = hasBlock ? block.start : _cursorPos;
    final cursorBefore = _cursorPos;
    _editText = '${text.substring(0, insertAt)}( ${text.substring(insertAt)}';
    _cursorPos = cursorBefore + 2;
    _atEnd = _cursorPos >= _editText!.length;
  }

  /// Appends a literal `%` to the end of the number block surrounding the
  /// cursor. No-op when there is no block, or when the block already ends
  /// with `%`.
  void _editApplyPercentInBlock() {
    final text = _editText!;
    final block = _findNumberBlock(text, _cursorPos);
    if (block.end == block.start) return;
    if (text[block.end - 1] == '%') return;

    _editText = '${text.substring(0, block.end)}%${text.substring(block.end)}';
    _cursorPos = block.end + 1;
    _atEnd = _cursorPos >= _editText!.length;
  }

  /// Replaces the substring [text] [start..end) with the Add2-formatted
  /// representation of [newRaw] (digit-only string), restoring the optional
  /// `%` suffix and positioning the cursor so that exactly
  /// [newDigitsAfterCursor] digit characters of the new block lie after it.
  ///
  /// Anchoring the cursor by digits-after (rather than digits-before) keeps
  /// it visually stable when Add2 pads the block with a leading zero — the
  /// trailing digits are the stable reference, not the volatile leading edge.
  void _replaceBlockWithFormatted(
    String text,
    int start,
    int end,
    String newRaw,
    bool hasPercent,
    int newDigitsAfterCursor,
  ) {
    final newCore = newRaw.isEmpty
        ? ''
        : NumberFormatter.format(
            int.parse(newRaw),
            separator: _decimalSeparator,
            useThousandsSeparator: true,
          );
    final newBlock = newCore + (hasPercent ? '%' : '');

    _editText = text.substring(0, start) + newBlock + text.substring(end);

    final cursorOffsetInBlock = newCore.isEmpty
        ? 0
        : _positionWithDigitsAfter(newCore, newDigitsAfterCursor);
    _cursorPos = start + cursorOffsetInBlock;
    _atEnd = _cursorPos >= _editText!.length;
  }

  /// Finds the maximal range of contiguous number-like characters
  /// containing position [pos] in [text]. Returns a zero-length range at
  /// [pos] when the cursor is not adjacent to any number-like char.
  ({int start, int end}) _findNumberBlock(String text, int pos) {
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

  String _stripToDigits(String s) {
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (_digitRegExp.hasMatch(s[i])) buffer.write(s[i]);
    }

    return buffer.toString();
  }

  int _countDigits(String text, int start, int end) {
    var n = 0;
    for (var i = start; i < end; i++) {
      if (_digitRegExp.hasMatch(text[i])) n++;
    }

    return n;
  }

  /// Returns the offset in [formatted] such that exactly [digitCount] digit
  /// characters follow it. Clamps to `[0, formatted.length]`.
  int _positionWithDigitsAfter(String formatted, int digitCount) {
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

  /// Normalizes the formatted edit text into a string the
  /// [ExpressionEvaluator] can parse: removes thousand separators and
  /// converts the configured decimal separator back to a dot.
  String _normalizeForEvaluator(String text) {
    final thousands = _decimalSeparator == DecimalSeparator.dot ? ',' : '.';
    final decimal = _decimalSeparator.character;
    var t = text.replaceAll(thousands, '');
    if (decimal != '.') {
      t = t.replaceAll(decimal, '.');
    }

    return t;
  }

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
  void _saveOrUpdateSession() {
    if (_sessionLines.isEmpty) return;
    if (_sessionLines.length == _persistedLineCount) return;

    final lastResult = _sessionLines.last.result;
    final linesSnapshot = List.of(_sessionLines);

    if (_currentSessionId != null) {
      _historyRepository.update(
        HistoryEntry(
          id: _currentSessionId,
          lines: linesSnapshot,
          result: lastResult,
          createdAt: DateTime.now(),
        ),
      );
      _persistedLineCount = linesSnapshot.length;

      return;
    }

    if (_addInFlight) {
      // First add already issued but id not yet returned. Do not issue
      // another add; the in-flight future will set the id and the next
      // persist call will go through the update branch.
      _persistedLineCount = linesSnapshot.length;

      return;
    }

    _addInFlight = true;
    _persistedLineCount = linesSnapshot.length;
    _historyRepository
        .add(
          HistoryEntry(
            lines: linesSnapshot,
            result: lastResult,
            createdAt: DateTime.now(),
          ),
        )
        .then((saved) {
          _addInFlight = false;
          // Only adopt the id if the session wasn't reset in the meantime.
          if (_persistedLineCount > 0) {
            _currentSessionId = saved.id;
          }
        });
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
    _currentSessionId = null;
    _persistedLineCount = 0;

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
