import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:decima/config/dependencies.dart';
import 'package:decima/config/routes.dart';
import 'package:decima/data/database/app_database.dart';
import 'package:decima/config/theme/app_colors.dart';
import 'package:decima/config/theme/app_theme.dart';
import 'package:decima/domain/enums/theme_mode_option.dart';
import 'package:decima/ui/core/desktop/desktop_window_initializer.dart';
import 'package:decima/ui/core/widgets/desktop_shell.dart';
import 'package:decima/ui/settings/settings_view_model.dart';
import 'package:decima/utils/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (DesktopShell.isDesktop) {
    await initDesktopWindow();
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  setupDependencies();
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

  @override
  void initState() {
    super.initState();
    _settingsVM = getIt<SettingsViewModel>();
    _settingsVM.addListener(_onSettingsChanged);
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
        return DesktopShell(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
