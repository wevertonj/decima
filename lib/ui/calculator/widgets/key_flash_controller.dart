import 'package:flutter/foundation.dart';

/// Sinal de feedback visual para um botão do keypad.
///
/// [label] identifica o botão (o mesmo rótulo exibido no keypad) e [sequence]
/// muda a cada acionamento, para que a mesma tecla pressionada repetidamente
/// reinicie a animação em vez de ser ignorada por igualdade de valor.
typedef KeyFlash = ({String label, int sequence});

/// Ponte entre o teclado físico e o feedback visual do keypad.
///
/// O `KeyboardShortcutsHandler` dispara [flash] a cada tecla reconhecida e os
/// `CalculatorButton` correspondentes reproduzem exatamente a mesma animação
/// (glow LED + flash de fundo) usada no toque.
class KeyFlashController extends ValueNotifier<KeyFlash?> {
  KeyFlashController() : super(null);

  int _sequence = 0;

  void flash(String label) {
    _sequence++;
    value = (label: label, sequence: _sequence);
  }
}
