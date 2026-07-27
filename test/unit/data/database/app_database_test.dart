import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:decima/data/database/app_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('AppDatabase', () {
    test('throws StateError when accessed before initialize', () {
      final database = AppDatabase(databaseFactory: databaseFactoryFfi);

      expect(() => database.database, throwsStateError);
    });

    test('initialize inMemory does not use the directory resolver', () async {
      var resolverCalled = false;
      final database = AppDatabase(
        databaseFactory: databaseFactoryFfi,
        directoryResolver: () async {
          resolverCalled = true;

          return Directory.systemTemp.path;
        },
      );

      await database.initialize(inMemory: true);

      expect(resolverCalled, isFalse);
      expect(database.database.isOpen, isTrue);
      await database.close();
    });

    test('initialize creates the database inside the resolved directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('decima_db_test');
      addTearDown(() => tempDir.delete(recursive: true));

      final database = AppDatabase(
        databaseFactory: databaseFactoryFfi,
        directoryResolver: () async => tempDir.path,
      );

      await database.initialize();

      final dbFile = File(p.join(tempDir.path, 'decima.db'));
      expect(database.database.isOpen, isTrue);
      expect(dbFile.existsSync(), isTrue);
      await database.close();
    });

    test('without resolver keeps the factory default relative path', () async {
      final database = AppDatabase(databaseFactory: databaseFactoryFfi);

      await database.initialize(inMemory: true);

      expect(database.database.isOpen, isTrue);
      await database.close();
    });
  });
}
