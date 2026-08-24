import 'package:decima/data/repositories/history_repository.dart';
import 'package:decima/domain/entities/history_entry.dart';
import 'package:flutter/foundation.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required HistoryRepository historyRepository})
    : _historyRepository = historyRepository;

  final HistoryRepository _historyRepository;

  final List<HistoryEntry> _entries = [];
  bool _hasMore = false;
  bool _isLoading = false;
  bool _showFavoritesOnly = false;
  int _offset = 0;

  static const int _pageSize = 20;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  bool get hasMore => _hasMore;

  bool get isLoading => _isLoading;

  bool get showFavoritesOnly => _showFavoritesOnly;

  Future<void> loadEntries() async {
    _isLoading = true;
    _offset = 0;
    _entries.clear();
    notifyListeners();

    final results = await _fetchPage(0);

    _entries.addAll(results);
    _hasMore = results.length >= _pageSize;
    _offset = results.length;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    final results = await _fetchPage(_offset);

    _entries.addAll(results);
    _hasMore = results.length >= _pageSize;
    _offset += results.length;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    await _historyRepository.delete(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _historyRepository.clear();
    _entries.clear();
    _hasMore = false;
    _offset = 0;
    notifyListeners();
  }

  Future<void> updateName(int id, String? name) async {
    await _historyRepository.updateName(id, name);

    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(name: name);
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(int id) async {
    await _historyRepository.toggleFavorite(id);

    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(
        isFavorite: !_entries[index].isFavorite,
      );
      notifyListeners();
    }
  }

  Future<void> setShowFavoritesOnly(bool value) async {
    _showFavoritesOnly = value;
    await loadEntries();
  }

  Future<List<HistoryEntry>> _fetchPage(int offset) {
    if (_showFavoritesOnly) {
      return _historyRepository.getFavorites(limit: _pageSize, offset: offset);
    }

    return _historyRepository.getPaginated(limit: _pageSize, offset: offset);
  }
}
