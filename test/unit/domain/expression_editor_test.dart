import 'package:decima/domain/enums/decimal_separator.dart';
import 'package:decima/domain/expression_editor.dart';
import 'package:flutter_test/flutter_test.dart';

// Cenários de edição mid-expression absorvidos de
// calculator_view_model_test.dart na Etapa 20 — mesmos casos e expectativas,
// agora contra a API pura do ExpressionEditor.
void main() {
  const separator = DecimalSeparator.dot;

  group('ExpressionEditor', () {
    group('insertDigits', () {
      test('in middle inserts at cursor preserving digits-after anchor', () {
        // "12.50", cursor na posição 2 (entre '2' e '.').
        const state = EditorState(text: '12.50', cursor: 2);
        final next = ExpressionEditor.insertDigits(state, '7', separator);

        // raw '1250' (digitsAfter=2) + '7' -> '12750' -> '127.50'
        // Cursor preserva 2 digits-after -> posição 4 (após '127.').
        expect(next.text, '127.50');
        expect(next.cursor, 4);
      });

      test('in middle re-applies Add2 to the number block', () {
        // "2.37", cursor entre '3' e '7' (pos 3).
        const state = EditorState(text: '2.37', cursor: 3);
        final next = ExpressionEditor.insertDigits(state, '1', separator);

        // raw '237' -> insere '1' no digit-idx 2 -> '2317' -> Add2 -> '23.17'
        expect(next.text, '23.17');
      });

      test('appended at end of block reformats with Add2', () {
        // "2.37 +", cursor entre '7' e ' ' (pos 4).
        const state = EditorState(text: '2.37 +', cursor: 4);
        final next = ExpressionEditor.insertDigits(state, '1', separator);

        // raw '237' -> anexa '1' ao final -> '2371' -> '23.71'
        expect(next.text, '23.71 +');
      });
    });

    group('backspace', () {
      test('in middle deletes a digit and re-applies Add2', () {
        // "12.34", cursor entre '3' e '4' (pos 4).
        const state = EditorState(text: '12.34', cursor: 4);
        final next = ExpressionEditor.backspace(state, separator);

        // Remove o dígito '3' do raw '1234' -> '124' -> Add2 -> '1.24'
        expect(next.text, '1.24');
        expect(next.cursor, 3);
      });

      test('on operator merges surrounding blocks via Add2', () {
        // '0.12 + 0.50', cursor logo após o operador (pos 7).
        const state = EditorState(text: '0.12 + 0.50', cursor: 7);
        // Backspace logo após o operador funde os dois blocos. Os raws são
        // normalizados via int.parse para descartar os zeros à esquerda do
        // Add2: '0.12' -> '12', '0.50' -> '50' -> fundidos '1250' -> '12.50'.
        // Cursor preserva rightDigits.length=2 digits-after -> posição 3.
        final next = ExpressionEditor.backspace(state, separator);

        expect(next.text, '12.50');
        expect(next.cursor, 3);
      });

      test('at start of right block merges adjacent blocks', () {
        // "0.12 + 0.34", cursor antes do '0' do segundo bloco (pos 7).
        const state = EditorState(text: '0.12 + 0.34', cursor: 7);
        final next = ExpressionEditor.backspace(state, separator);

        // Merge: '0.12' (-> '12') + '0.34' (-> '34') -> '1234' -> '12.34'.
        expect(next.text, '12.34');
      });

      test('at position 0 is a no-op', () {
        const state = EditorState(text: '12.50', cursor: 0);
        final next = ExpressionEditor.backspace(state, separator);

        expect(next.text, '12.50');
        expect(next.cursor, 0);
      });

      test('outside number blocks deletes the literal char', () {
        // '( 12.50', cursor logo após '( ' (pos 2): sem dígitos antes do
        // cursor dentro do bloco e sem padrão ` op ` -> deleção literal.
        const state = EditorState(text: '( 12.50', cursor: 2);
        final next = ExpressionEditor.backspace(state, separator);

        expect(next.text, '(12.50');
        expect(next.cursor, 1);
      });
    });

    group('insertOperator', () {
      test('in middle splits the block into two halves', () {
        // "12.50", cursor na posição 2.
        const state = EditorState(text: '12.50', cursor: 2);
        final next = ExpressionEditor.insertOperator(state, '+', separator);

        // O raw '1250' do bloco divide no digit-idx 2 (chars antes do cursor
        // são '1' e '2'): raw esquerdo '12' -> '0.12', direito '50' -> '0.50'.
        // Cursor cai após ' + ' (block.start=0 + leftCore.length=4 + 3 = 7).
        expect(next.text, '0.12 + 0.50');
        expect(next.cursor, 7);
      });

      test('at start of block appends literally (no split)', () {
        // "12.50", cursor no início (digitsBefore=0).
        const state = EditorState(text: '12.50', cursor: 0);
        final next = ExpressionEditor.insertOperator(state, '+', separator);

        // digitsBefore=0 -> insere ' + ' literal no cursor.
        expect(next.text, ' + 12.50');
        expect(next.cursor, 3);
      });
    });

    group('insertParenthesis', () {
      test('should open a parenthesis before the number under the cursor', () {
        // `12.50`, cursor no meio do número (pos 2).
        const state = EditorState(text: '12.50', cursor: 2);
        final next = ExpressionEditor.insertParenthesis(state);

        expect(next.text, '( 12.50');
      });

      test('should never insert an unmatched closing parenthesis', () {
        const state = EditorState(text: '12.50', cursor: 2);
        final next = ExpressionEditor.insertParenthesis(state);

        expect(next.text, isNot(contains(')')));
      });

      test(
        'should keep the cursor anchored to the same digit when opening',
        () {
          const state = EditorState(text: '12.50', cursor: 2);
          final next = ExpressionEditor.insertParenthesis(state);

          // Cursor estava entre `2` e `.` em `12.50`; após prefixar `( `,
          // continua entre `2` e `.` em `( 12.50`.
          expect(next.cursor, 4);
        },
      );

      test('should open the parenthesis before the block, not at the end', () {
        // `10.00 + 5.00`, cursor entre `5` e `.` (pos 10).
        const state = EditorState(text: '10.00 + 5.00', cursor: 10);
        final next = ExpressionEditor.insertParenthesis(state);

        expect(next.text, '10.00 + ( 5.00');
      });

      test('should close at the end of the block when one paren is open', () {
        // `( 12.50`, cursor entre `2` e `.` (pos 4).
        const state = EditorState(text: '( 12.50', cursor: 4);
        final next = ExpressionEditor.insertParenthesis(state);

        expect(next.text, '( 12.50 )');
        expect(ExpressionEditor.countOpenParens(next.text), 0);
      });

      test('should close before the trailing part of the expression', () {
        // `( 12.50 + 3.00`, cursor entre `2` e `.` do primeiro número.
        const state = EditorState(text: '( 12.50 + 3.00', cursor: 4);
        final next = ExpressionEditor.insertParenthesis(state);

        expect(next.text, '( 12.50 ) + 3.00');
      });
    });

    group('applyPercent', () {
      test('appends % to the end of the block under the cursor', () {
        const state = EditorState(text: '12.50 + 3.00', cursor: 2);
        final next = ExpressionEditor.applyPercent(state);

        expect(next.text, '12.50% + 3.00');
        expect(next.cursor, 6);
      });

      test('is a no-op when the block already ends with %', () {
        const state = EditorState(text: '12.50%', cursor: 2);
        final next = ExpressionEditor.applyPercent(state);

        expect(next.text, '12.50%');
        expect(next.cursor, 2);
      });

      test('is a no-op when the cursor is not touching a number block', () {
        const state = EditorState(text: ' + ', cursor: 1);
        final next = ExpressionEditor.applyPercent(state);

        expect(next.text, ' + ');
        expect(next.cursor, 1);
      });
    });

    group('countOpenParens', () {
      test('counts unmatched opening parentheses', () {
        expect(ExpressionEditor.countOpenParens(''), 0);
        expect(ExpressionEditor.countOpenParens('( 12.50'), 1);
        expect(ExpressionEditor.countOpenParens('( 12.50 )'), 0);
        expect(ExpressionEditor.countOpenParens('( ( 1.00 )'), 1);
      });
    });

    group('normalizeForEvaluator', () {
      test('removes thousand separators with dot as decimal separator', () {
        final normalized = ExpressionEditor.normalizeForEvaluator(
          '1,234.56 + 2.00',
          DecimalSeparator.dot,
        );

        expect(normalized, '1234.56 + 2.00');
      });

      test('converts comma decimal separator back to dot', () {
        final normalized = ExpressionEditor.normalizeForEvaluator(
          '1.234,56 + 2,00',
          DecimalSeparator.comma,
        );

        expect(normalized, '1234.56 + 2.00');
      });
    });
  });
}
