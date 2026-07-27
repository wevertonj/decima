import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Decima'**
  String get appTitle;

  /// Calculator screen title
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculator;

  /// History screen title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Load more button in timeline
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// Clear button label
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get clear;

  /// Backspace button accessibility label
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get backspace;

  /// Equals button label
  ///
  /// In en, this message translates to:
  /// **'='**
  String get equals;

  /// Percent button label
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get percent;

  /// Accessibility label for the contextual C (clear all) button
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// Accessibility label for the parenthesis toggle button
  ///
  /// In en, this message translates to:
  /// **'Parenthesis'**
  String get parenthesis;

  /// Tab label for all history entries
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allEntries;

  /// Tab label for favorite entries only
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Empty state message when there are no history entries
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistory;

  /// Empty state message when there are no favorite entries
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// Action to clear all history entries
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// Confirmation message before clearing history
  ///
  /// In en, this message translates to:
  /// **'Delete all history entries? This action cannot be undone.'**
  String get clearHistoryConfirm;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Rename action label
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Save button in rename dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get renameSave;

  /// Hint text for the rename input field
  ///
  /// In en, this message translates to:
  /// **'Entry name'**
  String get renameHint;

  /// Settings section title for theme mode
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Settings section title for accent color
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Settings section title for number format
  ///
  /// In en, this message translates to:
  /// **'Number format'**
  String get numberFormat;

  /// Settings section title for language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Portuguese language option
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// System language option (follow device setting)
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Context menu option to copy the current expression
  ///
  /// In en, this message translates to:
  /// **'Copy calculation'**
  String get copyExpression;

  /// Context menu option to copy the current result
  ///
  /// In en, this message translates to:
  /// **'Copy result'**
  String get copyResult;

  /// Context menu option to copy all session timeline entries
  ///
  /// In en, this message translates to:
  /// **'Copy history'**
  String get copyHistory;

  /// Context menu option to paste from the system clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Snackbar message shown when pasted clipboard text is not a valid number or expression
  ///
  /// In en, this message translates to:
  /// **'Invalid clipboard content'**
  String get pasteInvalid;

  /// Snackbar message confirming a successful copy
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
