import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:decima/data/database/database_factory_resolver.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('resolveDatabaseFactory', () {
    test('returns FFI factory when isDesktop is true', () {
      final factory = resolveDatabaseFactory(isDesktop: true);

      expect(factory, same(databaseFactoryFfi));
    });

    test('returns sqflite plugin factory when isDesktop is false', () {
      final factory = resolveDatabaseFactory(isDesktop: false);

      expect(factory, same(databaseFactorySqflitePlugin));
    });

    test('detects desktop platform by default (Windows)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final factory = resolveDatabaseFactory();

      expect(factory, same(databaseFactoryFfi));
    });

    test('detects mobile platform by default (Android)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final factory = resolveDatabaseFactory();

      expect(factory, same(databaseFactorySqflitePlugin));
    });

    test('FFI factory opens an in-memory database on this host', () async {
      final factory = resolveDatabaseFactory(isDesktop: true);

      final db = await factory.openDatabase(inMemoryDatabasePath);
      final result = await db.rawQuery('SELECT 1 AS value');

      expect(result.first['value'], 1);
      await db.close();
    });
  });

  group('resolveDatabaseDirectoryResolver', () {
    test('returns a resolver on desktop', () {
      final resolver = resolveDatabaseDirectoryResolver(isDesktop: true);

      expect(resolver, isNotNull);
    });

    test('returns null on mobile (sqflite uses its own databases dir)', () {
      final resolver = resolveDatabaseDirectoryResolver(isDesktop: false);

      expect(resolver, isNull);
    });

    test('detects platform by default', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(resolveDatabaseDirectoryResolver(), isNotNull);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(resolveDatabaseDirectoryResolver(), isNull);
    });
  });
}
