import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:decima/utils/platform_info.dart';

/// Resolve a [DatabaseFactory] adequada à plataforma.
///
/// O plugin `sqflite` só tem implementação nativa em Android/iOS/macOS —
/// em desktop (Windows/Linux) o banco usa `sqflite_common_ffi`, que
/// embute o SQLite via FFI (mesmo mecanismo usado nos testes).
DatabaseFactory resolveDatabaseFactory({bool? isDesktop}) {
  if (isDesktop ?? PlatformInfo.isDesktop) {
    sqfliteFfiInit();

    return databaseFactoryFfi;
  }

  return databaseFactorySqflitePlugin;
}

/// Resolve o diretório do banco por plataforma.
///
/// Em desktop, o FFI resolveria paths relativos contra o CWD do processo
/// (que varia conforme o atalho/terminal que lançou o app) — usa-se o
/// diretório de suporte por usuário (ex: `%APPDATA%\Wevasoft\Decima`
/// no Windows). Em mobile retorna null: o sqflite já usa o diretório de
/// databases do próprio app.
Future<String> Function()? resolveDatabaseDirectoryResolver({bool? isDesktop}) {
  if (isDesktop ?? PlatformInfo.isDesktop) {
    return () async => (await getApplicationSupportDirectory()).path;
  }

  return null;
}
