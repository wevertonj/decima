import 'dart:async';

import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';
import 'package:decima/ui/calculator/controllers/session_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/history_fixtures.dart';
import '../../../../mocks/mock_history_repository.dart';

void main() {
  late SessionRecorder recorder;
  late MockHistoryRepository mockHistoryRepository;

  final line1 = HistoryLine(expression: '10.00 + 5.00', result: '15.00');
  final line2 = HistoryLine(expression: '15.00 × 2.00', result: '30.00');

  setUpAll(() {
    registerFallbackValue(
      HistoryEntry(
        lines: [HistoryLine(expression: '', result: '')],
        result: '',
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockHistoryRepository = MockHistoryRepository();
    when(() => mockHistoryRepository.add(any())).thenAnswer(
      (invocation) async =>
          (invocation.positionalArguments.first as HistoryEntry).copyWith(
            id: 1,
          ),
    );
    when(() => mockHistoryRepository.update(any())).thenAnswer((_) async {});
    recorder = SessionRecorder(historyRepository: mockHistoryRepository);
  });

  group('SessionRecorder', () {
    group('persist', () {
      test('should be a no-op when there are no lines', () async {
        await recorder.persist();

        verifyNever(() => mockHistoryRepository.add(any()));
        verifyNever(() => mockHistoryRepository.update(any()));
      });

      test('should create the session on the first persist', () async {
        recorder.append(line1);

        await recorder.persist();

        final captured =
            verify(
                  () => mockHistoryRepository.add(captureAny()),
                ).captured.single
                as HistoryEntry;
        expect(captured.id, isNull);
        expect(captured.lines, [line1]);
        expect(captured.result, '15.00');
      });

      test(
        'should update the created session on subsequent persists',
        () async {
          recorder.append(line1);
          await recorder.persist();

          recorder.append(line2);
          await recorder.persist();

          final captured =
              verify(
                    () => mockHistoryRepository.update(captureAny()),
                  ).captured.single
                  as HistoryEntry;
          expect(captured.id, 1);
          expect(captured.lines, [line1, line2]);
          expect(captured.result, '30.00');
        },
      );

      test(
        'should be a no-op when no new line landed since the last persist',
        () async {
          recorder.append(line1);
          await recorder.persist();

          await recorder.persist();

          verify(() => mockHistoryRepository.add(any())).called(1);
          verifyNever(() => mockHistoryRepository.update(any()));
        },
      );

      test('should chain the update onto an add still in flight instead of '
          'creating a second session', () async {
        final pendingAdd = Completer<HistoryEntry>();
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) => pendingAdd.future);

        recorder.append(line1);
        final firstWrite = recorder.persist();

        recorder.append(line2);
        final secondWrite = recorder.persist();

        pendingAdd.complete(HistoryFixtures.entry1);
        await Future.wait([firstWrite, secondWrite]);

        verify(() => mockHistoryRepository.add(any())).called(1);
        final captured =
            verify(
                  () => mockHistoryRepository.update(captureAny()),
                ).captured.single
                as HistoryEntry;
        expect(captured.id, HistoryFixtures.entry1.id);
        expect(captured.lines, [line1, line2]);
      });
    });

    group('startNewSession', () {
      test(
        'should start a fresh session after the previous one persisted',
        () async {
          recorder.append(line1);
          await recorder.persist();

          recorder.startNewSession();
          recorder.append(line2);
          await recorder.persist();

          verify(() => mockHistoryRepository.add(any())).called(2);
          verifyNever(() => mockHistoryRepository.update(any()));
        },
      );

      test('should detach an add still in flight — its id never lands in the '
          'new session', () async {
        final pendingAdd = Completer<HistoryEntry>();
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) => pendingAdd.future);

        recorder.append(line1);
        final firstWrite = recorder.persist();

        // A sessão é descartada enquanto o add ainda está em voo.
        recorder.startNewSession();
        pendingAdd.complete(HistoryFixtures.entry1);
        await firstWrite;

        // A próxima linha cria uma sessão nova em vez de atualizar a antiga.
        when(() => mockHistoryRepository.add(any())).thenAnswer(
          (invocation) async =>
              (invocation.positionalArguments.first as HistoryEntry).copyWith(
                id: 2,
              ),
        );
        recorder.append(line2);
        await recorder.persist();

        verifyNever(() => mockHistoryRepository.update(any()));
        final captured =
            verify(() => mockHistoryRepository.add(captureAny())).captured.last
                as HistoryEntry;
        expect(captured.lines, [line2]);
      });
    });

    group('adoptSession', () {
      test('should treat adopted lines as persisted (no-op persist)', () async {
        recorder.adoptSession(sessionId: 7, lines: [line1]);

        await recorder.persist();

        verifyNever(() => mockHistoryRepository.add(any()));
        verifyNever(() => mockHistoryRepository.update(any()));
      });

      test('should update the adopted session when a new line lands', () async {
        recorder.adoptSession(sessionId: 7, lines: [line1]);

        recorder.append(line2);
        await recorder.persist();

        final captured =
            verify(
                  () => mockHistoryRepository.update(captureAny()),
                ).captured.single
                as HistoryEntry;
        expect(captured.id, 7);
        expect(captured.lines, [line1, line2]);
      });
    });

    group('pendingWrite', () {
      test('should complete only after an in-flight write lands', () async {
        final pendingAdd = Completer<HistoryEntry>();
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) => pendingAdd.future);

        recorder.append(line1);
        unawaited(recorder.persist());

        var flushed = false;
        unawaited(recorder.pendingWrite.then((_) => flushed = true));
        await Future<void>.delayed(Duration.zero);
        expect(flushed, isFalse);

        pendingAdd.complete(HistoryFixtures.entry1);
        await recorder.pendingWrite;
        expect(flushed, isTrue);
      });

      test('should be idempotent — awaiting twice with nothing new never '
          'issues another write', () async {
        recorder.append(line1);
        await recorder.persist();

        await recorder.pendingWrite;
        await recorder.pendingWrite;

        verify(() => mockHistoryRepository.add(any())).called(1);
      });

      test('should never be poisoned by a failed write', () async {
        when(
          () => mockHistoryRepository.add(any()),
        ).thenAnswer((_) async => throw Exception('db unavailable'));

        recorder.append(line1);
        await expectLater(recorder.persist(), throwsException);

        // A cadeia segue viva: o flush completa mesmo após a falha, então o
        // app nunca fica impossibilitado de fechar.
        await expectLater(recorder.pendingWrite, completes);
      });
    });
  });
}
