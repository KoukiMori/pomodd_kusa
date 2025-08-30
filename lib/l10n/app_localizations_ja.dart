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
      'この表は時間バランスの参考です。実際のコントリビューション色は、その日の達成率（total%）で決まります。';

  @override
  String get evaluationGuide2 =>
      '達成率 = （作業＋休憩の実績合計秒）÷（目標合計秒）。目標合計秒 = （作業分＋休憩分）×60×サイクル数。';

  @override
  String get evaluationFormula => '達成率(%) = 実績秒 ÷ 目標秒 × 100';

  @override
  String get contributionMapGuide => 'ヒートマップの色は total% に対応して0〜5段階で表示します（0=空）。';

  @override
  String get achievementEvaluationGuide =>
      '5段階の目安: 0%=0, (0,20)%=1, [20,40)%=2, [40,60)%=3, [60,80)%=4, [80,100]%=5。';

  @override
  String get achievementExample => '例: 4サイクル目標で実績が50%なら、その日の評価は3になります。';

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
