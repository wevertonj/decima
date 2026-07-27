import 'package:get_it/get_it.dart';

import 'package:decima/data/database/app_database.dart';
import 'package:decima/data/database/database_factory_resolver.dart';
import 'package:decima/data/repositories/history_repository.dart';
import 'package:decima/data/repositories/history_repository_impl.dart';
import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/data/repositories/settings_repository_impl.dart';
import 'package:decima/data/services/clipboard_service.dart';
import 'package:decima/data/services/clipboard_service_impl.dart';
import 'package:decima/data/services/night_mode_service.dart';
import 'package:decima/data/services/night_mode_service_impl.dart';
import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:decima/ui/history/history_view_model.dart';
import 'package:decima/ui/settings/settings_view_model.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Database — em desktop usa SQLite via FFI (sqflite não suporta
  // Windows/Linux) com path absoluto por usuário; em mobile usa o
  // plugin nativo com o diretório padrão do app
  getIt.registerLazySingleton<AppDatabase>(
    () => AppDatabase(
      databaseFactory: resolveDatabaseFactory(),
      directoryResolver: resolveDatabaseDirectoryResolver(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(),
  );

  // Services
  getIt.registerLazySingleton<ClipboardService>(() => ClipboardServiceImpl());
  getIt.registerLazySingleton<NightModeService>(() => NightModeServiceImpl());

  // ViewModels
  getIt.registerLazySingleton<CalculatorViewModel>(
    () => CalculatorViewModel(
      historyRepository: getIt<HistoryRepository>(),
      settingsRepository: getIt<SettingsRepository>(),
      clipboardService: getIt<ClipboardService>(),
    ),
  );
  getIt.registerFactory<HistoryViewModel>(
    () => HistoryViewModel(historyRepository: getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<SettingsViewModel>(
    () => SettingsViewModel(
      settingsRepository: getIt<SettingsRepository>(),
      nightModeService: getIt<NightModeService>(),
    ),
  );
}
