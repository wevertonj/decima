import 'package:decima/config/dependencies.dart';
import 'package:decima/config/routes.dart';
import 'package:decima/config/theme/app_colors.dart';
import 'package:decima/config/theme/app_theme.dart';
import 'package:decima/data/database/app_database.dart';
import 'package:decima/data/repositories/settings_repository.dart';
import 'package:decima/domain/entities/window_position.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:decima/ui/core/desktop/desktop_window_initializer.dart';
import 'package:decima/ui/core/desktop/window_close_handler.dart';
import 'package:decima/ui/core/desktop/window_position_validator.dart';
import 'package:decima/ui/core/mobile/app_lifecycle_flush_handler.dart';
import 'package:decima/ui/core/widgets/desktop_shell.dart';
import 'package:decima/ui/settings/settings_view_model.dart';
import 'package:decima/utils/l10n/app_localizations.dart';
import 'package:decima/utils/platform_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Antes da janela: `initDesktopWindow` lê a última posição pelo
  // `SettingsRepository`. Registrar dependências não tem efeito colateral.
  setupDependencies();
  if (DesktopShell.isDesktop) {
    await initDesktopWindow(settingsRepository: getIt<SettingsRepository>());
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  await getIt<AppDatabase>().initialize();
  await getIt<SettingsViewModel>().loadSettings();
  runApp(const DecimaApp());
}

class DecimaApp extends StatefulWidget {
  const DecimaApp({super.key});

  @override
  State<DecimaApp> createState() => _DecimaAppState();
}

class _DecimaAppState extends State<DecimaApp> with WidgetsBindingObserver {
  late final SettingsViewModel _settingsVM;
  late final CalculatorViewModel _calculatorVM;
  late final SettingsRepository _settingsRepository;

  @override
  void initState() {
    super.initState();
    _settingsVM = getIt<SettingsViewModel>();
    _settingsVM.addListener(_onSettingsChanged);
    _calculatorVM = getIt<CalculatorViewModel>();
    _settingsRepository = getIt<SettingsRepository>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsVM.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  Future<void> _flushSession() => _calculatorVM.flushSession();

  /// Gravada no fechamento (e não a cada `onWindowMoved`) para poupar I/O —
  /// ver "Memória da posição da janela" em `docs/fundacao/arquitetura.md`.
  ///
  /// Posição que o gerenciador de janelas não sabe informar é descartada:
  /// gravá-la reabriria a janela num canto em vez de centralizada.
  Future<void> _saveWindowPosition(double x, double y) async {
    final position = WindowPosition(x: x, y: y);
    if (!isWindowPositionStorable(
      position: position,
      isLinux: PlatformInfo.isLinux,
    )) {
      return;
    }

    await _settingsRepository.setWindowPosition(x, y);
  }

  @override
  void didChangePlatformBrightness() {
    _settingsVM.syncNativeNightMode();
  }

  ThemeMode _resolveThemeMode() {
    switch (_settingsVM.themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  Locale? _resolveLocale() {
    final locale = _settingsVM.locale;
    if (locale == null) return null;

    return Locale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = AppColors.seedColors[_settingsVM.seedColorIndex];

    return MaterialApp(
      title: 'Decima',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      themeMode: _resolveThemeMode(),
      locale: _resolveLocale(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.calculator,
      builder: (context, child) {
        return WindowCloseHandler(
          onFlush: _flushSession,
          onSavePosition: _saveWindowPosition,
          child: AppLifecycleFlushHandler(
            onFlush: _flushSession,
            child: DesktopShell(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
