import 'package:decima/domain/entities/calculation.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/ui/calculator/controllers/clipboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_clipboard_service.dart';

void main() {
  late ClipboardController controller;
  late MockClipboardService mockClipboardService;

  setUp(() {
    mockClipboardService = MockClipboardService();
    when(() => mockClipboardService.copyText(any())).thenAnswer((_) async {});
    when(() => mockClipboardService.readText()).thenAnswer((_) async => null);
    controller = ClipboardController(clipboardService: mockClipboardService);
  });

  group('ClipboardController', () {
    group('copyText', () {
      test('should delegate to the clipboard service', () async {
        await controller.copyText('12.50 + 3.00');

        verify(() => mockClipboardService.copyText('12.50 + 3.00')).called(1);
      });
    });

    group('copyHistory', () {
      test('should copy one line per entry in the <expression> = <result> '
          'format', () async {
        final entries = [
          Calculation(
            expression: '10.00 + 5.00',
            result: '15.00',
            timestamp: DateTime(2026),
          ),
          Calculation(
            expression: '15.00 × 2.00',
            result: '30.00',
            timestamp: DateTime(2026),
          ),
        ];

        await controller.copyHistory(entries);

        verify(
          () => mockClipboardService.copyText(
            '10.00 + 5.00 = 15.00\n15.00 × 2.00 = 30.00',
          ),
        ).called(1);
      });

      test('should be a no-op when there are no entries', () async {
        await controller.copyHistory(const []);

        verifyNever(() => mockClipboardService.copyText(any()));
      });
    });

    group('hasText', () {
      test('should be false when the clipboard is empty', () async {
        expect(await controller.hasText(), isFalse);
      });

      test(
        'should be false when the clipboard holds an empty string',
        () async {
          when(
            () => mockClipboardService.readText(),
          ).thenAnswer((_) async => '');

          expect(await controller.hasText(), isFalse);
        },
      );

      test('should be true when the clipboard holds text', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '10 + 5');

        expect(await controller.hasText(), isTrue);
      });
    });

    group('readPastedSession', () {
      test('should return null when the clipboard is empty', () async {
        expect(await controller.readPastedSession(), isNull);
      });

      test('should return null for content the parser rejects', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => 'abc');

        expect(await controller.readPastedSession(), isNull);
      });

      test('should return the open input line as tokens with no resolved '
          'lines', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '10 + 5');

        final pasted = await controller.readPastedSession();

        expect(pasted, isNotNull);
        expect(pasted!.lines, isEmpty);
        expect(pasted.inputTokens, ['10.00', '+', '5.00']);
      });

      test('should recalculate resolved lines instead of trusting the pasted '
          'result', () async {
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => '10 + 5 = 999');

        final pasted = await controller.readPastedSession();

        expect(pasted, isNotNull);
        expect(pasted!.lines, [
          HistoryLine(expression: '10.00 + 5.00', result: '15.00'),
        ]);
        expect(pasted.inputTokens, isNull);
      });

      test(
        'should return null when any resolved line cannot be evaluated',
        () async {
          // A linha parseia, mas a divisão por zero é inavaliável — nada deve
          // ser aplicado para a calculadora não ficar pela metade.
          when(
            () => mockClipboardService.readText(),
          ).thenAnswer((_) async => '10 / 0 = 0\n2 + 2');

          expect(await controller.readPastedSession(), isNull);
        },
      );

      test('should round-trip the copyHistory output back into the same '
          'lines', () async {
        final entries = [
          Calculation(
            expression: '10.00 + 5.00',
            result: '15.00',
            timestamp: DateTime(2026),
          ),
          Calculation(
            expression: '15.00 × 2.00',
            result: '30.00',
            timestamp: DateTime(2026),
          ),
        ];
        await controller.copyHistory(entries);
        final copied =
            verify(
                  () => mockClipboardService.copyText(captureAny()),
                ).captured.single
                as String;
        when(
          () => mockClipboardService.readText(),
        ).thenAnswer((_) async => copied);

        final pasted = await controller.readPastedSession();

        expect(pasted, isNotNull);
        expect(pasted!.lines, [
          HistoryLine(expression: '10.00 + 5.00', result: '15.00'),
          HistoryLine(expression: '15.00 × 2.00', result: '30.00'),
        ]);
        expect(pasted.inputTokens, isNull);
      });
    });
  });
}
