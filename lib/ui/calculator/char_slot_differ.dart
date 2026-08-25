import 'dart:math';

import 'package:flutter/foundation.dart';

/// Animação atribuída a um caractere do display após o diff de textos.
enum CharAnimType { none, popIn, roll }

/// Um caractere do display com a animação decidida pelo diff.
class CharSlot {
  final String char;
  final String? oldChar;
  final CharAnimType type;
  final UniqueKey key;

  CharSlot({required this.char, this.oldChar, required this.type})
    : key = UniqueKey();
}

/// Diff puro entre o texto anterior e o atual do display: decide qual
/// animação cada caractere recebe. Prefixo e sufixo comuns não animam;
/// trocas no trecho do meio rolam (roll) carregando o caractere antigo;
/// caracteres extras entram com pop-in.
class CharSlotDiffer {
  const CharSlotDiffer._();

  /// Slots para [text] inteiro, todos com pop-in ([animate]) ou estáticos.
  static List<CharSlot> build(String text, {required bool animate}) {
    return [
      for (int i = 0; i < text.length; i++)
        CharSlot(
          char: text[i],
          type: animate ? CharAnimType.popIn : CharAnimType.none,
        ),
    ];
  }

  static List<CharSlot> diff(String oldText, String newText) {
    if (oldText.isEmpty) {
      return build(newText, animate: true);
    }

    int prefixLen = 0;
    final minLen = min(oldText.length, newText.length);
    while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    int suffixLen = 0;
    final maxSuffix = minLen - prefixLen;
    while (suffixLen < maxSuffix &&
        oldText[oldText.length - 1 - suffixLen] ==
            newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }

    final oldMiddleStart = prefixLen;
    final oldMiddleLen = oldText.length - suffixLen - prefixLen;

    final slots = <CharSlot>[];

    for (int i = 0; i < newText.length; i++) {
      if (i < prefixLen || i >= newText.length - suffixLen) {
        slots.add(CharSlot(char: newText[i], type: CharAnimType.none));
      } else {
        final middleOffset = i - prefixLen;
        if (middleOffset < oldMiddleLen) {
          final oldChar = oldText[oldMiddleStart + middleOffset];
          if (oldChar != newText[i]) {
            slots.add(
              CharSlot(
                char: newText[i],
                oldChar: oldChar,
                type: CharAnimType.roll,
              ),
            );
          } else {
            slots.add(CharSlot(char: newText[i], type: CharAnimType.none));
          }
        } else {
          slots.add(CharSlot(char: newText[i], type: CharAnimType.popIn));
        }
      }
    }

    return slots;
  }

  /// Decai um slot animado para texto estático (fim da animação).
  static CharSlot settle(CharSlot slot) =>
      CharSlot(char: slot.char, type: CharAnimType.none);
}
