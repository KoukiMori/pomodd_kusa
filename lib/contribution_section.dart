import 'package:flutter/material.dart';
import 'package:pomodd_kusa/data_helper.dart';
import 'package:pomodd_kusa/pomod_rule.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class ContributionSection extends StatefulWidget {
  final bool previewLegend; // プレビュー（10段階）を全セルに適用
  const ContributionSection({super.key, this.previewLegend = false});

  @override
  State<ContributionSection> createState() => _ContributionSectionState();
}

class _ContributionSectionState extends State<ContributionSection> {
  Map<String, int> _data = <String, int>{};
  DateTime? _firstPlayDate;
  // Color? _todayLegendColor; // 当日の実績に基づく評価色（未使用）
  static const List<Color> _legendPalette = [
    Color(0xFF161B22),
    Color(0xFF0E2E1F),
    Color(0xFF0E4429),
    Color(0xFF095A2C),
    Color(0xFF006D32),
    Color(0xFF13833A),
    Color(0xFF26A641),
    Color(0xFF32BF4A),
    Color(0xFF39D353),
    Color(0xFF5AE079),
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
    final map = await DataHelper.loadContributionMap();
    final firstPlay = await DataHelper.loadFirstPlayDate();
    if (!mounted) return;
    setState(() {
      _data = map;
      _firstPlayDate = firstPlay;
    });
  }

  Future<void> _loadTodayEvalColor() async {
    final DateTime now = DateTime.now();
    final (int wSec, int rSec) = await DataHelper.loadDailyActual(now);
    final UserSettings s = await DataHelper.loadUserSettings();
    final PomodActualResult res = PomodRule.evaluateActualBySeconds(
      workMin: s.workTime,
      restMin: s.restTime,
      totalWorkSeconds: wSec,
      totalRestSeconds: rSec,
      referenceCycles: 4,
    );
    // 現仕様では当日は固定オレンジで強調するため、実績色は使用しない。
    // 将来の拡張時に備えて残してある処理。
    final int _ = (res.actualScore10 - 1).clamp(0, _legendPalette.length - 1);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    // 表示する月の範囲（今月から過去5ヶ月＝計6ヶ月）
    final List<DateTime> months = List<DateTime>.generate(
      6,
      (i) => DateTime(today.year, today.month - i, 1),
    );

    // プレビュー中は常にダミーデータ（全セル着色）を使用。
    // そうでなければ、実データが無い場合のみダミーデータ。
    final Map<String, int> viewData = widget.previewLegend
        ? _buildDummyContributionData(months, includeZero: false)
        : ((_firstPlayDate == null || _data.isEmpty)
              ? _buildDummyContributionData(months)
              : _data);

    // 値の最大を求め、レベル分け（0..4）
    final int maxVal = viewData.values.fold<int>(0, (p, e) => math.max(p, e));
    int levelFor(int v) {
      if (v <= 0) return 0;
      if (maxVal <= 0) return 1;
      final double r = v / maxVal;
      if (r < 0.25) return 1;
      if (r < 0.5) return 2;
      if (r < 0.75) return 3;
      return 4;
    }

    Color colorFor10(int v) {
      if (v <= 0 || maxVal <= 0) return _legendPalette[0];
      final double ratio = (v / maxVal).clamp(0.0, 1.0);
      final int idx = (ratio * 9).round().clamp(0, _legendPalette.length - 1);
      return _legendPalette[idx];
    }

    Color colorFor(int level) {
      switch (level) {
        case 0:
          return const Color(0xFF161B22); // 空
        case 1:
          return const Color(0xFF0E4429);
        case 2:
          return const Color(0xFF006D32);
        case 3:
          return const Color(0xFF26A641);
        default:
          return const Color(0xFF39D353);
      }
    }

    // 起点日の表示ラベル（例: 8/19~）。未設定なら空。
    String startLabel = '';
    if (_firstPlayDate != null) {
      final DateTime d = _firstPlayDate!;
      startLabel = '${d.month}/${d.day}~';
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      height: 400, // 固定高さを設定してレイアウトエラーを回避
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
                        child: _buildMonthGrid(
                          month,
                          levelFor,
                          colorFor,
                          colorFor10,
                          viewData,
                          cellSize,
                        ),
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

  // 1ヶ月分のカレンダーグリッドを構築
  Widget _buildMonthGrid(
    DateTime month,
    int Function(int) levelFor,
    Color Function(int) colorFor,
    Color Function(int) colorFor10,
    Map<String, int> viewData,
    double cellSize,
  ) {
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

                  final String key = _dateKey(date);
                  final int value = viewData[key] ?? 0;
                  final int level = levelFor(value);

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

                  // 基本色（プレビュー時は10段階、通常は5段階）
                  final Color baseColor = widget.previewLegend
                      ? colorFor10(value)
                      : colorFor(level);

                  // 優先度: Today(オレンジ) > Future(グレー) > 基本色
                  final Color cellColor = isToday
                      ? Colors.orangeAccent
                      : (isFuture ? const Color(0xFF3A3A3A) : baseColor);

                  return Container(
                    width: cellSize,
                    height: cellSize,
                    margin: EdgeInsets.only(right: day == 6 ? 0 : gap),
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 10段階の凡例（Less ... More）
  Widget _buildLegend() {
    return SizedBox(
      width: 260,
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

  String _dateKey(DateTime dt) {
    final DateTime d = DateTime(dt.year, dt.month, dt.day);
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
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
  Map<String, int> _buildDummyContributionData(
    List<DateTime> months, {
    bool includeZero = true,
  }) {
    final Map<String, int> map = <String, int>{};
    // 固定シードで毎回同じ見た目
    final math.Random rng = math.Random(42);
    for (final m in months) {
      final DateTime firstDay = DateTime(m.year, m.month, 1);
      final DateTime lastDay = DateTime(m.year, m.month + 1, 0);
      for (int d = 0; d < lastDay.day; d++) {
        final DateTime date = firstDay.add(Duration(days: d));
        final String key = _dateKey(date);
        if (includeZero) {
          map[key] = rng.nextInt(11); // 0〜10
        } else {
          map[key] = rng.nextInt(10) + 1; // 1〜10（全セル着色）
        }
      }
    }
    return map;
  }
}
