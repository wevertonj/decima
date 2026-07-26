import 'package:get_it/get_it.dart';

import 'package:wevacalc/data/database/app_database.dart';
import 'package:wevacalc/data/repositories/history_repository.dart';
import 'package:wevacalc/data/repositories/history_repository_impl.dart';
import 'package:wevacalc/data/repositories/settings_repository.dart';
import 'package:wevacalc/data/repositories/settings_repository_impl.dart';
import 'package:wevacalc/data/services/clipboard_service.dart';
import 'package:wevacalc/data/services/clipboard_service_impl.dart';
import 'package:wevacalc/data/services/night_mode_service.dart';
import 'package:wevacalc/data/services/night_mode_service_impl.dart';
import 'package:wevacalc/ui/calculator/calculator_view_model.dart';
import 'package:wevacalc/ui/history/history_view_model.dart';
import 'package:wevacalc/ui/settings/settings_view_model.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

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
