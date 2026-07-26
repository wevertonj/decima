import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wevacalc/ui/calculator/keyboard_shortcuts.dart';

void main() {
  CalculatorKeyCommand? resolve(
    LogicalKeyboardKey key, {
    String? character,
    bool control = false,
    bool meta = false,
  }) {
    return KeyboardShortcuts.resolve(
      logicalKey: key,
      character: character,
      isControlPressed: control,
      isMetaPressed: meta,
    );
  }

  group('KeyboardShortcuts.resolve', () {
    group('digits', () {
      const digitKeys = <LogicalKeyboardKey>[
        LogicalKeyboardKey.digit0,
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
        LogicalKeyboardKey.digit7,
        LogicalKeyboardKey.digit8,
        LogicalKeyboardKey.digit9,
      ];

      const numpadKeys = <LogicalKeyboardKey>[
        LogicalKeyboardKey.numpad0,
        LogicalKeyboardKey.numpad1,
        LogicalKeyboardKey.numpad2,
        LogicalKeyboardKey.numpad3,
        LogicalKeyboardKey.numpad4,
        LogicalKeyboardKey.numpad5,
        LogicalKeyboardKey.numpad6,
        LogicalKeyboardKey.numpad7,
        LogicalKeyboardKey.numpad8,
        LogicalKeyboardKey.numpad9,
      ];

      test('should map every digit key to a digit command', () {
        for (var i = 0; i < digitKeys.length; i++) {
          expect(
            resolve(digitKeys[i], character: '$i'),
            equals(CalculatorKeyCommand(CalculatorKeyAction.digit, '$i')),
            reason: 'digit $i',
          );
        }
      });

      test('should map digit keys without character via the key label', () {
        expect(
          resolve(LogicalKeyboardKey.digit7),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.digit, '7')),
        );
      });

      test('should map every numpad digit key to a digit command', () {
        for (var i = 0; i < numpadKeys.length; i++) {
          expect(
            resolve(numpadKeys[i]),
            equals(CalculatorKeyCommand(CalculatorKeyAction.digit, '$i')),
            reason: 'numpad $i',
          );
        }
      });
    });

    group('operators', () {
      test('should map plus to the add operator', () {
        expect(
          resolve(LogicalKeyboardKey.add, character: '+'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '+')),
        );
      });

      test('should map hyphen to the minus sign operator', () {
        expect(
          resolve(LogicalKeyboardKey.minus, character: '-'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '−')),
        );
      });

      test('should map asterisk to the multiply operator', () {
        expect(
          resolve(LogicalKeyboardKey.digit8, character: '*'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '×')),
        );
      });

      test('should map lower and upper case x to the multiply operator', () {
        expect(
          resolve(LogicalKeyboardKey.keyX, character: 'x'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '×')),
        );
        expect(
          resolve(LogicalKeyboardKey.keyX, character: 'X'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '×')),
        );
      });

      test('should map slash to the divide operator', () {
        expect(
          resolve(LogicalKeyboardKey.slash, character: '/'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '÷')),
        );
      });

      test('should map numpad operator keys', () {
        expect(
          resolve(LogicalKeyboardKey.numpadAdd),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '+')),
        );
        expect(
          resolve(LogicalKeyboardKey.numpadSubtract),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '−')),
        );
        expect(
          resolve(LogicalKeyboardKey.numpadMultiply),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '×')),
        );
        expect(
          resolve(LogicalKeyboardKey.numpadDivide),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '÷')),
        );
      });

      test('should map already-typographic operator characters', () {
        expect(
          resolve(LogicalKeyboardKey.minus, character: '−'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '−')),
        );
        expect(
          resolve(LogicalKeyboardKey.keyX, character: '×'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '×')),
        );
        expect(
          resolve(LogicalKeyboardKey.slash, character: '÷'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.operator, '÷')),
        );
      });
    });

    group('equals', () {
      test('should map Enter to equals', () {
        expect(
          resolve(LogicalKeyboardKey.enter),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.equals)),
        );
      });

      test('should map numpad Enter to equals', () {
        expect(
          resolve(LogicalKeyboardKey.numpadEnter),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.equals)),
        );
      });

      test('should map the equal sign to equals', () {
        expect(
          resolve(LogicalKeyboardKey.equal, character: '='),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.equals)),
        );
      });

      test('should map numpad equal to equals', () {
        expect(
          resolve(LogicalKeyboardKey.numpadEqual),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.equals)),
        );
      });
    });

    group('editing', () {
      test('should map Backspace to backspace', () {
        expect(
          resolve(LogicalKeyboardKey.backspace),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.backspace)),
        );
      });

      test('should map Escape to clear all', () {
        expect(
          resolve(LogicalKeyboardKey.escape),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.clearAll)),
        );
      });

      test('should map Delete to clear all', () {
        expect(
          resolve(LogicalKeyboardKey.delete),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.clearAll)),
        );
      });
    });

    group('percentage and parentheses', () {
      test('should map the percent character to percentage', () {
        expect(
          resolve(LogicalKeyboardKey.digit5, character: '%'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.percent)),
        );
      });

      test('should map the percent logical key to percentage', () {
        expect(
          resolve(LogicalKeyboardKey.percent),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.percent)),
        );
      });

      test('should map both parentheses to the parenthesis toggle', () {
        expect(
          resolve(LogicalKeyboardKey.digit9, character: '('),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.parenthesis)),
        );
        expect(
          resolve(LogicalKeyboardKey.digit0, character: ')'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.parenthesis)),
        );
      });
    });

    group('decimal separator keys', () {
      test('should map period to the double zero shortcut', () {
        expect(
          resolve(LogicalKeyboardKey.period, character: '.'),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.doubleZero)),
        );
      });

      test('should map comma to the double zero shortcut', () {
        expect(
          resolve(LogicalKeyboardKey.comma, character: ','),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.doubleZero)),
        );
      });

      test('should map numpad decimal to the double zero shortcut', () {
        expect(
          resolve(LogicalKeyboardKey.numpadDecimal),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.doubleZero)),
        );
      });
    });

    group('cursor movement', () {
      test('should map arrow left to cursor left', () {
        expect(
          resolve(LogicalKeyboardKey.arrowLeft),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.cursorLeft)),
        );
      });

      test('should map arrow right to cursor right', () {
        expect(
          resolve(LogicalKeyboardKey.arrowRight),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.cursorRight)),
        );
      });
    });

    group('clipboard', () {
      test('should map Ctrl+C to copy', () {
        expect(
          resolve(LogicalKeyboardKey.keyC, character: 'c', control: true),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.copy)),
        );
      });

      test('should map Cmd+C to copy', () {
        expect(
          resolve(LogicalKeyboardKey.keyC, character: 'c', meta: true),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.copy)),
        );
      });

      test('should map Ctrl+V to paste', () {
        expect(
          resolve(LogicalKeyboardKey.keyV, character: 'v', control: true),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.paste)),
        );
      });

      test('should map Cmd+V to paste', () {
        expect(
          resolve(LogicalKeyboardKey.keyV, character: 'v', meta: true),
          equals(const CalculatorKeyCommand(CalculatorKeyAction.paste)),
        );
      });

      test('should ignore other modified combinations', () {
        expect(
          resolve(LogicalKeyboardKey.keyX, character: 'x', control: true),
          isNull,
        );
        expect(
          resolve(LogicalKeyboardKey.digit5, character: '5', control: true),
          isNull,
        );
      });
    });

    group('unmapped keys', () {
      test('should ignore plain letters', () {
        expect(resolve(LogicalKeyboardKey.keyA, character: 'a'), isNull);
        expect(resolve(LogicalKeyboardKey.keyZ, character: 'z'), isNull);
      });

      test('should ignore modifier keys pressed alone', () {
        expect(resolve(LogicalKeyboardKey.shiftLeft), isNull);
        expect(resolve(LogicalKeyboardKey.controlLeft, control: true), isNull);
        expect(resolve(LogicalKeyboardKey.altLeft), isNull);
      });

      test('should ignore function and navigation keys', () {
        expect(resolve(LogicalKeyboardKey.f1), isNull);
        expect(resolve(LogicalKeyboardKey.tab), isNull);
        expect(resolve(LogicalKeyboardKey.arrowUp), isNull);
        expect(resolve(LogicalKeyboardKey.arrowDown), isNull);
      });
    });
  });

  group('CalculatorKeyCommand', () {
    test('should implement value equality', () {
      expect(
        const CalculatorKeyCommand(CalculatorKeyAction.digit, '1'),
        equals(const CalculatorKeyCommand(CalculatorKeyAction.digit, '1')),
      );
      expect(
        const CalculatorKeyCommand(CalculatorKeyAction.digit, '1'),
        isNot(equals(const CalculatorKeyCommand(CalculatorKeyAction.digit))),
      );
      expect(
        const CalculatorKeyCommand(CalculatorKeyAction.digit, '1').hashCode,
        equals(
          const CalculatorKeyCommand(CalculatorKeyAction.digit, '1').hashCode,
        ),
      );
    });
  });
}
