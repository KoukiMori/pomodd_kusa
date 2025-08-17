import 'package:flutter/material.dart';
import 'package:pomodd_kusa/data_helper.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class ContributionSection extends StatefulWidget {
  const ContributionSection({super.key});

  @override
  State<ContributionSection> createState() => _ContributionSectionState();
}

class _ContributionSectionState extends State<ContributionSection> {
  Map<String, int> _data = <String, int>{};
  DateTime? _firstPlayDate;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    // 表示する月の範囲（今月から過去5ヶ月＝計6ヶ月）
    final List<DateTime> months = List<DateTime>.generate(
      6,
      (i) => DateTime(today.year, today.month - i, 1),
    );

    // 実データが無い場合はダミーデータで表示
    final Map<String, int> viewData = (_firstPlayDate == null || _data.isEmpty)
        ? _buildDummyContributionData(months)
        : _data;

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

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      height: 400, // 固定高さを設定してレイアウトエラーを回避
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 年表示
          Text(
            '${today.year}',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
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

                  return Container(
                    width: cellSize,
                    height: cellSize,
                    margin: EdgeInsets.only(right: day == 6 ? 0 : gap),
                    decoration: BoxDecoration(
                      color: colorFor(level),
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
  Map<String, int> _buildDummyContributionData(List<DateTime> months) {
    final Map<String, int> map = <String, int>{};
    // 固定シードで毎回同じ見た目
    final math.Random rng = math.Random(42);
    for (final m in months) {
      final DateTime firstDay = DateTime(m.year, m.month, 1);
      final DateTime lastDay = DateTime(m.year, m.month + 1, 0);
      for (int d = 0; d < lastDay.day; d++) {
        final DateTime date = firstDay.add(Duration(days: d));
        final String key = _dateKey(date);
        map[key] = rng.nextInt(11); // 0〜10
      }
    }
    return map;
  }
}
