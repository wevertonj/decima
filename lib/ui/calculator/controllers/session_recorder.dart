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

  /// Raw expression/result pairs accumulated during the current session.
  final List<HistoryLine> _lines = [];

  /// Database ID of the current session. `null` when no session has been
  /// persisted yet. Set after the first `=` press and reset on
  /// [startNewSession].
  int? _sessionId;

  /// Number of session lines already persisted. Used to skip redundant
  /// save calls (e.g., `clear()` right after `=` should not re-add).
  int _persistedLineCount = 0;

  /// In-flight `add` for the current session, resolving with the id assigned
  /// by the database. `null` when no creation is pending. Subsequent saves
  /// chain onto it instead of issuing a second `add`.
  Future<int?>? _pendingAdd;

  /// Chain of every write already issued. [pendingWrite] expõe a cadeia para
  /// o flush aguardar — o app fechando nunca interrompe uma escrita em curso.
  Future<void> _pendingWrite = Future<void>.value();

  /// Incremented whenever the session is reset (clear, load, paste). Lets an
  /// in-flight `add` know its id belongs to a session that no longer exists.
  int _generation = 0;

  /// Future completing once every write issued so far has landed.
  Future<void> get pendingWrite => _pendingWrite;

  /// Adiciona uma linha à sessão corrente (sem persistir — ver [persist]).
  void append(HistoryLine line) => _lines.add(line);

  /// Persists or updates the current session lines as a single
  /// [HistoryEntry].
  ///
  /// On the first call within a session, creates a new row in the database
  /// and stores its ID in [_sessionId]. Subsequent calls update the existing
  /// row with the latest lines and result. No-op when there are no new lines
  /// since the last persist.
  ///
  /// Returns a future that completes once every write issued so far has
  /// landed.
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
      // The `add` for the first line has not returned an id yet. Chain the
      // update onto the id it produces instead of creating a second session.
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
          // The session may have been reset (clear/load/paste) while the add
          // was in flight — the id then belongs to a session that is gone.
          if (_generation == generation) {
            _pendingAdd = null;
            _sessionId = saved.id;
          }

          return saved.id;
        });
    _pendingAdd = add;

    return _trackWrite(add);
  }

  /// Drops every trace of the current session so the next lines start a new
  /// one. An `add` still in flight is detached: its id no longer lands in
  /// [_sessionId], but the update chained onto it still writes to the
  /// session those lines belong to.
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

  /// Appends [write] to the chain of pending writes and returns a future
  /// completing when it lands. A failed write never poisons the chain: later
  /// waits still complete, so the app is always able to close.
  Future<void> _trackWrite(Future<void> write) {
    // O encadeamento só escuta [write] um microtask depois; sem o ignore(),
    // uma escrita que falha antes disso vira erro não tratado na zone.
    write.ignore();
    final chained = _pendingWrite.then((_) => write);
    _pendingWrite = chained.catchError((_) {});

    return chained;
  }
}
