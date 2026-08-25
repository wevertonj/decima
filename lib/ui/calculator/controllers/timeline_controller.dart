import 'package:decima/domain/entities/calculation.dart';

/// Linhas de cálculo da sessão exibidas na timeline, com janela de
/// visibilidade incremental ("load more" carrega lotes de 20 para cima).
class TimelineController {
  static const int _loadMoreCount = 20;

  final List<Calculation> _entries = [];
  int _visibleCount = 20;

  int get maxVisibleEntries => _visibleCount;

  bool get hasEntries => _entries.isNotEmpty;

  List<Calculation> get entries => List.unmodifiable(_entries);

  List<Calculation> get visibleEntries {
    if (_entries.length <= _visibleCount) {
      return List.unmodifiable(_entries);
    }

    final start = _entries.length - _visibleCount;

    return List.unmodifiable(_entries.sublist(start));
  }

  bool get hasMore => _entries.length > _visibleCount;

  void add(Calculation entry) => _entries.add(entry);

  void clear() => _entries.clear();

  void loadMore() => _visibleCount += _loadMoreCount;
}
