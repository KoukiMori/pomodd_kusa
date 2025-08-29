import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode用
import 'package:pomodgrass/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pomodgrass/color_style.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io' show Platform; // プラットフォーム判定用
import 'package:flutter/services.dart';
import 'package:pomodgrass/contribution_section.dart';
import 'package:pomodgrass/data_helper.dart';
import 'package:pomodgrass/preset_settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  // TestFlightでのデバッグ機能制御フラグ（App Store本リリース時は false に変更）
  static const bool _enableDebugInTestFlight = true;

  // デバッグ機能が有効かどうかを判定
  bool get _isDebugEnabled => kDebugMode || _enableDebugInTestFlight;

  // 設定値（状態）
  // デバッグ有効時は時間を短く設定
  int workTime = 25; // デフォルト値
  int restTime = 5; // デフォルト値
  int resp = 5; // デフォルト値

  // 設定の保存/読み込み（DataHelper に委譲）
  Future<void> _saveSettings() async {
    await DataHelper.saveUserSettings(
      UserSettings(workTime: workTime, restTime: restTime, resp: resp),
    );
  }

  Future<void> _loadSettings() async {
    // デバッグ有効時はデフォルト値を短時間に設定
    final int defaultWork = _isDebugEnabled ? 1 : 25;
    final int defaultRest = _isDebugEnabled ? 1 : 5;
    final int defaultResp = _isDebugEnabled ? 2 : 5;

    final UserSettings s = await DataHelper.loadUserSettings(
      defaultWork: defaultWork,
      defaultRest: defaultRest,
      defaultResp: defaultResp,
    );
    if (!mounted) return;
    setState(() {
      workTime = s.workTime;
      restTime = s.restTime;
      resp = s.resp;
    });
  }

  // タイマー/アニメーション用の状態
  late final AnimationController _animationController; // 0.0→1.0で進行
  double _progress = 0.0; // 円弧の進捗 (0.0〜1.0)
  bool _isRunning = false; // 再生中かどうか
  bool _isWorkPhase = true; // true=Work, false=Rest
  int _currentCycle = 0; // 0始まり、resp回実行
  Timer? _blinkTimer; // 1秒ごとの点滅用
  bool _blinkOn = true; // true: 表示, false: 非表示
  bool _isPaused = false; // 一時停止中かどうか
  bool _previewLegend = false; // コントリビューション配色プレビュー
  bool _hasStartedSession = false; // セッション開始フラグ（一度でもプレイボタンを押したら true）
  int _contributionUpdateKey = 0; // コントリビューションセクション更新用キー
  bool _sessionCompletedPendingConfirm = false; // セッション完了後、完了ボタン待ちの状態

  // 全体残り割合（全Work+Rest×respを100%として減少）
  int _computeTotalRemainingPercent() {
    final int totalSeconds = ((workTime + restTime) * resp) * 60;
    if (totalSeconds <= 0) return 0;

    // 完了済サイクルの経過秒
    int elapsedSeconds = _currentCycle * (workTime + restTime) * 60;

    // セッション完了時は100%経過として扱う
    if (_currentCycle >= resp) {
      elapsedSeconds = totalSeconds;
    } else {
      // 現在サイクルの経過秒
      if (_isWorkPhase) {
        elapsedSeconds += (_progress * workTime * 60).round();
      } else {
        elapsedSeconds += (workTime * 60) + (_progress * restTime * 60).round();
      }
    }

    final double remainingPercent =
        100.0 * (1.0 - (elapsedSeconds / totalSeconds));
    return remainingPercent.clamp(0.0, 100.0).round();
  }

  // 残りサイクル数（Rest完了ごとに1減少）。最小0
  int get _remainingCycles => (resp - _currentCycle).clamp(0, resp);

  // セッション完了ダイアログ
  Future<void> _showCompletionDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            AppLocalizations.of(context)!.sessionCompleted,
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          content: Text(
            AppLocalizations.of(context)!.sessionCompletedMessage,
            style: GoogleFonts.roboto(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // キャンセル時は完了確認状態をリセット（データ保存しない）
                setState(() {
                  _sessionCompletedPendingConfirm = false;
                });
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                // 完了ボタン押下時にデータを保存（ここで初めて評価色に反映）
                if (_sessionCompletedPendingConfirm) {
                  // 1セッション（Work+Rest）完了を貢献として記録
                  unawaited(
                    DataHelper.addContribution(DateTime.now(), delta: 1),
                  );

                  // 初回セッション完了時に起点日を記録
                  _recordFirstPlayIfNeeded();
                }

                // 完了: 状態を初期化
                setState(() {
                  _isRunning = false;
                  _isPaused = false;
                  _progress = 0.0;
                  _currentCycle = 0;
                  _isWorkPhase = true;
                  _hasStartedSession = false; // セッション終了時にフラグリセット
                  _sessionCompletedPendingConfirm = false; // 完了確認状態をリセット
                });
                Navigator.of(context).pop();
                // 完了ボタン押下時にコントリビューションセクションを更新
                // 当日のセルが評価色に変わるようにUIを更新
                setState(() {
                  _contributionUpdateKey++; // キーを変更して強制的に再構築
                });
              },
              child: Text(AppLocalizations.of(context)!.complete),
            ),
          ],
        );
      },
    );
  }

  // フェーズ切り替え音（iOSの標準通知音とバイブレーション）
  void _playPhaseChangeSound() {
    if (Platform.isIOS) {
      SystemSound.play(SystemSoundType.alert);
      Future.delayed(const Duration(milliseconds: 200), () {
        SystemSound.play(SystemSoundType.click);
      });
    } else {
      SystemSound.play(SystemSoundType.click);
      SystemSound.play(SystemSoundType.alert);
    }

    HapticFeedback.lightImpact();
    HapticFeedback.selectionClick();

    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });

    if (Platform.isIOS) {
      Future.delayed(const Duration(milliseconds: 300), () {
        HapticFeedback.vibrate();
      });
    }
  }

  // 設定変更の確認ダイアログ（実行中/一時停止中にタップされた場合）
  Future<bool> _showChangeConfirmDialog() async {
    if (!mounted) return false;
    final bool? shouldChange = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            AppLocalizations.of(context)!.changeSettingsConfirmation,
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          content: Text(
            AppLocalizations.of(context)!.changeSettingsMessage,
            style: GoogleFonts.roboto(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.change),
            ),
          ],
        );
      },
    );
    return shouldChange ?? false;
  }

  // タイマーを停止して進捗をリセット
  void _stopAndResetTimer() {
    _animationController.stop();
    _animationController.reset();
    // 途中停止時に、その時点までの経過を実績へ加算
    final int addWork = _isWorkPhase ? (_progress * workTime * 60).round() : 0;
    final int addRest = !_isWorkPhase ? (_progress * restTime * 60).round() : 0;
    if (addWork > 0 || addRest > 0) {
      // ignore: discarded_futures
      DataHelper.addDailyActual(
        DateTime.now(),
        workSecDelta: addWork,
        restSecDelta: addRest,
        workTimeSetting: workTime,
        restTimeSetting: restTime,
        respSetting: resp,
      );
    }
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _progress = 0.0;
      // フェーズ（Work/Rest）とサイクル数は維持
    });
  }

  // ピッカーを開き、閉じたら新設定で現在フェーズを再スタート
  Future<void> _openPickerAndRestart(Size screenSize) async {
    await _showTimeSettingsPicker(screenSize);
    // 設定変更は新セッションとして扱い、Total%を100%から減らすため
    // サイクルとフェーズを初期状態に戻して開始
    setState(() {
      _currentCycle = 0;
      _isWorkPhase = true; // Workから再スタート
      _progress = 0.0;
    });
    _startCurrentPhase();
  }

  // 設定項目タップ時の共通ハンドラ
  Future<void> _onTapSettings(Size screenSize) async {
    // 実行中/一時停止中は確認、停止中はそのままピッカー
    if (_isRunning || _isPaused) {
      final bool ok = await _showChangeConfirmDialog();
      if (!ok) return; // キャンセル
      _stopAndResetTimer();
      await _openPickerAndRestart(screenSize);
    } else {
      await _showTimeSettingsPicker(screenSize);
      // 停止中は自動開始しない（現状の挙動を維持）
    }
  }

  // 現在フェーズ（Work/Rest）の合計秒数
  int get _phaseSeconds => (_isWorkPhase ? workTime : restTime) * 60;

  // Work/Rest/Resp の3列ピッカーを表示
  Future<void> _showTimeSettingsPicker(Size screenSize) async {
    // 一時選択値（閉じるまでローカルに保持）
    int tempWork = workTime;
    int tempRest = restTime;
    int tempResp = resp;

    // モーダルが閉じられる（外タップ）まで待機し、閉じた時点で選択値を確定する
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        // 指定件数の 1..N を生成（ピッカー用）
        List<Widget> numberItems(int count) =>
            List.generate(count, (i) => Center(child: Text('${i + 1}')));

        return CupertinoPopupSurface(
          isSurfacePainted: true,
          child: Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            height: screenSize.height * .36,
            width: screenSize.width,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: screenSize.height * .02),
                // タイトル行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Work',
                      style: GoogleFonts.roboto(
                        fontSize: screenSize.height * .025,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      'Rest',
                      style: GoogleFonts.roboto(
                        fontSize: screenSize.height * .025,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      'Resp',
                      style: GoogleFonts.roboto(
                        fontSize: screenSize.height * .025,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                // 3列のピッカー
                SizedBox(
                  height: 220,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            // 5分刻み(5..60)の0始まりインデックス
                            initialItem: ((workTime - 1) ~/ 5).clamp(
                              0,
                              11,
                            ), // 0..11
                          ),
                          onSelectedItemChanged: (index) =>
                              tempWork = (index + 1) * 5, // 5,10,..,60
                          // 5分刻みの表示アイテム
                          children: List.generate(
                            12,
                            (i) => Center(child: Text('${(i + 1) * 5}')),
                          ), // Work: 5..60 (5分刻み)
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: (restTime - 1).clamp(
                              0,
                              9,
                            ), // 1..10 → 0..9
                          ),
                          onSelectedItemChanged: (index) =>
                              tempRest = index + 1,
                          children: numberItems(10), // Rest: 1..10
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: (resp - 1).clamp(0, 9), // 1..10 → 0..9
                          ),
                          onSelectedItemChanged: (index) =>
                              tempResp = index + 1,
                          children: numberItems(10), // Resp: 1..10
                        ),
                      ),
                    ],
                  ),
                ),
                // Done ボタンは無し。外側タップで閉じる
              ],
            ),
          ),
        );
      },
    );
    // モーダルが閉じられたので、最新の選択値を反映
    setState(() {
      workTime = tempWork.clamp(5, 60); // 5..60（5刻み）
      restTime = tempRest.clamp(1, 10);
      resp = tempResp.clamp(1, 10);
    });
    // 設定変更を保存（次回起動時も反映される）
    unawaited(_saveSettings());
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
            vsync: this,
            duration: Duration(seconds: _phaseSeconds),
          )
          ..addListener(() {
            // アニメーションの進行に合わせて円弧の割合を更新
            setState(() {
              _progress = _animationController.value;
            });
          })
          ..addStatusListener((status) {
            // 1フェーズ完了時の遷移（Work→Rest→次のWork...）
            if (status == AnimationStatus.completed) {
              _handlePhaseComplete();
            }
          });

    // 1秒ごとに点滅状態をトグル（実行中のみ反映）
    _blinkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) return;
      setState(() {
        _blinkOn = !_blinkOn;
      });
    });

    // 起動時にユーザー設定を読み込む（保存済みなら UI に反映）
    // 非同期だが、読み込み後に setState で即座に表示を更新する。
    // タイマーの実行処理は _startCurrentPhase() 側で duration を都度設定するため影響なし。
    // ignore: discarded_futures
    _loadSettings();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // 現在のフェーズ（Work/Rest）の長さでアニメーション開始（時計回りで0→1）
  void _startCurrentPhase() {
    _animationController.duration = Duration(seconds: _phaseSeconds);
    _animationController.reset();
    // フェーズ開始時に進捗を明示的に0へ（インジケータは満タンから減少）
    _progress = 0.0;
    _animationController.forward();
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
  }

  // フェーズ完了時のハンドリング
  void _handlePhaseComplete() {
    if (_isWorkPhase) {
      // Workが終わったらRestへ
      _playPhaseChangeSound();
      // 実績に作業分を加算
      // ignore: discarded_futures
      DataHelper.addDailyActual(
        DateTime.now(),
        workSecDelta: workTime * 60,
        workTimeSetting: workTime,
        restTimeSetting: restTime,
        respSetting: resp,
      );
      _isWorkPhase = false;
      _startCurrentPhase();
    } else {
      // Restが終わったら次サイクルへ
      // 実績に休憩分を加算
      // ignore: discarded_futures
      DataHelper.addDailyActual(DateTime.now(), restSecDelta: restTime * 60);
      _currentCycle += 1;
      if (_currentCycle < resp) {
        // Rest→Work への切り替えでもクリック音を鳴らす
        _playPhaseChangeSound();
        _isWorkPhase = true;
        _startCurrentPhase();
      } else {
        // すべてのサイクル完了
        setState(() {
          _isRunning = false;
          _isPaused = false;
          _progress = 1.0;
          _sessionCompletedPendingConfirm = true; // 完了ボタン待ち状態に設定
        });

        // セッション完了時に音とバイブレーションで通知
        _playPhaseChangeSound();

        // ダイアログで完了通知（データ保存は完了ボタンで実行）
        _showCompletionDialog();
      }
    }
  }

  // 一時停止
  void _pause() {
    _animationController.stop();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  // 再開（現在の進捗から継続）
  void _resume() {
    _animationController.forward();
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
  }

  // 再生/一時停止ボタン押下時の挙動
  void _onPressPlay() {
    if (_isRunning) {
      // 実行中 → 一時停止
      _pause();
      return;
    }

    if (_isPaused) {
      // 一時停止中 → 再開
      _resume();
      return;
    }

    // 停止中（未開始/完了） → 最初から開始
    setState(() {
      _hasStartedSession = true; // セッション開始フラグを立てる
      _currentCycle = 0;
      _isWorkPhase = true;
      _progress = 0.0;
    });
    _startCurrentPhase();
  }

  // 初回プレイ日の記録（まだ設定されていない場合のみ）
  void _recordFirstPlayIfNeeded() {
    // 非同期だが UI ブロックは不要のため unawaited で実行
    unawaited(() async {
      final DateTime? existing = await DataHelper.loadFirstPlayDate();
      if (existing == null) {
        await DataHelper.saveFirstPlayDate(DateTime.now());
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true, // タイトルを常に中央に配置
        leading:
            _isDebugEnabled // デバッグ機能有効時にプレビューボタンを表示
            ? IconButton(
                onPressed: () {
                  setState(() => _previewLegend = !_previewLegend);
                },
                icon: Icon(
                  _previewLegend ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                tooltip: 'Legend Preview',
              )
            : SizedBox(width: kToolbarHeight), // 右のactionsとバランスを取り真の中央に揃える
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: Localizations.localeOf(context).languageCode == 'ja'
              ? GoogleFonts.mPlus1Code(
                  fontSize: 32,
                  color: ColorStyle.textColor,
                  fontWeight: FontWeight.w300,
                )
              : GoogleFonts.roboto(
                  fontSize: 32,
                  color: ColorStyle.textColor,
                  fontWeight: FontWeight.w300,
                ),
        ),
        toolbarHeight: screenSize.height * .06,
        actions: [
          // タイトルと縦位置がずれないよう微調整（上に数px）
          Row(
            children: [
              // デバッグ機能有効時にテスト用アイコンを表示（プレビューアイコンはleadingに移動）
              if (_isDebugEnabled)
                IconButton(
                  onPressed: () {
                    // タイマーが実行中または一時停止中の場合は停止してリセット
                    if (_isRunning || _isPaused) {
                      _stopAndResetTimer();
                    }
                    setState(() {
                      workTime = 1; // Work Time を1分に設定
                      restTime = 1; // Rest Time を1分に設定
                      resp = 1; // Resp（サイクル数）を1に設定
                      _currentCycle = 0; // サイクルを初期状態にリセット
                      _isWorkPhase = true; // Workフェーズから開始
                      _progress = 0.0; // 進捗をリセット
                    });
                    // 設定を保存し、次回起動時も反映されるようにする
                    unawaited(_saveSettings());
                  },
                  icon: Icon(
                    Icons.bug_report, // テスト用アイコンとして虫のアイコンを使用
                    color: Colors.lightGreenAccent, // 他のアイコンと区別しやすい色
                    size: screenSize.width * .08,
                  ),
                  tooltip: 'Set Test Times (1min/1min/1cycle)', // ツールチップで機能説明
                ),
              // プリセット設定アイコン（リリース版でも使用）
              IconButton(
                onPressed: () async {
                  // プリセット選択画面へ遷移し、結果を受け取って反映
                  final result = await Navigator.of(context)
                      .push<Map<String, int>>(
                        MaterialPageRoute(
                          builder: (_) => const PresetSettingsPage(),
                        ),
                      );
                  if (result != null) {
                    setState(() {
                      workTime = result['work'] ?? workTime;
                      restTime = result['rest'] ?? restTime;
                      // サイクル数も受け取れたら反映
                      if (result.containsKey('resp')) {
                        resp = (result['resp'] ?? resp).clamp(1, 10);
                      }
                    });
                    // 保存して次回起動にも反映
                    // ignore: discarded_futures
                    _saveSettings();
                  }
                },
                icon: Icon(
                  Icons.manage_search,
                  color: Colors.white,
                  size: screenSize.width * .08,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1, // タイマー部分の比重を適度に制限
            child: Stack(
              children: [
                Positioned(
                  left: screenSize.width * .03,
                  child: Opacity(
                    // 実行中のみ1秒ごとの点滅（非実行時は常に表示）
                    opacity: _isRunning ? (_blinkOn ? 1.0 : 0.1) : 1.0,
                    child: Text(
                      _isWorkPhase ? 'Work' : 'Rest',
                      style: GoogleFonts.roboto(
                        fontSize: screenSize.height * .05,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                // セッション開始後に停止アイコンを表示
                if (_hasStartedSession)
                  Positioned(
                    top: screenSize.width * .12,
                    left: screenSize.width * .01,
                    child: IconButton(
                      onPressed: () async {
                        // タイマー実行中または一時停止中のみ停止確認ダイアログを表示
                        if (_isRunning || _isPaused) {
                          final bool? shouldStop = await showDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Colors.black,
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.timerStopConfirmation,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                  ),
                                ),
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.timerStopMessage,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white70,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(
                                      AppLocalizations.of(context)!.no,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      AppLocalizations.of(context)!.yes,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldStop == true) {
                            // 「はい」が選択された場合、タイマーを停止してリセット
                            _stopAndResetTimer();
                            // サイクルとフェーズを初期状態に戻す
                            setState(() {
                              _currentCycle = 0;
                              _isWorkPhase = true;
                              _progress = 0.0;
                            });
                          }
                        }
                      },
                      icon: Icon(
                        Icons.timer_off_outlined,
                        size: screenSize.width * .1,
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                  ),
                Positioned(
                  top: screenSize.width * .1,
                  right: screenSize.width * .02,
                  child: SizedBox(
                    width: screenSize.width,
                    child: _TwoThirdCircularIndicator(
                      // 画面幅に合わせて半径を可変にする（レスポンシブ）
                      radius: screenSize.width / 2.6,
                      // 進捗（0.0〜1.0）
                      // 残り割合として減少表示（1.0→0.0で減る）
                      percent: 1.0 - _progress,
                      // 円弧の太さ
                      lineWidth: 8,
                      // 配色（点滅なしで常に表示）
                      progressColor: Colors.grey,
                      backgroundColor: Colors.white,
                      // 欠ける角度（ここでは 1/3 を欠けさせる = 120度）
                      gapAngle: 2 * math.pi / 7.8,
                      // 開始位置を上方向中心に配置（任意で微調整可能）
                      rotation: -math.pi / 3.4,
                      // 中央テキスト
                      center: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          SizedBox(height: screenSize.height * .02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 20,
                            children: [
                              SettingTimeWidget(
                                onTap: () => _onTapSettings(screenSize),
                                title: 'Work Time',
                                settingTime: workTime,
                                valueFontSize: screenSize.height * .07,
                                description: ' min',
                                screenSize: screenSize,
                              ),
                              SettingTimeWidget(
                                onTap: () => _onTapSettings(screenSize),
                                title: 'Rest Time',
                                settingTime: restTime,
                                valueFontSize: screenSize.height * .07,
                                description: ' min',
                                screenSize: screenSize,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 20,
                            children: [
                              SettingTimeWidget(
                                onTap: () {},
                                title: 'Total Work Time',
                                settingTime: workTime * resp,
                                description: ' min',
                                screenSize: screenSize,
                              ),
                              SettingTimeWidget(
                                onTap: () {},
                                title: 'Total Rest Time',
                                settingTime: restTime * resp,
                                description: ' min',
                                screenSize: screenSize,
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: _onPressPlay,
                            icon: _isRunning
                                ? Icon(
                                    Icons.pause_circle_filled,
                                    size: screenSize.height * .1,
                                    color: Colors.grey,
                                  )
                                : Icon(
                                    Icons.play_circle_fill_outlined,
                                    size: screenSize.height * .1,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: screenSize.width * .02,
                  child: SettingTimeWidget(
                    onTap: () {},
                    title: 'Total%',
                    // 全時間を100%として残り%を表示
                    settingTime: _computeTotalRemainingPercent(),
                    description: '%',
                    screenSize: screenSize,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: screenSize.width * .028,
                  child: SettingTimeWidget(
                    onTap: () {},
                    title: '    Total Time',
                    settingTime: (workTime * resp) + (restTime * resp),
                    description: 'min',
                    screenSize: screenSize,
                  ),
                ),
                Positioned(
                  top: screenSize.width * .08,
                  // 10/10 の位置はそのまま、9以下（1桁）の場合は少し左へ寄せる
                  right: screenSize.width * (.12 + (resp < 10 ? -.03 : -.09)),
                  child: GestureDetector(
                    onTap: () => _onTapSettings(screenSize),
                    child: RichText(
                      text: TextSpan(
                        // 残りサイクル数/合計サイクル数（x2が1減る挙動）
                        text: _remainingCycles.toString(),
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: screenSize.width * .16,
                          letterSpacing: resp < 10 ? 6 : -2,
                        ),
                        children: [
                          TextSpan(
                            text: '/',
                            style: GoogleFonts.roboto(
                              fontSize: screenSize.width * .1,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: resp < 10 ? 6 : 1,
                            ),
                          ),
                          TextSpan(
                            text: resp.toString(),
                            style: GoogleFonts.roboto(
                              fontSize: screenSize.width * .06,
                              letterSpacing: resp < 10 ? 6 : 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1, // コントリビューション部分に適切な比重を設定
            child: ContributionSection(
              key: ValueKey(_contributionUpdateKey), // キーで強制更新
              previewLegend: _previewLegend,
              // 当日は完了ダイアログの完了ボタン押下までオレンジを維持
              forceTodayOrange: _sessionCompletedPendingConfirm,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class SettingTimeWidget extends StatelessWidget {
  VoidCallback onTap;
  final String title;
  final String description;
  final int settingTime;
  final Size screenSize;
  // 任意指定のフォントサイズ（未指定時はデフォルトサイズを使用）
  final double? titleFontSize;
  final double? valueFontSize;
  final double? descriptionFontSize;
  SettingTimeWidget({
    super.key,
    required this.title,
    required this.settingTime,
    required this.description,
    required this.onTap,
    required this.screenSize,
    this.titleFontSize,
    this.valueFontSize,
    this.descriptionFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: titleFontSize ?? screenSize.width * .03,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          RichText(
            text: TextSpan(
              text: settingTime.toString(),
              style: GoogleFonts.roboto(
                fontSize: valueFontSize ?? screenSize.width * .12,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: description,
                  style: GoogleFonts.roboto(
                    fontSize: descriptionFontSize ?? 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 1/3（120度）をカットした円弧インジケータ
// - rotation: キャンバス全体の回転（開始位置の調整用）
// - gapAngle: 欠けている角度（ラジアン）。2πのうち gapAngle 分だけ描画しない
// - percent: 可視領域（2π - gapAngle）の中での進捗（0.0〜1.0）
class _TwoThirdCircularIndicator extends StatelessWidget {
  final double radius;
  final double lineWidth;
  final double percent; // 0.0〜1.0
  final double gapAngle; // 欠け角（rad）
  final double rotation; // 回転（rad）
  final Color progressColor;
  final Color backgroundColor;
  final Widget? center;

  const _TwoThirdCircularIndicator({
    required this.radius,
    required this.lineWidth,
    required this.percent,
    required this.gapAngle,
    required this.rotation,
    required this.progressColor,
    required this.backgroundColor,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: radius * 1.98,
        height: radius * 1.98,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // CustomPaint で部分円弧を描画
            CustomPaint(
              size: Size(radius * 2, radius * 2),
              painter: _TwoThirdCircularPainter(
                lineWidth: lineWidth,
                percent: percent.clamp(0.0, 1.0),
                gapAngle: gapAngle,
                rotation: rotation,
                progressColor: progressColor,
                backgroundColor: ColorStyle.accentColor,
              ),
            ),
            if (center != null) center!,
          ],
        ),
      ),
    );
  }
}

class _TwoThirdCircularPainter extends CustomPainter {
  final double lineWidth;
  final double percent; // 0.0〜1.0
  final double gapAngle; // 欠け角（rad）
  final double rotation; // 回転（rad）
  final Color progressColor;
  final Color backgroundColor;

  _TwoThirdCircularPainter({
    required this.lineWidth,
    required this.percent,
    required this.gapAngle,
    required this.rotation,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2;

    // スタイル設定（角を丸めて滑らかに）
    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final Paint fgPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    // 2π から gapAngle を引いた描画可能な角度（=可視領域）
    final double visibleSweep = 2 * math.pi - gapAngle;

    // キャンバス回転で開始位置を調整
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation + gapAngle / 2); // ギャップを左右均等に配置
    canvas.translate(-center.dx, -center.dy);

    // 背景の弧（可視領域分のみ描画）
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      visibleSweep,
      false,
      bgPaint,
    );

    // 進捗の弧（可視領域 * percent 分）
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      visibleSweep * percent,
      false,
      fgPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TwoThirdCircularPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.gapAngle != gapAngle ||
        oldDelegate.rotation != rotation ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
