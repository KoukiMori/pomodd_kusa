// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CycleSprout';

  @override
  String get sessionCompleted => 'Session completed';

  @override
  String get sessionCompletedMessage => 'Great job! All cycles are completed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get complete => 'Complete';

  @override
  String get timerStopConfirmation => 'Stop the timer?';

  @override
  String get timerStopMessage =>
      'Stop the current timer and end the session.\nSession completion does not contribute to evaluation.';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get changeSettingsConfirmation => 'Change settings?';

  @override
  String get changeSettingsMessage =>
      'Changing settings will reset the current timer and start with new settings.';

  @override
  String get change => 'Change';

  @override
  String get workTime => 'Work Time';

  @override
  String get restTime => 'Rest Time';

  @override
  String get totalWorkTime => 'Total Work Time';

  @override
  String get totalRestTime => 'Total Rest Time';

  @override
  String get totalPercent => 'Total%';

  @override
  String get workPhase => 'Work';

  @override
  String get restPhase => 'Rest';

  @override
  String get presetListTitle => 'Preset List';

  @override
  String get workTimeHeader => 'Work Time';

  @override
  String get restTimeHeader => 'Rest Time';

  @override
  String get cycleTotalHeader => 'Cycle Total';

  @override
  String get breaksPerHourHeader => 'Breaks per Hour';

  @override
  String get evaluationGuideTitle =>
      'How to read the evaluation (about this table)';

  @override
  String get evaluationGuide1 =>
      'This table is based on the balance between work time and break time. (Example: 25 minutes work + 5 minutes break is \"standard\".)';

  @override
  String get evaluationGuide2 =>
      'The standard 25 minutes work + 5 minutes break is reflected as evaluation 3, and other time settings have different evaluations based on the balance between work and break.';

  @override
  String get evaluationFormula =>
      'Formula: 60 ÷ (work minutes + break minutes) ≈ number of breaks per hour';

  @override
  String get contributionMapGuide =>
      'In the contribution map, the degree of achievement is displayed as a \"achievement evaluation\" in a heat map.';

  @override
  String get achievementEvaluationGuide =>
      'Achievement evaluation is determined by the combination of the standard evaluation of the selected setting itself (balance evaluation calculated internally) and the degree of achievement against the set target cycle count (completed work/rest time).';

  @override
  String get achievementExample =>
      '(Example: If 2 cycles are completed out of 4 cycles set, the achievement rate is 50%, which is reflected in the \"achievement evaluation\" for that day.)';

  @override
  String get applyPresetConfirmation => 'Apply this setting?';

  @override
  String get contributionReflectionNote =>
      'It will be reflected in the contribution map as an achievement evaluation.';

  @override
  String get cyclesLabel => 'Cycles';

  @override
  String get executeButton => 'Execute';

  @override
  String get minutesUnit => 'min';

  @override
  String get approximately => 'approx.';

  @override
  String get timesUnit => 'times';
}
