import 'package:decima/domain/entities/calculation.dart';
import 'package:decima/ui/calculator/widgets/animated_input_display.dart';
import 'package:decima/ui/calculator/widgets/timeline_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('TimelineDisplay', () {
    final now = DateTime(2026, 4, 19, 12, 0);
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('rendering', () {
      testWidgets('should display full expression inline', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '12.50 + 3.00',
              previewResult: '15.50',
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        final display = tester.widget<AnimatedInputDisplay>(
          find.byType(AnimatedInputDisplay),
        );
        expect(display.text, equals('12.50 + 3.00'));
      });

      testWidgets('should display current value', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '0.00',
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        final display = tester.widget<AnimatedInputDisplay>(
          find.byType(AnimatedInputDisplay),
        );
        expect(display.text, equals('0.00'));
      });

      testWidgets('should display preview result when available', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '10.00 + 5.00',
              previewResult: '15.00',
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        expect(find.text('15.00'), findsOneWidget);
      });

      testWidgets('should not display preview when null', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '0.00',
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        final display = tester.widget<AnimatedInputDisplay>(
          find.byType(AnimatedInputDisplay),
        );
        expect(display.text, equals('0.00'));
      });

      testWidgets('should display past calculation entries', (tester) async {
        final entries = [
          Calculation(
            expression: '10.00 + 5.00',
            result: '15.00',
            timestamp: now,
          ),
          Calculation(
            expression: '20.00 × 2.00',
            result: '40.00',
            timestamp: now,
          ),
        ];

        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: entries,
              displayText: '0.00',
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        expect(find.text('10.00 + 5.00'), findsOneWidget);
        expect(find.text('15.00'), findsOneWidget);
        expect(find.text('20.00 × 2.00'), findsOneWidget);
        expect(find.text('40.00'), findsOneWidget);
      });
    });

    group('load more', () {
      testWidgets('should show load more button when hasMore is true', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '0.00',
              previewResult: null,
              hasMore: true,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        expect(find.text('Load more'), findsOneWidget);
      });

      testWidgets('should not show load more button when hasMore is false', (
        tester,
      ) async {
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '0.00',
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        expect(find.text('Load more'), findsNothing);
      });

      testWidgets('should call onLoadMore when load more is tapped', (
        tester,
      ) async {
        var loadMoreCalled = false;

        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '0.00',
              previewResult: null,
              hasMore: true,
              onLoadMore: () => loadMoreCalled = true,
              displayController: controller,
            ),
          ),
        );

        await tester.tap(find.text('Load more'));
        await tester.pumpAndSettle();

        expect(loadMoreCalled, isTrue);
      });
    });

    group('layout', () {
      testWidgets('should display expression and result for each entry', (
        tester,
      ) async {
        final entries = [
          Calculation(
            expression: '5.00 + 5.00',
            result: '10.00',
            timestamp: now,
          ),
        ];

        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: entries,
              displayText: '10.00 + 2.00',
              previewResult: '12.00',
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        // Entrada passada
        expect(find.text('5.00 + 5.00'), findsOneWidget);
        expect(find.text('10.00'), findsOneWidget);

        // Expressão atual (display animado por caractere)
        final display = tester.widget<AnimatedInputDisplay>(
          find.byType(AnimatedInputDisplay),
        );
        expect(display.text, equals('10.00 + 2.00'));

        // Preview
        expect(find.text('12.00'), findsOneWidget);
      });
    });

    group('adaptive font scaling', () {
      testWidgets('should use base font size for short text', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '0.00',
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        final display = tester.widget<AnimatedInputDisplay>(
          find.byType(AnimatedInputDisplay),
        );
        expect(display.fontSize, equals(48));
      });

      testWidgets('should reduce font size for long text', (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '123,456.00 + 789,012.00 + 345,678.00 + 901,234.00',
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        final display = tester.widget<AnimatedInputDisplay>(
          find.byType(AnimatedInputDisplay),
        );
        expect(display.fontSize < 48, isTrue);
      });

      testWidgets('should use smallest font for very long text', (
        tester,
      ) async {
        final veryLongText =
            '1.00 + 2.00 + 3.00 + 4.00 + 5.00 + 6.00 + 7.00 + 8.00 + 9.00 + 10.00 + 11.00';
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: veryLongText,
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        final display = tester.widget<AnimatedInputDisplay>(
          find.byType(AnimatedInputDisplay),
        );
        expect(display.fontSize, equals(28));
        expect(display.multiline, isTrue);
      });

      testWidgets('should reset font size after clearing', (tester) async {
        controller.text = '123,456.00 + 789,012.00 + 345,678.00';
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '123,456.00 + 789,012.00 + 345,678.00',
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        // Reconstrói com texto curto (simulando o clear)
        await tester.pumpApp(
          Scaffold(
            body: TimelineDisplay(
              entries: const [],
              displayText: '0.00',
              previewResult: null,
              hasMore: false,
              onLoadMore: () {},
              displayController: controller,
            ),
          ),
        );

        final display = tester.widget<AnimatedInputDisplay>(
          find.byType(AnimatedInputDisplay),
        );
        expect(display.fontSize, equals(48));
      });
    });
  });
}
