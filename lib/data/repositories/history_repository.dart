import 'package:decima/domain/entities/history_entry.dart';

abstract class HistoryRepository {
  Future<List<HistoryEntry>> getAll();
  Future<HistoryEntry?> getById(int id);
  Future<List<HistoryEntry>> getPaginated({
    required int limit,
    required int offset,
  });
  Future<List<HistoryEntry>> getFavorites({
    required int limit,
    required int offset,
  });
  Future<HistoryEntry> add(HistoryEntry entry);
  Future<void> update(HistoryEntry entry);
  Future<void> updateName(int id, String? name);
  Future<void> toggleFavorite(int id);
  Future<void> delete(int id);
  Future<void> clear();
}
