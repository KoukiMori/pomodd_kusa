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
      'This table is a reference for time balance. The contribution color actually uses the day\'s achievement (total%).';

  @override
  String get evaluationGuide2 =>
      'Achievement% = (work+rest actual seconds) ÷ (daily goal seconds). Goal seconds = (work+rest minutes)×60×cycles.';

  @override
  String get evaluationFormula =>
      'Achievement% = actual seconds ÷ goal seconds × 100';

  @override
  String get contributionMapGuide =>
      'The heatmap color maps total% to a 0–5 scale (0=empty).';

  @override
  String get achievementEvaluationGuide =>
      '5-level thresholds: 0%=0, (0,20)%=1, [20,40)%=2, [40,60)%=3, [60,80)%=4, [80,100]%=5.';

  @override
  String get achievementExample =>
      'Example: With a 4-cycle goal and 50% actual, the day\'s rating becomes 3.';

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
