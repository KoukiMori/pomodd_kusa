import 'package:flutter/material.dart';
import 'package:pomodgrass/data_helper.dart';
// import 'package:pomodgrass/pomod_rule.dart'; // total%評価に切り替えたため未使用
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class ContributionSection extends StatefulWidget {
  final bool previewLegend; // プレビュー（10段階）を全セルに適用
  final bool forceTodayOrange; // 当日は完了確定までオレンジを強制表示する
  const ContributionSection({
    super.key,
    this.previewLegend = false,
    this.forceTodayOrange = false,
  });

  @override
  State<ContributionSection> createState() => _ContributionSectionState();
}

class _ContributionSectionState extends State<ContributionSection> {
  DateTime? _firstPlayDate;
  // Color? _todayLegendColor; // 当日の実績に基づく評価色（未使用）
  static const List<Color> _legendPalette = [
    Color(0xFF161B22), // 0: 空
    Color(0xFF0E4429), // 1: 最低
    Color(0xFF006D32), // 2: 低
    Color(0xFF26A641), // 3: 中
    Color(0xFF39D353), // 4: 高
    Color(0xFF5AE079), // 5: 最高
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _loadTodayEvalColor();
  }

  @override
  void didUpdateWidget(covariant ContributionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadTodayEvalColor();
  }

  Future<void> _load() async {
    final firstPlay = await DataHelper.loadFirstPlayDate();
    if (!mounted) return;
    setState(() {
      _firstPlayDate = firstPlay;
    });
  }

  Future<void> _loadTodayEvalColor() async {
    // 当日の評価色をロード（UIの更新トリガーとして使用）
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    // 表示する月の範囲を動的に決定
    final List<DateTime> months = _getDisplayMonths(
      today,
      _firstPlayDate,
      widget.previewLegend,
    );

    // プレビュー中は常にダミーデータ（全セル着色）を使用。
    // そうでなければ、実データが無い場合のみダミーデータ。
    // viewData, levelFor, colorFor, colorFor5 は _buildMonthGrid に集約

    // 起点日の表示ラベル（例: 8/19~）。未設定なら空。
    String startLabel = '';
    if (widget.previewLegend) {
      // プレビューモード（ダミーデータ表示）時は固定で3月11日を起点とする
      startLabel = 'Mar/11~';
    } else if (_firstPlayDate != null) {
      // 通常モード時は実際の初回プレイ日を起点とする
      final DateTime d = _firstPlayDate!;
      startLabel = '${d.month}/${d.day}~';
    } else {
      // 起点日未設定時は本日を起点として表示（ただし実際の評価色は表示しない）
      final DateTime today = DateTime.now();
      startLabel = '${today.month}/${today.day}~';
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 年表示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${today.year}',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (startLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      startLabel,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              // 右側に10段階の凡例（Less→More）を表示
              _buildLegend(),
            ],
          ),
          // 月別カレンダーグリッド（2列配置）。
          // 当月（左上）→1ヶ月前（右）→2ヶ月前（次段左）→3ヶ月前（次段右）…
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double cardGap = 10; // 月カード間の隙間
                final double columnWidth = (constraints.maxWidth - cardGap) / 2;
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: cardGap,
                    runSpacing: cardGap,
                    children: months.map((month) {
                      // 列幅に合わせて日セルサイズを算出（7列 + 6ギャップ + 余裕）
                      const double dayGap = 2;
                      final double cellSize =
                          (columnWidth - (6 * dayGap) - 4) / 7;
                      return SizedBox(
                        width: columnWidth,
                        child: _buildMonthGrid(month, cellSize),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 表示月の配置を決定するヘルパーメソッド
  List<DateTime> _getDisplayMonths(
    DateTime today,
    DateTime? firstPlayDate,
    bool isPreview,
  ) {
    if (isPreview) {
      // プレビューON時：Mar/11を起点とした6ヶ月表示（新しい月から古い月へ）
      final DateTime dummyStartMonth = DateTime(today.year, 3, 1); // Mar/11の月
      return List<DateTime>.generate(
        6,
        (i) => DateTime(dummyStartMonth.year, dummyStartMonth.month + 5 - i, 1),
      );
    } else if (firstPlayDate == null) {
      // プレビューOFF時で初回プレイ日がない場合：当月のみ表示
      return [DateTime(today.year, today.month, 1)];
    } else {
      // 本番環境では起点月から当月までを表示
      final DateTime startMonth = DateTime(
        firstPlayDate.year,
        firstPlayDate.month,
        1,
      );
      final DateTime currentMonth = DateTime(today.year, today.month, 1);

      // 起点月から当月までの月リストを生成
      List<DateTime> monthList = [];
      DateTime month = startMonth;

      while (month.isBefore(currentMonth) ||
          (month.year == currentMonth.year &&
              month.month == currentMonth.month)) {
        monthList.add(month);
        month = DateTime(month.year, month.month + 1, 1);
      }

      // 当月を最初に、残りを古い順（起点月→当月-1）で配置
      List<DateTime> result = [currentMonth];
      for (DateTime m in monthList.reversed) {
        if (m.year != currentMonth.year || m.month != currentMonth.month) {
          result.add(m);
        }
      }

      return result;
    }
  }

  // データ表示判定メソッド
  bool _shouldShowRealData(DateTime month, DateTime? firstPlayDate) {
    if (widget.previewLegend || firstPlayDate == null) {
      return false; // プレビュー時または起点日未設定時はダミーデータ
    } else {
      // 起点月以降は実データを表示
      final DateTime startMonth = DateTime(
        firstPlayDate.year,
        firstPlayDate.month,
        1,
      );
      return month.isAfter(startMonth) ||
          (month.year == startMonth.year && month.month == startMonth.month);
    }
  }

  // 1ヶ月分のカレンダーグリッドを構築
  Widget _buildMonthGrid(DateTime month, double cellSize) {
    const double gap = 2; // 日セル間の隙間

    // 月の最初と最後
    final DateTime firstDay = DateTime(month.year, month.month, 1);
    final DateTime lastDay = DateTime(month.year, month.month + 1, 0);

    // 最初の週の開始日（日曜始まり）
    final int firstWeekday = firstDay.weekday % 7; // 0:Sun, 1:Mon, ..., 6:Sat
    final DateTime gridStart = firstDay.subtract(Duration(days: firstWeekday));

    // グリッドの週数
    final int totalDays = lastDay.day + firstWeekday;
    final int weeks = (totalDays / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月ラベル（MM/Mon 表記。例: 08/Aug, 09/Sep）
        Text(
          _formatMonthLabel(month),
          style: GoogleFonts.roboto(
            color: Colors.white54,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // 曜日ヘッダー（一部のみ表示）
        Row(
          children: List.generate(7, (day) {
            final String label = _getWeekdayHeaderLabel(day);
            return Container(
              width: cellSize,
              height: 14,
              alignment: Alignment.center,
              margin: EdgeInsets.only(right: day == 6 ? 0 : gap),
              child: label.isNotEmpty
                  ? Text(
                      label,
                      style: GoogleFonts.roboto(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    )
                  : null,
            );
          }),
        ),
        const SizedBox(height: 4),
        // カレンダーグリッド
        Column(
          children: List.generate(weeks, (week) {
            return Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: Row(
                children: List.generate(7, (day) {
                  final DateTime date = gridStart.add(
                    Duration(days: week * 7 + day),
                  );

                  // 月外の日は表示しない
                  if (date.month != month.month) {
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: EdgeInsets.only(right: day == 6 ? 0 : gap),
                    );
                  }

                  final DateTime todayDate = DateTime.now();
                  final DateTime todayOnly = DateTime(
                    todayDate.year,
                    todayDate.month,
                    todayDate.day,
                  );
                  final bool isToday =
                      date.year == todayOnly.year &&
                      date.month == todayOnly.month &&
                      date.day == todayOnly.day;
                  final bool isFuture = date.isAfter(todayOnly);

                  // FutureBuilderを使って非同期で日別データをロード
                  return FutureBuilder<DailyActualData>(
                    future: DataHelper.loadDailyActual(date),
                    builder: (context, snapshot) {
                      int score = 0;
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        // total% に基づく5段階評価（0:未達/空, 1..5:達成度）
                        final d = snapshot.data!;
                        final int goalSec =
                            (d.workTimeSetting + d.restTimeSetting) *
                            60 *
                            d.respSetting;
                        if (goalSec > 0) {
                          final double p = ((d.workSec + d.restSec) / goalSec)
                              .clamp(0.0, 1.0);
                          if (p == 0) {
                            score = 0;
                          } else if (p < .2) {
                            score = 1;
                          } else if (p < .4) {
                            score = 2;
                          } else if (p < .6) {
                            score = 3;
                          } else if (p < .8) {
                            score = 4;
                          } else {
                            score = 5;
                          }
                        }
                      }

                      // プレビューモードまたは起点月以外はダミーデータを使用
                      final bool useRealData = _shouldShowRealData(
                        month,
                        _firstPlayDate,
                      );
                      // 起点日より前かどうかをチェック
                      bool isBeforeStartDate = false;
                      if (!widget.previewLegend) {
                        if (_firstPlayDate != null) {
                          // 起点日が設定済みの場合、その日より前は表示しない
                          isBeforeStartDate = date.isBefore(_firstPlayDate!);
                        } else {
                          // 起点日が未設定の場合、すべての日付を起点日より前として扱う
                          isBeforeStartDate = true;
                        }
                      }

                      // 起点日より前の場合はスコアも0にする（評価色を表示しないため）
                      final int actualScore = isBeforeStartDate ? 0 : score;

                      // 表示スコアの決定（起点日より前は必ず0にする）
                      final int displayScore;
                      if (isBeforeStartDate && !widget.previewLegend) {
                        // プレビューモードでない場合、起点日より前は必ず0（グレー）
                        displayScore = 0;
                      } else if (widget.previewLegend || !useRealData) {
                        // プレビューモードまたは実データなしの場合はダミーデータ
                        displayScore = _buildDummyDataForDate(date, month);
                      } else {
                        // 実データを使用
                        displayScore = actualScore;
                      }

                      final Color baseColor = _legendPalette[displayScore];

                      // 当日の色判定ロジック：完了状況により色を決定
                      final Color cellColor;
                      if (isToday) {
                        // 仕様: 当日は完了確定(完了ボタン押下)まではオレンジを維持
                        if (widget.forceTodayOrange) {
                          cellColor = Colors.orangeAccent;
                        } else if (useRealData && actualScore > 0) {
                          // 完了確定後は評価色に切り替え
                          cellColor = baseColor;
                        } else {
                          // それ以外はオレンジ
                          cellColor = Colors.orangeAccent;
                        }
                      } else if (isFuture) {
                        // 未来の日付は灰色
                        cellColor = const Color(0xFF3A3A3A);
                      } else {
                        // 過去の日付は評価に基づく色
                        cellColor = baseColor;
                      }

                      return Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.only(right: day == 6 ? 0 : gap),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  );
                }),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 5段階の凡例（Less ... More）
  Widget _buildLegend() {
    return SizedBox(
      width: 180,
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Less',
            style: GoogleFonts.roboto(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 8),
          ..._legendPalette.map(
            (c) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'More',
            style: GoogleFonts.roboto(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 曜日ヘッダーラベルを取得（日曜始まり、S W S S W S W スタイル）
  String _getWeekdayHeaderLabel(int day) {
    switch (day) {
      case 0:
        return 'S'; // Sun
      case 1:
        return ''; // Mon
      case 2:
        return 'W'; // Tue
      case 3:
        return ''; // Wed
      case 4:
        return 'S'; // Thu
      case 5:
        return ''; // Fri
      case 6:
        return 'S'; // Sat
      default:
        return '';
    }
  }

  // 月ラベルを MM/Mon で返す（例: 08/Aug, 09/Sep）
  String _formatMonthLabel(DateTime date) {
    final String mm = date.month.toString().padLeft(2, '0');
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String mon = months[date.month - 1];
    return '$mm/$mon';
  }

  // ダミーのコントリビューションデータを生成
  // 月ごとのダミーデータを生成するヘルパー
  int _buildDummyDataForDate(DateTime date, DateTime month) {
    // Mar/11を起点日として、それ以前の日付は評価なし（0）として表示
    final DateTime dummyStartDate = DateTime(date.year, 3, 11);

    // Mar/11以前の日付は評価なし
    if (date.isBefore(dummyStartDate)) {
      return 0; // 空のセルとして表示
    }

    // Mar/11以降は経過日数を基にした固定シードでランダムな値を生成
    final int daysDiff = date.difference(dummyStartDate).inDays;
    final int seed = daysDiff % 10000; // 経過日数を基にしたシード
    final math.Random rng = math.Random(seed);
    return rng.nextInt(6); // 0〜5の範囲でダミーのスコアを返す
  }
}
