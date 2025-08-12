import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pomodd_kusa/color_style.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/services.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  // 設定値（状態）
  int workTime = 25;
  int restTime = 5;
  int resp = 5;

  // タイマー/アニメーション用の状態
  late final AnimationController _animationController; // 0.0→1.0で進行
  double _progress = 0.0; // 円弧の進捗 (0.0〜1.0)
  bool _isRunning = false; // 再生中かどうか
  bool _isWorkPhase = true; // true=Work, false=Rest
  int _currentCycle = 0; // 0始まり、resp回実行
  Timer? _blinkTimer; // 1秒ごとの点滅用
  bool _blinkOn = true; // true: 表示, false: 非表示
  bool _isPaused = false; // 一時停止中かどうか

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
            'セッション完了',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          content: Text(
            'おつかれさまです！全てのサイクルが完了しました。',
            style: GoogleFonts.roboto(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                // 完了: 状態を初期化
                setState(() {
                  _isRunning = false;
                  _isPaused = false;
                  _progress = 0.0;
                  _currentCycle = 0;
                  _isWorkPhase = true;
                });
                Navigator.of(context).pop();
              },
              child: const Text('完了'),
            ),
          ],
        );
      },
    );
  }

  // フェーズ切り替え音（システムのクリック音を再生）
  void _playPhaseChangeSound() {
    // Work/Rest 切り替え時にシステムのアラート音 + 触覚フィードバック
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
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
            '設定を変更しますか？',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          content: Text(
            '変更すると現在のタイマーはリセットされ、新しい設定で開始します。',
            style: GoogleFonts.roboto(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('変更'),
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
        List<Widget> _numberItems(int count) =>
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
                            initialItem: (workTime - 1).clamp(
                              0,
                              59,
                            ), // 1..60 → 0..59
                          ),
                          onSelectedItemChanged: (index) =>
                              tempWork = index + 1,
                          children: _numberItems(60), // Work: 1..60
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
                          children: _numberItems(10), // Rest: 1..10
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
                          children: _numberItems(10), // Resp: 1..10
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
      workTime = tempWork.clamp(1, 60);
      restTime = tempRest.clamp(1, 10);
      resp = tempResp.clamp(1, 10);
    });
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
      _isWorkPhase = false;
      _startCurrentPhase();
    } else {
      // Restが終わったら次サイクルへ
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
        });
        // ダイアログで完了通知
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
    _currentCycle = 0;
    _isWorkPhase = true;
    _progress = 0.0;
    _startCurrentPhase();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'PomodGrass',
          style: GoogleFonts.roboto(
            fontSize: 32,
            color: ColorStyle.textColor,
            fontWeight: FontWeight.w300,
          ),
        ),
        toolbarHeight: screenSize.height * .03,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                Positioned(
                  top: screenSize.width * .01,
                  left: screenSize.width * .036,
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
                Positioned(
                  top: screenSize.width * .16,
                  right: screenSize.width * .036,
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
                  top: screenSize.width * .12,
                  // 10/10 の位置はそのまま、9以下（1桁）の場合は少し左へ寄せる
                  right: screenSize.width * (.12 + (resp < 10 ? .0 : -.08)),
                  child: GestureDetector(
                    onTap: () => _onTapSettings(screenSize),
                    child: RichText(
                      text: TextSpan(
                        // 残りサイクル数/合計サイクル数（x2が1減る挙動）
                        text: _remainingCycles.toString(),
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: screenSize.width * .16,
                          letterSpacing: 4,
                        ),
                        children: [
                          TextSpan(
                            text: '/',
                            style: GoogleFonts.roboto(
                              fontSize: screenSize.width * .1,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                          TextSpan(
                            text: resp.toString(),
                            style: GoogleFonts.roboto(
                              fontSize: screenSize.width * .06,
                              letterSpacing: 4,
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
          Expanded(flex: 1, child: Container(color: Colors.deepOrangeAccent)),
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
        width: radius * 2,
        height: radius * 2,
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
                backgroundColor: backgroundColor,
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
