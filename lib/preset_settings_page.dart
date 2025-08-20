import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pomodd_kusa/pomod_rule.dart';

// プリセット選択画面
// - こちらで用意した表（5段階評価）をテーブルで表示
// - 行をタップすると {work, rest} を返して呼び出し元へ反映させる
class PresetSettingsPage extends StatelessWidget {
  const PresetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = PomodRule.presets.map((p) {
      final eval = PomodRule.evaluate(workMin: p.work, restMin: p.rest);
      // 25分作業 + 5分休憩の行を強調
      final bool isStandardPomodoro = (p.work == 25 && p.rest == 5);
      return DataRow(
        // 行タップ時に最終確認ダイアログを表示
        onSelectChanged: (_) async {
          await _showConfirmDialog(context: context, preset: p, eval: eval);
        },
        color: isStandardPomodoro
            ? WidgetStateProperty.all(Colors.blueGrey.shade800)
            : null,
        cells: [
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
        ],
      );
    }).toList();
    final Size screenSize = MediaQuery.of(context).size;
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
        toolbarHeight: screenSize.height * .06,
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
                  ],
                  rows: rows,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF111111),
                  ),
                  dataRowColor: WidgetStateProperty.all(
                    const Color(0xFF0A0A0A),
                  ),
                  dividerThickness: 0.4,
                  headingRowHeight: 48,
                  columnSpacing: 20,
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
              _bullet(
                'この表は「作業時間と休憩時間のバランス」に基づいています。'
                '（例：25分作業+5分休憩が「標準」です。）',
              ),
              _bullet(
                '標準の25分作業＋5分休憩は評価3として反映され、それ以外の時間設定は作業と休憩のバランスにより評価が変わります。',
              ),
              _bullet('計算式: 60 ÷ (作業分 + 休憩分) ≒ 1時間あたりの休憩回数'),
              _bullet('コントリビューションマップでは達成度合いを「達成評価」としてヒートマップで表示します。'),
              _bullet(
                '達成評価は、選択した設定自体の基準評価（内部的に計算されるバランス評価）と、設定した目標サイクル数に対する実際の達成度合い（完了した作業・休憩時間）の組み合わせで決定されます。',
              ),
              _bullet(
                '（例: 設定4サイクルに対し2サイクル完了した場合、達成度は50%となり、その日の「達成評価」に反映されます。）',
              ),
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
        int selectedCycles = 4; // 標準値
        return StatefulBuilder(
          builder: (context, setStateSB) {
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
                  _rowText('作業時間', '${preset.work}分'),
                  _rowText('休憩時間', '${preset.rest}分'),
                  _rowText('1サイクル合計', '${eval.cycleMinutes}分'),
                  _rowText(
                    '1時間あたりの休憩回数',
                    '約${eval.breaksPerHour.toStringAsFixed(1)}回',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'コントリビューションマップに達成評価として反映されます。',
                    style: GoogleFonts.roboto(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'サイクル数',
                        style: GoogleFonts.roboto(color: Colors.white70),
                      ),
                      DropdownButton<int>(
                        value: selectedCycles,
                        dropdownColor: Colors.black,
                        style: GoogleFonts.roboto(color: Colors.white),
                        items: List.generate(10, (i) {
                          final val = i + 1;
                          return DropdownMenuItem<int>(
                            value: val,
                            child: Text('$val'),
                          );
                        }),
                        onChanged: (v) =>
                            setStateSB(() => selectedCycles = v ?? 4),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(true);
                    Navigator.of(context).pop(<String, int>{
                      'work': preset.work,
                      'rest': preset.rest,
                      'resp': selectedCycles,
                    });
                  },
                  child: const Text(
                    '実行',
                    style: TextStyle(color: Colors.deepOrangeAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      // すでにpop済み（上で返却）。ここでは何もしない。
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
