import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pomodd_kusa/color_style.dart';
import 'dart:math' as math;

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'PomoGrass',
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
                Container(
                  width: screenSize.width,
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Work',
                        style: GoogleFonts.roboto(
                          fontSize: screenSize.width * .1,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      _TwoThirdCircularIndicator(
                        // 画面幅に合わせて半径を可変にする（レスポンシブ）
                        radius: screenSize.width / 2.6,
                        // 進捗（0.0〜1.0）
                        percent: .76,
                        // 円弧の太さ
                        lineWidth: 8,
                        // 配色（既存の ColorStyle を使用）
                        progressColor: Colors.grey,
                        backgroundColor: Colors.white,
                        // 欠ける角度（ここでは 1/3 を欠けさせる = 120度）
                        gapAngle: 2 * math.pi / 6,
                        // 開始位置を上方向中心に配置（任意で微調整可能）
                        rotation: math.pi / 4,
                        // 中央テキスト
                        center: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 20,
                              children: [
                                SettingTimeWidget(
                                  onTap: () {},
                                  title: 'Work Time',
                                  settingTime: 25,
                                  description: ' min',
                                  screenSize: screenSize,
                                ),
                                SettingTimeWidget(
                                  onTap: () {},
                                  title: 'Rest Time',
                                  settingTime: 5,
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
                                  title: 'Total Rest Time',
                                  settingTime: 100,
                                  description: ' min',
                                  screenSize: screenSize,
                                ),
                                SettingTimeWidget(
                                  onTap: () {},
                                  title: 'Total Work Time',
                                  settingTime: 25,
                                  description: ' min',
                                  screenSize: screenSize,
                                ),
                              ],
                            ),
                            SettingTimeWidget(
                              onTap: () {},
                              title: 'Total %',
                              settingTime: 100,
                              description: ' %',
                              screenSize: screenSize,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: screenSize.width * .03,
                  right: screenSize.width * .1,
                  child: CircleAvatar(
                    radius: screenSize.width * .12,
                    backgroundColor: Colors.white,
                    child: RichText(
                      text: TextSpan(
                        text: 'x',
                        style: GoogleFonts.roboto(
                          fontSize: screenSize.width * .12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: '4',
                            style: GoogleFonts.roboto(
                              fontSize: screenSize.width * .16,
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
  SettingTimeWidget({
    super.key,
    required this.title,
    required this.settingTime,
    required this.description,
    required this.onTap,
    required this.screenSize,
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
              fontSize: screenSize.width * .03,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          RichText(
            text: TextSpan(
              text: settingTime.toString(),
              style: GoogleFonts.roboto(
                fontSize: screenSize.width * .12,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: description,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
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
