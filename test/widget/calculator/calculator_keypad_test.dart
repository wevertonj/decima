import 'package:decima/ui/calculator/widgets/calculator_button.dart';
import 'package:decima/ui/calculator/widgets/calculator_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  CalculatorKeypad buildKeypad({
    ValueChanged<String>? onDigit,
    ValueChanged<String>? onOperator,
    VoidCallback? onEquals,
    VoidCallback? onClear,
    VoidCallback? onParenthesis,
    VoidCallback? onPercent,
    VoidCallback? onDoubleZero,
    VoidCallback? onTripleZero,
  }) {
    return CalculatorKeypad(
      onDigit: onDigit ?? (_) {},
      onOperator: onOperator ?? (_) {},
      onEquals: onEquals ?? () {},
      onClear: onClear ?? () {},
      onParenthesis: onParenthesis ?? () {},
      onPercent: onPercent ?? () {},
      onDoubleZero: onDoubleZero ?? () {},
      onTripleZero: onTripleZero ?? () {},
    );
  }

  group('CalculatorKeypad', () {
    group('rendering', () {
      testWidgets('should display all numeric buttons', (tester) async {
        await tester.pumpApp(Scaffold(body: buildKeypad()));

        for (final digit in [
          '0',
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8',
          '9',
        ]) {
          expect(
            find.text(digit),
            findsOneWidget,
            reason: 'Missing digit $digit',
          );
        }
      });

      testWidgets('should display all operator buttons', (tester) async {
        await tester.pumpApp(Scaffold(body: buildKeypad()));

        expect(find.text('÷'), findsOneWidget);
        expect(find.text('×'), findsOneWidget);
        expect(find.text('−'), findsOneWidget);
        expect(find.text('+'), findsOneWidget);
      });

      testWidgets('should display contextual action buttons', (tester) async {
        await tester.pumpApp(Scaffold(body: buildKeypad()));

        expect(find.text('C'), findsOneWidget);
        expect(find.text('%'), findsOneWidget);
        expect(find.text('='), findsOneWidget);
        expect(find.text('( )'), findsOneWidget);
      });

      testWidgets('should not display the legacy backspace icon', (
        tester,
      ) async {
        await tester.pumpApp(Scaffold(body: buildKeypad()));

        expect(find.byIcon(Icons.backspace_rounded), findsNothing);
      });

      testWidgets('should display double zero and triple zero buttons', (
        tester,
      ) async {
        await tester.pumpApp(Scaffold(body: buildKeypad()));

        expect(find.text('00'), findsOneWidget);
        expect(find.text('000'), findsOneWidget);
      });

      testWidgets('should have exactly 20 CalculatorButton widgets', (
        tester,
      ) async {
        await tester.pumpApp(Scaffold(body: buildKeypad()));

        expect(find.byType(CalculatorButton), findsNWidgets(20));
      });
    });

    group('interaction', () {
      testWidgets('should call onDigit with correct digit', (tester) async {
        String? tappedDigit;

        await tester.pumpApp(
          Scaffold(body: buildKeypad(onDigit: (d) => tappedDigit = d)),
        );

        await tester.tap(find.text('7'));
        await tester.pumpAndSettle();

        expect(tappedDigit, '7');
      });

      testWidgets('should call onOperator with correct operator', (
        tester,
      ) async {
        String? tappedOperator;

        await tester.pumpApp(
          Scaffold(body: buildKeypad(onOperator: (op) => tappedOperator = op)),
        );

        await tester.tap(find.text('+'));
        await tester.pumpAndSettle();

        expect(tappedOperator, '+');
      });

      testWidgets('should call onEquals when = tapped', (tester) async {
        var equalsCalled = false;

        await tester.pumpApp(
          Scaffold(body: buildKeypad(onEquals: () => equalsCalled = true)),
        );

        await tester.tap(find.text('='));
        await tester.pumpAndSettle();

        expect(equalsCalled, isTrue);
      });

      testWidgets('should call onClear when C tapped', (tester) async {
        var clearCalled = false;

        await tester.pumpApp(
          Scaffold(body: buildKeypad(onClear: () => clearCalled = true)),
        );

        await tester.tap(find.text('C'));
        await tester.pumpAndSettle();

        expect(clearCalled, isTrue);
      });

      testWidgets('should call onParenthesis when ( ) tapped', (tester) async {
        var parenCalled = false;

        await tester.pumpApp(
          Scaffold(body: buildKeypad(onParenthesis: () => parenCalled = true)),
        );

        await tester.tap(find.text('( )'));
        await tester.pumpAndSettle();

        expect(parenCalled, isTrue);
      });

      testWidgets('should call onPercent when % tapped', (tester) async {
        var percentCalled = false;

        await tester.pumpApp(
          Scaffold(body: buildKeypad(onPercent: () => percentCalled = true)),
        );

        await tester.tap(find.text('%'));
        await tester.pumpAndSettle();

        expect(percentCalled, isTrue);
      });

      testWidgets('should call onDoubleZero when 00 tapped', (tester) async {
        var doubleZeroCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: buildKeypad(onDoubleZero: () => doubleZeroCalled = true),
          ),
        );

        await tester.tap(find.text('00'));
        await tester.pumpAndSettle();

        expect(doubleZeroCalled, isTrue);
      });

      testWidgets('should call onTripleZero when 000 tapped', (tester) async {
        var tripleZeroCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: buildKeypad(onTripleZero: () => tripleZeroCalled = true),
          ),
        );

        await tester.tap(find.text('000'));
        await tester.pumpAndSettle();

        expect(tripleZeroCalled, isTrue);
      });
    });

    testWidgets('should keep C button active by default', (tester) async {
      await tester.pumpApp(Scaffold(body: buildKeypad()));

      final clearButton = tester.widget<CalculatorButton>(
        find.ancestor(
          of: find.text('C'),
          matching: find.byType(CalculatorButton),
        ),
      );

      expect(clearButton.isDimmed, isFalse);
    });

    group('rapid input', () {
      testWidgets('should dispatch every digit in a rapid burst', (
        tester,
      ) async {
        final tappedDigits = <String>[];

        await tester.pumpApp(
          Scaffold(body: buildKeypad(onDigit: tappedDigits.add)),
        );

        const sequence = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
        for (final d in sequence) {
          await tester.tap(find.text(d));
          await tester.pump(const Duration(milliseconds: 8));
        }
        await tester.pumpAndSettle();

        expect(tappedDigits, sequence);
      });

      testWidgets('should dispatch operators and digits in mixed burst', (
        tester,
      ) async {
        final tapped = <String>[];

        await tester.pumpApp(
          Scaffold(
            body: buildKeypad(
              onDigit: (d) => tapped.add('d:$d'),
              onOperator: (op) => tapped.add('o:$op'),
              onEquals: () => tapped.add('='),
            ),
          ),
        );

        await tester.tap(find.text('1'));
        await tester.pump(const Duration(milliseconds: 5));
        await tester.tap(find.text('+'));
        await tester.pump(const Duration(milliseconds: 5));
        await tester.tap(find.text('2'));
        await tester.pump(const Duration(milliseconds: 5));
        await tester.tap(find.text('='));
        await tester.pumpAndSettle();

        expect(tapped, ['d:1', 'o:+', 'd:2', '=']);
      });
    });
  });
}
