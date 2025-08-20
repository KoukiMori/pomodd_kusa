// ポモドーロ設定の評価ルール
// 画像の表（作業時間×休憩時間）に基づいて、頻度の評価と5段階評価を返す。
// UIは変更せず、呼び出し側から
//   final eval = PomodRule.evaluate(workMin: 25, restMin: 5);
// のように使う想定。

class PomodEvaluation {
  final int workMinutes; // 作業時間（分）
  final int restMinutes; // 休憩時間（分）
  final int cycleMinutes; // 1サイクル合計（分）
  final double breaksPerHour; // 1時間あたりの休憩回数（概算）
  final String frequencyLabel; // 頻度の評価
  final int score5; // 5段階評価（1..5）

  const PomodEvaluation({
    required this.workMinutes,
    required this.restMinutes,
    required this.cycleMinutes,
    required this.breaksPerHour,
    required this.frequencyLabel,
    required this.score5,
  });
}

class PomodPreset {
  final int work;
  final int rest;
  const PomodPreset(this.work, this.rest);
}

/// 実績評価の結果（基準評価＋実績加味のスコア）
class PomodActualResult {
  final PomodEvaluation baseline; // 設定ペースに基づく評価（既存表ベース）
  final int actualScore5; // 実績重み付け後の5段階評価
  final double progressWeight; // 進捗重み（0.0〜1.0）
  final int actualTotalMinutes; // 実績の合計分
  final int referenceTotalMinutes; // 基準（例: 4サイクル）合計分

  const PomodActualResult({
    required this.baseline,
    required this.actualScore5,
    required this.progressWeight,
    required this.actualTotalMinutes,
    required this.referenceTotalMinutes,
  });
}

class PomodRule {
  // 事前に用意するプリセット（表に掲載の代表値）
  static const List<PomodPreset> presets = <PomodPreset>[
    PomodPreset(10, 2),
    PomodPreset(15, 3),
    PomodPreset(15, 5),
    PomodPreset(20, 3),
    PomodPreset(20, 5),
    PomodPreset(25, 5),
    PomodPreset(30, 5),
    PomodPreset(30, 10),
    PomodPreset(40, 5),
    PomodPreset(40, 10),
    PomodPreset(50, 10),
    PomodPreset(60, 10),
    PomodPreset(90, 15),
  ];

  // 表にある定義済みの組み合わせを switch で分岐して評価を返す
  static PomodEvaluation evaluate({
    required int workMin,
    required int restMin,
  }) {
    // 1サイクル合計と1時間あたりの回数（概算）を事前計算
    final int cycle = workMin + restMin;
    final double perHour = cycle > 0 ? (60.0 / cycle) : 0.0;

    switch (workMin) {
      case 10:
        switch (restMin) {
          case 2:
            return _build(workMin, restMin, 12, 5.0, '極端に多い', 5);
        }
        break;
      case 15:
        switch (restMin) {
          case 3:
            return _build(workMin, restMin, 18, 3.3, 'とても多い', 5);
          case 5:
            return _build(workMin, restMin, 20, 3.0, 'かなり多い', 4);
        }
        break;
      case 20:
        switch (restMin) {
          case 3:
            return _build(workMin, restMin, 23, 2.6, '多め', 4);
          case 5:
            return _build(workMin, restMin, 25, 2.4, '多い', 3);
        }
        break;
      case 25:
        switch (restMin) {
          case 5:
            return _build(workMin, restMin, 30, 2.0, '標準', 3);
        }
        break;
      case 30:
        switch (restMin) {
          case 5:
            return _build(workMin, restMin, 35, 1.7, '標準より少', 2);
          case 10:
            return _build(workMin, restMin, 40, 1.5, '少なめ', 2);
        }
        break;
      case 40:
        switch (restMin) {
          case 5:
            return _build(workMin, restMin, 45, 1.3, '少なめ', 2);
          case 10:
            return _build(workMin, restMin, 50, 1.2, '少ない', 1);
        }
        break;
      case 50:
        switch (restMin) {
          case 10:
            return _build(workMin, restMin, 60, 1.0, 'かなり少ない', 1);
        }
        break;
      case 60:
        switch (restMin) {
          case 10:
            return _build(workMin, restMin, 70, 0.9, '非常に少ない', 1);
        }
        break;
      case 90:
        switch (restMin) {
          case 15:
            return _build(workMin, restMin, 105, 0.6, '超少ない', 1);
        }
        break;
    }

    // 表に無い組み合わせは簡易的に閾値で評価（安全なフォールバック）
    return _fallback(
      workMin: workMin,
      restMin: restMin,
      cycle: cycle,
      perHour: perHour,
    );
  }

  // 表定義に完全一致する場合のビルダー
  static PomodEvaluation _build(
    int work,
    int rest,
    int cycle,
    double perHour,
    String label,
    int score,
  ) {
    return PomodEvaluation(
      workMinutes: work,
      restMinutes: rest,
      cycleMinutes: cycle,
      breaksPerHour: perHour,
      frequencyLabel: label,
      score5: score,
    );
  }

  // 表にない値のフォールバック（おおよその頻度に近い評価を付与）
  static PomodEvaluation _fallback({
    required int workMin,
    required int restMin,
    required int cycle,
    required double perHour,
  }) {
    // 閾値は表の行に合わせた近似（5段階）
    String label;
    int score;
    if (perHour >= 3.0) {
      label = '極端に多い';
      score = 5;
    } else if (perHour >= 2.4) {
      label = '多い';
      score = 4;
    } else if (perHour >= 1.9) {
      label = '標準';
      score = 3;
    } else if (perHour >= 1.3) {
      label = '少ない';
      score = 2;
    } else {
      label = '非常に少ない';
      score = 1;
    }

    return PomodEvaluation(
      workMinutes: workMin,
      restMinutes: restMin,
      cycleMinutes: cycle,
      breaksPerHour: perHour,
      frequencyLabel: label,
      score5: score,
    );
  }

  // 実績（秒）から重み付け実績評価を算出。
  // referenceCycles: 基準サイクル数（デフォルト4）。完了実績が短い場合はスコアを按分。
  static PomodActualResult evaluateActualBySeconds({
    required int workMin,
    required int restMin,
    required int totalWorkSeconds,
    required int totalRestSeconds,
    int referenceCycles = 4,
  }) {
    final PomodEvaluation base = evaluate(workMin: workMin, restMin: restMin);
    final int perCycleMin = (workMin + restMin).clamp(0, 100000);
    final int actualTotalMin = ((totalWorkSeconds + totalRestSeconds) / 60)
        .round();
    final int referenceTotalMin = perCycleMin * referenceCycles;
    final double weight = referenceTotalMin > 0
        ? (actualTotalMin / referenceTotalMin).clamp(0.0, 1.0)
        : 0.0;
    final int actualScore = (base.score5 * weight).round().clamp(1, 5);

    return PomodActualResult(
      baseline: base,
      actualScore5: actualScore,
      progressWeight: weight,
      actualTotalMinutes: actualTotalMin,
      referenceTotalMinutes: referenceTotalMin,
    );
  }

  // 実績（完了サイクル数と現在進行中の割合）から重み付け評価を算出。
  static PomodActualResult evaluateActualByCycles({
    required int workMin,
    required int restMin,
    required int completedCycles,
    double currentPhaseProgress = 0.0, // 0.0〜1.0（任意）
    bool isWorkPhase = true, // 進行中フェーズ（任意）
    int referenceCycles = 4,
  }) {
    final PomodEvaluation base = evaluate(workMin: workMin, restMin: restMin);
    final int perCycleMin = (workMin + restMin).clamp(0, 100000);

    // 実績合計分 = 完了サイクル分 + 進行中フェーズの進捗分
    int actualMin = completedCycles * perCycleMin;
    if (currentPhaseProgress > 0) {
      final int phaseMin = isWorkPhase ? workMin : restMin;
      actualMin += (phaseMin * currentPhaseProgress).round();
    }

    final int referenceTotalMin = perCycleMin * referenceCycles;
    final double weight = referenceTotalMin > 0
        ? (actualMin / referenceTotalMin).clamp(0.0, 1.0)
        : 0.0;
    final int actualScore = (base.score5 * weight).round().clamp(1, 5);

    return PomodActualResult(
      baseline: base,
      actualScore5: actualScore,
      progressWeight: weight,
      actualTotalMinutes: actualMin,
      referenceTotalMinutes: referenceTotalMin,
    );
  }
}
