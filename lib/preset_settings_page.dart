import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pomodd_kusa/pomod_rule.dart';

// プリセット選択画面
// - こちらで用意した表（10段階評価）をテーブルで表示
// - 行をタップすると {work, rest} を返して呼び出し元へ反映させる
class PresetSettingsPage extends StatelessWidget {
  const PresetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = PomodRule.presets.map((p) {
      final eval = PomodRule.evaluate(workMin: p.work, restMin: p.rest);
      return DataRow(
        // 行タップ時に最終確認ダイアログを表示
        onSelectChanged: (_) async {
          await _showConfirmDialog(context: context, preset: p, eval: eval);
        },
        cells: [
          DataCell(
            Center(
              child: Text(
                '${eval.score10}',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(color: Colors.white),
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${p.work}分',
                style: GoogleFonts.roboto(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${p.rest}分',
                style: GoogleFonts.roboto(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${eval.cycleMinutes}分',
                style: GoogleFonts.roboto(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '約${eval.breaksPerHour.toStringAsFixed(1)}回',
                style: GoogleFonts.roboto(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                eval.frequencyLabel,
                style: GoogleFonts.roboto(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          'Preset List',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: 28,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          // 画面全体の縦スクロール
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 表（横スクロール）
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(
                      label: Center(
                        child: Text(
                          '10段階評価',
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text(
                          '作業時間',
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text(
                          '休憩時間',
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text(
                          '1サイクル合計',
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text(
                          '1時間あたり\nの休憩回数',
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text(
                          '頻度の評価',
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  rows: rows,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF111111),
                  ),
                  dataRowColor: WidgetStateProperty.all(
                    const Color(0xFF0A0A0A),
                  ),
                  dividerThickness: 0.4,
                ),
              ),
              const SizedBox(height: 16),
              // 表の評価基準の説明（実装仕様に合わせる）
              Text(
                '評価の見方（この表について）',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _bullet('この表の10段階評価は「1時間あたりの休憩回数」を基準に算出しています'),
              _bullet('計算式: 60 ÷ (作業分 + 休憩分) ≒ 1時間あたりの休憩回数'),
              _bullet('回数が多いほどスコアは高く色が濃い（例: 約5回→10点、約0.6回→1点）'),
              _bullet('例1: 10分 + 2分 = 12分 → 約5回/時 → 10点（極端に多い）'),
              _bullet('例2: 25分 + 5分 = 30分 → 約2回/時 → 5点（標準）'),
              _bullet('「1サイクル合計」は時間の目安で、評価はサイクル数に依存しません'),
              _bullet('任意: 実績に基づく重み付け評価（4サイクルを基準に按分）にも対応しています'),
            ],
          ),
        ),
      ),
    );
  }

  // 最終確認ダイアログ
  Future<void> _showConfirmDialog({
    required BuildContext context,
    required PomodPreset preset,
    required PomodEvaluation eval,
  }) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'この設定を適用しますか？',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowText('10段階評価', '${eval.score10}'),
              _rowText('作業時間', '${preset.work}分'),
              _rowText('休憩時間', '${preset.rest}分'),
              _rowText('1サイクル合計', '${eval.cycleMinutes}分'),
              _rowText(
                '1時間あたりの休憩回数',
                '約${eval.breaksPerHour.toStringAsFixed(1)}回',
              ),
              _rowText('頻度の評価', eval.frequencyLabel),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('実行'),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      Navigator.of(
        context,
      ).pop(<String, int>{'work': preset.work, 'rest': preset.rest});
    }
  }

  Widget _rowText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.roboto(color: Colors.white70)),
          Text(value, style: GoogleFonts.roboto(color: Colors.white)),
        ],
      ),
    );
  }

  // 箇条書き行
  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(text, style: GoogleFonts.roboto(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
