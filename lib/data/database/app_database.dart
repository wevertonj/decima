import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String _databaseName = 'wevacalc.db';
  static const int _databaseVersion = 1;

  final DatabaseFactory _databaseFactory;

  /// Quando fornecido, o banco é criado dentro do diretório resolvido
  /// (caminho absoluto). Quando null, o path relativo fica a cargo da
  /// factory (no sqflite mobile, o diretório de databases do app).
  final Future<String> Function()? _directoryResolver;

  Database? _database;

  AppDatabase({
    DatabaseFactory? databaseFactory,
    Future<String> Function()? directoryResolver,
  }) : _databaseFactory = databaseFactory ?? databaseFactorySqflitePlugin,
       _directoryResolver = directoryResolver;

  Database get database {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }

    return _database!;
  }

  Future<void> initialize({bool inMemory = false}) async {
    String path;
    if (inMemory) {
      path = inMemoryDatabasePath;
    } else if (_directoryResolver != null) {
      path = p.join(await _directoryResolver(), _databaseName);
    } else {
      path = _databaseName;
    }
    _database = await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expression TEXT NOT NULL,
        result TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        name TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
