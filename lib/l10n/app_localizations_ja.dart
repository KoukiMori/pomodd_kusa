// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ポモドの草';

  @override
  String get sessionCompleted => 'セッション完了';

  @override
  String get sessionCompletedMessage => 'おつかれさまです！全てのサイクルが完了しました。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get complete => '完了';

  @override
  String get timerStopConfirmation => 'タイマーを停止しますか？';

  @override
  String get timerStopMessage =>
      '現在のタイマーを停止し\nセッションを終了します。\nセッション完了ではないため\nコントリビューションには反映しません。';

  @override
  String get no => 'いいえ';

  @override
  String get yes => 'はい';

  @override
  String get changeSettingsConfirmation => '設定を変更しますか？';

  @override
  String get changeSettingsMessage => '変更すると現在のタイマーはリセットされ、新しい設定で開始します。';

  @override
  String get change => '変更';

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
  String get presetListTitle => 'プリセットリスト';

  @override
  String get workTimeHeader => '作業時間';

  @override
  String get restTimeHeader => '休憩時間';

  @override
  String get cycleTotalHeader => '1サイクル合計';

  @override
  String get breaksPerHourHeader => '1時間あたりの\n休憩回数';

  @override
  String get evaluationGuideTitle => '評価の見方（この表について）';

  @override
  String get evaluationGuide1 =>
      'この表は「作業時間と休憩時間のバランス」に基づいています。（例：25分作業+5分休憩が「標準」です。）';

  @override
  String get evaluationGuide2 =>
      '標準の25分作業＋5分休憩は評価3として反映され、それ以外の時間設定は作業と休憩のバランスにより評価が変わります。';

  @override
  String get evaluationFormula => '計算式: 60 ÷ (作業分 + 休憩分) ≒ 1時間あたりの休憩回数';

  @override
  String get contributionMapGuide =>
      'コントリビューションマップでは達成度合いを「達成評価」としてヒートマップで表示します。';

  @override
  String get achievementEvaluationGuide =>
      '達成評価は、選択した設定自体の基準評価（内部的に計算されるバランス評価）と、設定した目標サイクル数に対する実際の達成度合い（完了した作業・休憩時間）の組み合わせで決定されます。';

  @override
  String get achievementExample =>
      '（例: 設定4サイクルに対し2サイクル完了した場合、達成度は50%となり、その日の「達成評価」に反映されます。）';

  @override
  String get applyPresetConfirmation => 'この設定を適用しますか？';

  @override
  String get contributionReflectionNote => 'コントリビューションマップに達成評価として反映されます。';

  @override
  String get cyclesLabel => 'サイクル数';

  @override
  String get executeButton => '実行';

  @override
  String get minutesUnit => '分';

  @override
  String get approximately => '約';

  @override
  String get timesUnit => '回';
}
