import 'package:decima/ui/calculator/char_slot_differ.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CharSlotDiffer.build', () {
    test('sem animação produz um slot none por caractere', () {
      final slots = CharSlotDiffer.build('12.50', animate: false);

      expect(slots.map((s) => s.char).join(), '12.50');
      expect(slots.every((s) => s.type == CharAnimType.none), isTrue);
    });

    test('com animação produz pop-in para todos os caracteres', () {
      final slots = CharSlotDiffer.build('42', animate: true);

      expect(slots.map((s) => s.char).join(), '42');
      expect(slots.every((s) => s.type == CharAnimType.popIn), isTrue);
    });

    test('texto vazio produz lista vazia', () {
      expect(CharSlotDiffer.build('', animate: true), isEmpty);
    });
  });

  group('CharSlotDiffer.diff', () {
    test('texto anterior vazio anima tudo com pop-in', () {
      final slots = CharSlotDiffer.diff('', '0.05');

      expect(slots.map((s) => s.char).join(), '0.05');
      expect(slots.every((s) => s.type == CharAnimType.popIn), isTrue);
    });

    test('textos idênticos não animam nada', () {
      final slots = CharSlotDiffer.diff('12.50', '12.50');

      expect(slots.every((s) => s.type == CharAnimType.none), isTrue);
    });

    test('caractere extra no fim dá pop-in e preserva o prefixo', () {
      final slots = CharSlotDiffer.diff('12.5', '12.50');

      expect(slots.map((s) => s.char).join(), '12.50');
      expect(
        slots.sublist(0, 4).every((s) => s.type == CharAnimType.none),
        isTrue,
      );
      expect(slots.last.type, CharAnimType.popIn);
    });

    test('troca no meio vira roll com o caractere antigo', () {
      // Add2: 0.05 → 0.51 (o 5 rola para 5, o 0→5 e 5→1 rolam).
      final slots = CharSlotDiffer.diff('0.05', '0.51');

      expect(slots.map((s) => s.char).join(), '0.51');
      final rolls = slots.where((s) => s.type == CharAnimType.roll).toList();
      expect(rolls, isNotEmpty);
      for (final slot in rolls) {
        expect(slot.oldChar, isNotNull);
        expect(slot.oldChar, isNot(slot.char));
      }
    });

    test('diff Add2 típico: 0.10 → 10.00 mistura roll, pop-in e sufixo', () {
      final slots = CharSlotDiffer.diff('0.10', '10.00');

      expect(slots.map((s) => s.char).join(), '10.00');
      // Sufixo comum "0" não anima.
      expect(slots.last.type, CharAnimType.none);
      // Há exatamente um caractere extra (pop-in).
      expect(slots.where((s) => s.type == CharAnimType.popIn).length, 1);
    });

    test('prefixo e sufixo comuns não animam em edição no meio', () {
      final slots = CharSlotDiffer.diff('12.50 + 3', '12.50 + 34');

      expect(slots.map((s) => s.char).join(), '12.50 + 34');
      for (int i = 0; i < 9; i++) {
        expect(slots[i].type, CharAnimType.none, reason: 'índice $i');
      }
      expect(slots.last.type, CharAnimType.popIn);
    });

    test('texto encolhendo mantém os caracteres restantes sem animação', () {
      final slots = CharSlotDiffer.diff('12.50', '1.25');

      expect(slots.map((s) => s.char).join(), '1.25');
      // Nenhum slot referencia caractere fora do novo texto.
      for (final slot in slots) {
        expect(slot.char.length, 1);
      }
    });

    test('caractere igual no meio do trecho alterado não anima', () {
      // Prefixo "a", sufixo "d"; no meio "xc" → "bc": o b roda, o c fica.
      final slots = CharSlotDiffer.diff('axcd', 'abcd');

      expect(slots[0].type, CharAnimType.none);
      expect(slots[1].type, CharAnimType.roll);
      expect(slots[1].oldChar, 'x');
      expect(slots[2].type, CharAnimType.none);
      expect(slots[3].type, CharAnimType.none);
    });

    test('cada slot recebe uma key única', () {
      final slots = CharSlotDiffer.diff('', '10.00');
      final keys = slots.map((s) => s.key).toSet();

      expect(keys.length, slots.length);
    });
  });

  group('CharSlotDiffer.settle', () {
    test('decai o slot para none preservando o caractere', () {
      final animated = CharSlotDiffer.diff('', '7').single;
      final settled = CharSlotDiffer.settle(animated);

      expect(settled.char, '7');
      expect(settled.type, CharAnimType.none);
      expect(settled.oldChar, isNull);
    });
  });
}
