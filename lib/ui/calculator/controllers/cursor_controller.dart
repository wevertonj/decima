import 'package:decima/domain/expression_editor.dart';

/// Estado do cursor e do modo de edição do display.
///
/// Enquanto [editText] é não-nulo, a string editável é a fonte da verdade do
/// texto exibido e as operações roteiam pelo `ExpressionEditor`. Os métodos
/// devolvem `true` quando o estado visível mudou e a UI deve ser notificada.
class CursorController {
  /// Editable text buffer used when the cursor is positioned somewhere
  /// other than the end of the expression.
  String? _editText;

  /// Cursor character offset inside [_editText]. Only valid while
  /// [_editText] is non-null. When [isAtEnd] is true, the visible cursor
  /// follows the end of the display text regardless of this value.
  int _cursorPos = 0;

  /// True when the cursor virtually follows the end of the display text.
  bool _atEnd = true;

  String? get editText => _editText;

  /// True when the cursor is in "edit mode" (positioned somewhere other
  /// than the end of the expression).
  bool get isEditing => _editText != null;

  /// True when the cursor is at the end of the display text (either the
  /// virtual at-end position or explicitly at its length). The cursor is
  /// hidden in this state even while edit mode is active.
  bool get isAtEnd => _atEnd;

  /// Current cursor position as a character offset in [fullText].
  /// Defaults to the end of the text and follows it as the text grows.
  int positionIn(String fullText) {
    if (_atEnd) return fullText.length;

    return _cursorPos;
  }

  /// Snapshot do modo de edição para o `ExpressionEditor`. Só é válido
  /// enquanto [editText] é não-nulo.
  EditorState get editorState =>
      EditorState(text: _editText!, cursor: _cursorPos);

  /// Aplica o estado devolvido por uma operação do `ExpressionEditor`.
  void applyEditorState(EditorState state) {
    _editText = state.text;
    _cursorPos = state.cursor;
    _atEnd = _cursorPos >= state.text.length;
  }

  /// Enters edit mode taking [fullText] as the editable snapshot. No-op
  /// when edit mode is already active.
  void enterEditMode(String fullText) {
    if (_editText != null) return;
    _editText = fullText;
    _cursorPos = _editText!.length;
  }

  /// Leaves edit mode and snaps the cursor back to the (hidden) at-end
  /// position. Called when the session state is rebuilt (equals, clear,
  /// loadSession, paste).
  void exitEditMode() {
    _editText = null;
    _cursorPos = 0;
    _atEnd = true;
  }

  /// Moves the cursor one character to the left, entering edit mode if
  /// the cursor was previously at the end of the expression.
  bool moveLeft(String fullText) {
    enterEditMode(fullText);
    if (_cursorPos > 0) {
      _cursorPos--;
      _atEnd = false;
    }

    return true;
  }

  /// Moves the cursor one character to the right. When the cursor reaches
  /// the end of the text in edit mode, it snaps to the at-end position
  /// (cursor becomes hidden) without exiting edit mode — so the user's
  /// edits are preserved.
  bool moveRight(String fullText) {
    if (_atEnd) return false;
    if (_cursorPos < fullText.length) {
      _cursorPos++;
    }
    _atEnd = _cursorPos >= fullText.length;

    return true;
  }

  /// Moves the cursor to the end of the display text, hiding it without
  /// exiting edit mode. Called when the user taps the empty area around
  /// the display.
  bool moveToEnd() {
    if (_editText == null) return false;
    _atEnd = true;
    _cursorPos = _editText!.length;

    return true;
  }

  /// Sets the cursor to an explicit character offset in [fullText].
  /// Out-of-range values are clamped. Edit mode is entered the first time
  /// the cursor is moved away from the end and persists until the session
  /// is reset.
  bool setPosition(String fullText, int position) {
    var clamped = position;
    if (clamped < 0) clamped = 0;
    if (clamped > fullText.length) clamped = fullText.length;

    if (clamped == fullText.length) {
      // Tapping at/past the end always moves cursor to the at-end
      // (hidden) position, whether or not edit mode is active.
      _atEnd = true;
      _cursorPos = clamped;

      return true;
    }

    enterEditMode(fullText);
    _cursorPos = clamped;
    _atEnd = false;

    return true;
  }
}
