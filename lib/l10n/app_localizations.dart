import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CycleSprout'**
  String get appTitle;

  /// No description provided for @sessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Session completed'**
  String get sessionCompleted;

  /// No description provided for @sessionCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Great job! All cycles are completed.'**
  String get sessionCompletedMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @timerStopConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Stop the timer?'**
  String get timerStopConfirmation;

  /// No description provided for @timerStopMessage.
  ///
  /// In en, this message translates to:
  /// **'Stop the current timer and end the session.\nSession completion does not contribute to evaluation.'**
  String get timerStopMessage;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @changeSettingsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Change settings?'**
  String get changeSettingsConfirmation;

  /// No description provided for @changeSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Changing settings will reset the current timer and start with new settings.'**
  String get changeSettingsMessage;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @workTime.
  ///
  /// In en, this message translates to:
  /// **'Work Time'**
  String get workTime;

  /// No description provided for @restTime.
  ///
  /// In en, this message translates to:
  /// **'Rest Time'**
  String get restTime;

  /// No description provided for @totalWorkTime.
  ///
  /// In en, this message translates to:
  /// **'Total Work Time'**
  String get totalWorkTime;

  /// No description provided for @totalRestTime.
  ///
  /// In en, this message translates to:
  /// **'Total Rest Time'**
  String get totalRestTime;

  /// No description provided for @totalPercent.
  ///
  /// In en, this message translates to:
  /// **'Total%'**
  String get totalPercent;

  /// No description provided for @workPhase.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workPhase;

  /// No description provided for @restPhase.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restPhase;

  /// No description provided for @presetListTitle.
  ///
  /// In en, this message translates to:
  /// **'Preset List'**
  String get presetListTitle;

  /// No description provided for @workTimeHeader.
  ///
  /// In en, this message translates to:
  /// **'Work Time'**
  String get workTimeHeader;

  /// No description provided for @restTimeHeader.
  ///
  /// In en, this message translates to:
  /// **'Rest Time'**
  String get restTimeHeader;

  /// No description provided for @cycleTotalHeader.
  ///
  /// In en, this message translates to:
  /// **'Cycle Total'**
  String get cycleTotalHeader;

  /// No description provided for @breaksPerHourHeader.
  ///
  /// In en, this message translates to:
  /// **'Breaks per Hour'**
  String get breaksPerHourHeader;

  /// No description provided for @evaluationGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to read the evaluation (about this table)'**
  String get evaluationGuideTitle;

  /// No description provided for @evaluationGuide1.
  ///
  /// In en, this message translates to:
  /// **'This table is based on the balance between work time and break time. (Example: 25 minutes work + 5 minutes break is \"standard\".)'**
  String get evaluationGuide1;

  /// No description provided for @evaluationGuide2.
  ///
  /// In en, this message translates to:
  /// **'The standard 25 minutes work + 5 minutes break is reflected as evaluation 3, and other time settings have different evaluations based on the balance between work and break.'**
  String get evaluationGuide2;

  /// No description provided for @evaluationFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula: 60 ÷ (work minutes + break minutes) ≈ number of breaks per hour'**
  String get evaluationFormula;

  /// No description provided for @contributionMapGuide.
  ///
  /// In en, this message translates to:
  /// **'In the contribution map, the degree of achievement is displayed as a \"achievement evaluation\" in a heat map.'**
  String get contributionMapGuide;

  /// No description provided for @achievementEvaluationGuide.
  ///
  /// In en, this message translates to:
  /// **'Achievement evaluation is determined by the combination of the standard evaluation of the selected setting itself (balance evaluation calculated internally) and the degree of achievement against the set target cycle count (completed work/rest time).'**
  String get achievementEvaluationGuide;

  /// No description provided for @achievementExample.
  ///
  /// In en, this message translates to:
  /// **'(Example: If 2 cycles are completed out of 4 cycles set, the achievement rate is 50%, which is reflected in the \"achievement evaluation\" for that day.)'**
  String get achievementExample;

  /// No description provided for @applyPresetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Apply this setting?'**
  String get applyPresetConfirmation;

  /// No description provided for @contributionReflectionNote.
  ///
  /// In en, this message translates to:
  /// **'It will be reflected in the contribution map as an achievement evaluation.'**
  String get contributionReflectionNote;

  /// No description provided for @cyclesLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get cyclesLabel;

  /// No description provided for @executeButton.
  ///
  /// In en, this message translates to:
  /// **'Execute'**
  String get executeButton;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesUnit;

  /// No description provided for @approximately.
  ///
  /// In en, this message translates to:
  /// **'approx.'**
  String get approximately;

  /// No description provided for @timesUnit.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get timesUnit;
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
