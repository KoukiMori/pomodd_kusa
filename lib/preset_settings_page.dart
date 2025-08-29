import 'package:flutter/material.dart';
import 'package:pomodgrass/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pomodgrass/pomod_rule.dart';

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
                '${p.work}${AppLocalizations.of(context)!.minutesUnit}',
                style: GoogleFonts.roboto(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${p.rest}${AppLocalizations.of(context)!.minutesUnit}',
                style: GoogleFonts.roboto(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${eval.cycleMinutes}${AppLocalizations.of(context)!.minutesUnit}',
                style: GoogleFonts.roboto(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${AppLocalizations.of(context)!.approximately}${eval.breaksPerHour.toStringAsFixed(1)}${AppLocalizations.of(context)!.timesUnit}',
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
          AppLocalizations.of(context)!.presetListTitle,
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
                          AppLocalizations.of(context)!.workTimeHeader,
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text(
                          AppLocalizations.of(context)!.restTimeHeader,
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text(
                          AppLocalizations.of(context)!.cycleTotalHeader,
                          style: GoogleFonts.roboto(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Center(
                        child: Text(
                          AppLocalizations.of(context)!.breaksPerHourHeader,
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
                AppLocalizations.of(context)!.evaluationGuideTitle,
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _bullet(AppLocalizations.of(context)!.evaluationGuide1),
              _bullet(AppLocalizations.of(context)!.evaluationGuide2),
              _bullet(AppLocalizations.of(context)!.evaluationFormula),
              _bullet(AppLocalizations.of(context)!.contributionMapGuide),
              _bullet(AppLocalizations.of(context)!.achievementEvaluationGuide),
              _bullet(AppLocalizations.of(context)!.achievementExample),
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
                AppLocalizations.of(context)!.applyPresetConfirmation,
                style: GoogleFonts.roboto(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowText(
                    AppLocalizations.of(context)!.workTime,
                    '${preset.work}${AppLocalizations.of(context)!.minutesUnit}',
                  ),
                  _rowText(
                    AppLocalizations.of(context)!.restTime,
                    '${preset.rest}${AppLocalizations.of(context)!.minutesUnit}',
                  ),
                  _rowText(
                    AppLocalizations.of(context)!.cycleTotalHeader,
                    '${eval.cycleMinutes}${AppLocalizations.of(context)!.minutesUnit}',
                  ),
                  _rowText(
                    AppLocalizations.of(
                      context,
                    )!.breaksPerHourHeader.replaceAll('\n', ''),
                    '${AppLocalizations.of(context)!.approximately}${eval.breaksPerHour.toStringAsFixed(1)}${AppLocalizations.of(context)!.timesUnit}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.contributionReflectionNote,
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
                        AppLocalizations.of(context)!.cyclesLabel,
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
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(color: Colors.white),
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
                  child: Text(
                    AppLocalizations.of(context)!.executeButton,
                    style: const TextStyle(color: Colors.deepOrangeAccent),
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
