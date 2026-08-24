import 'package:decima/config/dependencies.dart';
import 'package:decima/ui/calculator/calculator_page.dart';
import 'package:decima/ui/calculator/calculator_view_model.dart';
import 'package:decima/ui/history/history_page.dart';
import 'package:decima/ui/history/history_view_model.dart';
import 'package:decima/ui/settings/settings_page.dart';
import 'package:decima/ui/settings/settings_view_model.dart';
import 'package:flutter/material.dart';

/// Configuração centralizada de rotas do app.
class AppRoutes {
  AppRoutes._();

  static const String calculator = '/';
  static const String history = '/history';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    calculator: (_) => CalculatorPage(viewModel: getIt<CalculatorViewModel>()),
    history: (_) => HistoryPage(viewModel: getIt<HistoryViewModel>()),
    settings: (_) => SettingsPage(viewModel: getIt<SettingsViewModel>()),
  };
}
