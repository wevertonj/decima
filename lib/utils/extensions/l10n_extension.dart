import 'package:flutter/widgets.dart';

import 'package:decima/utils/l10n/app_localizations.dart';

/// Extension para acesso simplificado ao AppLocalizations via context.
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
