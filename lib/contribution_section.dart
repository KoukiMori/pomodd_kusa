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
    // 初回プレイ日が設定されていない場合は空表示
    if (_firstPlayDate == null) {
      return Expanded(
        flex: 1,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Text(
              'セッションを完了すると\n貢献グラフが表示されます',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(color: Colors.white54, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final DateTime today = DateTime.now();
    final DateTime startDate = _firstPlayDate!;

    // 表示する月の範囲を決定（今月から過去12ヶ月）
    final List<DateTime> months = [];
    for (int i = 0; i < 12; i++) {
      final DateTime month = DateTime(today.year, today.month - i, 1);
      if (month.isBefore(startDate) ||
          month.isAtSameMomentAs(
            DateTime(startDate.year, startDate.month, 1),
          )) {
        break; // 起点月より前は表示しない
      }
      months.add(month);
    }

    // 起点月も含める
    if (months.isEmpty ||
        !months.any(
          (m) => m.year == startDate.year && m.month == startDate.month,
        )) {
      months.add(DateTime(startDate.year, startDate.month, 1));
    }

    // 新しい順（今月が最初）にソート
    months.sort((a, b) => b.compareTo(a));

    // 値の最大を求め、レベル分け（0..4）
    final int maxVal = _data.values.fold<int>(0, (p, e) => math.max(p, e));
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

    return Expanded(
      flex: 1,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 年表示
            Text(
              '${today.year}',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // 月別カレンダーグリッド
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: months.map((month) {
                    return _buildMonthGrid(month, levelFor, colorFor);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1ヶ月分のカレンダーグリッドを構築
  Widget _buildMonthGrid(
    DateTime month,
    int Function(int) levelFor,
    Color Function(int) colorFor,
  ) {
    const double cellSize = 22;
    const double gap = 2;
    const double monthWidth = (cellSize + gap) * 7 + 16; // 7日分 + 余白

    // 月の最初と最後
    final DateTime firstDay = DateTime(month.year, month.month, 1);
    final DateTime lastDay = DateTime(month.year, month.month + 1, 0);

    // 最初の週の開始日（日曜始まり）
    final int firstWeekday = firstDay.weekday % 7; // 0:Sun, 1:Mon, ..., 6:Sat
    final DateTime gridStart = firstDay.subtract(Duration(days: firstWeekday));

    // グリッドの週数
    final int totalDays = lastDay.day + firstWeekday;
    final int weeks = (totalDays / 7).ceil();

    return Container(
      width: monthWidth,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 月ラベル
          Text(
            _getMonthName(month.month),
            style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          // 曜日ヘッダー（一部のみ表示）
          Row(
            children: List.generate(7, (day) {
              final String label = _getWeekdayHeaderLabel(day);
              return Container(
                width: cellSize + gap,
                height: 12,
                alignment: Alignment.center,
                child: label.isNotEmpty
                    ? Text(
                        label,
                        style: GoogleFonts.roboto(
                          color: Colors.white54,
                          fontSize: 8,
                        ),
                      )
                    : null,
              );
            }),
          ),
          const SizedBox(height: 2),
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
                        margin: EdgeInsets.only(right: gap),
                      );
                    }

                    final String key = _dateKey(date);
                    final int value = _data[key] ?? 0;
                    final int level = levelFor(value);

                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: EdgeInsets.only(right: gap),
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

  // 月名を取得（英語略称）
  String _getMonthName(int month) {
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
    return months[month - 1];
  }
}
