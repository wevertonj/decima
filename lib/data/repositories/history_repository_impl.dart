import 'package:decima/data/database/app_database.dart';
import 'package:decima/data/models/history_model.dart';
import 'package:decima/data/repositories/history_repository.dart';
import 'package:decima/domain/entities/history_entry.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  static const String _tableName = 'history';

  final AppDatabase _database;

  HistoryRepositoryImpl({required AppDatabase database}) : _database = database;

  @override
  Future<List<HistoryEntry>> getAll() async {
    final maps = await _database.database.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => HistoryModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<HistoryEntry?> getById(int id) async {
    final maps = await _database.database.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return HistoryModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<List<HistoryEntry>> getPaginated({
    required int limit,
    required int offset,
  }) async {
    final maps = await _database.database.query(
      _tableName,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => HistoryModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<HistoryEntry>> getFavorites({
    required int limit,
    required int offset,
  }) async {
    final maps = await _database.database.query(
      _tableName,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => HistoryModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<HistoryEntry> add(HistoryEntry entry) async {
    final model = HistoryModel.fromEntity(entry);
    final id = await _database.database.insert(_tableName, model.toMap());

    return entry.copyWith(id: id);
  }

  @override
  Future<void> update(HistoryEntry entry) async {
    if (entry.id == null) return;

    final model = HistoryModel.fromEntity(entry);
    final map = model.toMap();
    // Only update expression (lines JSON) and result.
    await _database.database.update(
      _tableName,
      {'expression': map['expression'], 'result': map['result']},
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<void> updateName(int id, String? name) async {
    await _database.database.update(
      _tableName,
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> toggleFavorite(int id) async {
    await _database.database.rawUpdate(
      'UPDATE $_tableName SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await _database.database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clear() async {
    await _database.database.delete(_tableName);
  }
}
