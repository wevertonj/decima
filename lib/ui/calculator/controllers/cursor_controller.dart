import 'package:decima/domain/expression_editor.dart';

/// Estado do cursor e do modo de edição do display.
///
/// Enquanto [editText] é não-nulo, a string editável é a fonte da verdade do
/// texto exibido e as operações roteiam pelo `ExpressionEditor`. Os métodos
/// devolvem `true` quando o estado visível mudou e a UI deve ser notificada.
class CursorController {
  /// Buffer editável usado quando o cursor sai do fim da expressão.
  String? _editText;

  /// Offset do cursor dentro de [_editText]; válido só com [_editText]
  /// não-nulo. Com [isAtEnd], o cursor visível segue o fim do texto,
  /// ignorando este valor.
  int _cursorPos = 0;

  /// `true` quando o cursor segue virtualmente o fim do texto do display.
  bool _atEnd = true;

  String? get editText => _editText;

  /// `true` quando o cursor está em modo de edição (fora do fim da
  /// expressão).
  bool get isEditing => _editText != null;

  /// `true` quando o cursor está no fim do texto; nesse estado ele fica
  /// oculto mesmo com o modo de edição ativo.
  bool get isAtEnd => _atEnd;

  /// Posição do cursor como offset de caractere em [fullText]; por padrão
  /// acompanha o fim do texto conforme ele cresce.
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

  /// Entra em modo de edição com [fullText] como snapshot editável. No-op
  /// quando o modo já está ativo.
  void enterEditMode(String fullText) {
    if (_editText != null) return;
    _editText = fullText;
    _cursorPos = _editText!.length;
  }

  /// Sai do modo de edição e devolve o cursor à posição (oculta) de fim.
  /// Chamado quando o estado da sessão é reconstruído (equals, clear,
  /// loadSession, paste).
  void exitEditMode() {
    _editText = null;
    _cursorPos = 0;
    _atEnd = true;
  }

  /// Move o cursor um caractere à esquerda, entrando em modo de edição se
  /// ele estava no fim da expressão.
  bool moveLeft(String fullText) {
    enterEditMode(fullText);
    if (_cursorPos > 0) {
      _cursorPos--;
      _atEnd = false;
    }

    return true;
  }

  /// Move o cursor um caractere à direita. Ao alcançar o fim em modo de
  /// edição, encosta na posição de fim (oculto) sem sair do modo — as
  /// edições do usuário são preservadas.
  bool moveRight(String fullText) {
    if (_atEnd) return false;
    if (_cursorPos < fullText.length) {
      _cursorPos++;
    }
    _atEnd = _cursorPos >= fullText.length;

    return true;
  }

  /// Move o cursor para o fim do texto, ocultando-o sem sair do modo de
  /// edição. Chamado no toque na área vazia ao redor do display.
  bool moveToEnd() {
    if (_editText == null) return false;
    _atEnd = true;
    _cursorPos = _editText!.length;

    return true;
  }

  /// Posiciona o cursor num offset explícito de [fullText]; valores fora do
  /// intervalo são clampados. O modo de edição começa quando o cursor sai
  /// do fim e persiste até o reset da sessão.
  bool setPosition(String fullText, int position) {
    var clamped = position;
    if (clamped < 0) clamped = 0;
    if (clamped > fullText.length) clamped = fullText.length;

    if (clamped == fullText.length) {
      // Toque no fim (ou além) sempre leva à posição de fim oculta, com ou
      // sem modo de edição ativo.
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
