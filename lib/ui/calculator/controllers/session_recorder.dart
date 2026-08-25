import 'package:decima/data/repositories/history_repository.dart';
import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';

/// Grava a sessão de cálculos corrente como uma única [HistoryEntry].
///
/// Acumula os pares expressão/resultado da sessão e encapsula os invariantes
/// de persistência: criação no primeiro `=` e atualização nos seguintes,
/// encadeamento das escritas (uma escrita nunca é interrompida por outra),
/// gerações de sessão (um `add` em voo cujo id pertence a uma sessão já
/// descartada não contamina a próxima) e o flush idempotente no fechamento.
class SessionRecorder {
  SessionRecorder({required HistoryRepository historyRepository})
    : _historyRepository = historyRepository;

  final HistoryRepository _historyRepository;

  /// Pares crus expressão/resultado acumulados na sessão corrente.
  final List<HistoryLine> _lines = [];

  /// ID da sessão no banco; `null` até a primeira persistência. Definido no
  /// primeiro `=` e zerado em [startNewSession].
  int? _sessionId;

  /// Linhas já persistidas — evita gravações redundantes (ex.: `clear()`
  /// logo após `=` não deve regravar).
  int _persistedLineCount = 0;

  /// `add` em voo da sessão corrente, resolvendo com o id do banco; `null`
  /// sem criação pendente. Persistências seguintes encadeiam nele em vez de
  /// emitir um segundo `add`.
  Future<int?>? _pendingAdd;

  /// Cadeia de todas as escritas já emitidas. [pendingWrite] a expõe para o
  /// flush aguardar — o app fechando nunca interrompe uma escrita em curso.
  Future<void> _pendingWrite = Future<void>.value();

  /// Incrementado a cada reset de sessão (clear, load, paste). Permite a um
  /// `add` em voo saber que seu id pertence a uma sessão que já não existe.
  int _generation = 0;

  /// Completa quando toda escrita emitida até aqui tiver aterrissado.
  Future<void> get pendingWrite => _pendingWrite;

  /// Adiciona uma linha à sessão corrente (sem persistir — ver [persist]).
  void append(HistoryLine line) => _lines.add(line);

  /// Persiste as linhas da sessão como uma única [HistoryEntry]: cria a
  /// linha no banco na primeira chamada, atualiza nas seguintes; no-op sem
  /// linha nova. Devolve um future que completa quando toda escrita emitida
  /// até aqui tiver aterrissado.
  Future<void> persist() {
    if (_lines.isEmpty) return _pendingWrite;
    if (_lines.length == _persistedLineCount) return _pendingWrite;

    final lines = List.of(_lines);
    final lastResult = lines.last.result;
    _persistedLineCount = lines.length;

    final sessionId = _sessionId;
    if (sessionId != null) {
      return _trackWrite(
        _historyRepository.update(_sessionEntry(sessionId, lines, lastResult)),
      );
    }

    final pendingAdd = _pendingAdd;
    if (pendingAdd != null) {
      // O `add` da primeira linha ainda não devolveu id: encadeia o update
      // no id que ele produzir, em vez de criar uma segunda sessão.
      return _trackWrite(
        pendingAdd.then<void>((id) async {
          if (id == null) return;

          await _historyRepository.update(_sessionEntry(id, lines, lastResult));
        }),
      );
    }

    final generation = _generation;
    final add = _historyRepository
        .add(_sessionEntry(null, lines, lastResult))
        .then((saved) {
          // A sessão pode ter sido resetada com o add em voo — o id então
          // pertence a uma sessão que já não existe.
          if (_generation == generation) {
            _pendingAdd = null;
            _sessionId = saved.id;
          }

          return saved.id;
        });
    _pendingAdd = add;

    return _trackWrite(add);
  }

  /// Descarta a sessão corrente para as próximas linhas começarem outra. Um
  /// `add` em voo é desanexado: o id não aterrissa em [_sessionId], mas o
  /// update encadeado nele ainda grava na sessão dona daquelas linhas.
  void startNewSession() {
    _lines.clear();
    _detachTracking();
  }

  /// Adota uma sessão carregada do histórico: [lines] já estão persistidas
  /// sob [sessionId], então os próximos [persist] caem no ramo de update
  /// (ou viram no-op enquanto não houver linha nova).
  void adoptSession({
    required int? sessionId,
    required List<HistoryLine> lines,
  }) {
    _lines
      ..clear()
      ..addAll(lines);
    _detachTracking();
    _sessionId = sessionId;
    _persistedLineCount = _lines.length;
  }

  void _detachTracking() {
    _generation++;
    _sessionId = null;
    _persistedLineCount = 0;
    _pendingAdd = null;
  }

  HistoryEntry _sessionEntry(int? id, List<HistoryLine> lines, String result) {
    return HistoryEntry(
      id: id,
      lines: lines,
      result: result,
      createdAt: DateTime.now(),
    );
  }

  /// Anexa [write] à cadeia de escritas pendentes e devolve um future que
  /// completa quando ela aterrissar. Escrita que falha nunca envenena a
  /// cadeia: esperas posteriores completam e o app sempre consegue fechar.
  Future<void> _trackWrite(Future<void> write) {
    // O encadeamento só escuta [write] um microtask depois; sem o ignore(),
    // uma escrita que falha antes disso vira erro não tratado na zone.
    write.ignore();
    final chained = _pendingWrite.then((_) => write);
    _pendingWrite = chained.catchError((_) {});

    return chained;
  }
}
