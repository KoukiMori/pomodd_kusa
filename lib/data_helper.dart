import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// ユーザー設定（作業/休憩/サイクル回数）を端末へ保存・読み込みするヘルパー
/// - シンプルなキー値保存のため shared_preferences を使用
class DataHelper {
  // 保存キー（他所と衝突しないように意味のある名前にする）
  static const String _kWorkTimeKey = 'work_time';
  static const String _kRestTimeKey = 'rest_time';
  static const String _kRespKey = 'resp_count';
  static const String _kContribMapKey = 'contrib_map'; // 日付→実施回数マップ
  static const String _kFirstPlayDateKey = 'first_play_date'; // 初回プレイ日（起点）
  static const String _kDailyActualsKey =
      'daily_actuals_v2'; // 日付→その日の実績詳細マップ (workSec, restSec, workTimeSetting, restTimeSetting, respSetting)

  const DataHelper._();

  /// 端末に保存する（ユーザーが設定を変更したタイミングで呼ぶ）
  static Future<void> saveUserSettings(UserSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final UserSettings v = settings.clamped();
    await prefs.setInt(_kWorkTimeKey, v.workTime);
    await prefs.setInt(_kRestTimeKey, v.restTime);
    await prefs.setInt(_kRespKey, v.resp);
  }

  /// 端末から読み込む（起動時に呼ぶ）。保存がない場合はデフォルト値を返す
  static Future<UserSettings> loadUserSettings({
    int defaultWork = 25,
    int defaultRest = 5,
    int defaultResp = 5,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int work = prefs.getInt(_kWorkTimeKey) ?? defaultWork;
    final int rest = prefs.getInt(_kRestTimeKey) ?? defaultRest;
    final int rc = prefs.getInt(_kRespKey) ?? defaultResp;
    return UserSettings(workTime: work, restTime: rest, resp: rc).clamped();
  }

  /// yyyy-MM-dd の文字列に正規化（端末ローカル日付で集計）
  static String _dateKey(DateTime dt) {
    final DateTime d = DateTime(dt.year, dt.month, dt.day);
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  /// 日別実績: 対象日の作業/休憩秒と設定値を読み出す
  static Future<DailyActualData> loadDailyActual(DateTime date) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = _dateKey(date);
    final String? raw = prefs.getString(_kDailyActualsKey);
    final Map<String, dynamic> dataMap = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : (json.decode(raw) as Map<String, dynamic>);

    final Map<String, dynamic> dayData =
        (dataMap[key] as Map<String, dynamic>?) ?? {};

    return DailyActualData(
      workSec: (dayData['workSec'] as num?)?.toInt() ?? 0,
      restSec: (dayData['restSec'] as num?)?.toInt() ?? 0,
      workTimeSetting: (dayData['workTimeSetting'] as num?)?.toInt() ?? 25,
      restTimeSetting: (dayData['restTimeSetting'] as num?)?.toInt() ?? 5,
      respSetting: (dayData['respSetting'] as num?)?.toInt() ?? 4,
    );
  }

  /// 日別実績: 対象日に作業/休憩秒の増分と設定値を加算して保存
  static Future<void> addDailyActual(
    DateTime date, {
    int workSecDelta = 0,
    int restSecDelta = 0,
    int? workTimeSetting,
    int? restTimeSetting,
    int? respSetting,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = _dateKey(date);

    final String? raw = prefs.getString(_kDailyActualsKey);
    final Map<String, dynamic> dataMap = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : (json.decode(raw) as Map<String, dynamic>);

    final Map<String, dynamic> dayData =
        (dataMap[key] as Map<String, dynamic>?) ?? {};

    // 既存の値を読み込み、増分を適用
    final int currentWorkSec = (dayData['workSec'] as num?)?.toInt() ?? 0;
    final int currentRestSec = (dayData['restSec'] as num?)?.toInt() ?? 0;

    dayData['workSec'] = (currentWorkSec + workSecDelta).clamp(0, 86400 * 10);
    dayData['restSec'] = (currentRestSec + restSecDelta).clamp(0, 86400 * 10);

    // 設定値はnullでなければ更新
    if (workTimeSetting != null) dayData['workTimeSetting'] = workTimeSetting;
    if (restTimeSetting != null) dayData['restTimeSetting'] = restTimeSetting;
    if (respSetting != null) dayData['respSetting'] = respSetting;

    dataMap[key] = dayData;
    await prefs.setString(_kDailyActualsKey, json.encode(dataMap));
  }

  /// 既存の貢献マップを読み込む（キー: yyyy-MM-dd, 値: 実施回数）
  static Future<Map<String, int>> loadContributionMap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kContribMapKey);
    if (raw == null || raw.isEmpty) return <String, int>{};
    final Map<String, dynamic> jsonMap =
        json.decode(raw) as Map<String, dynamic>;
    return jsonMap.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// 指定日の実施回数に delta を加算（デフォルト1）
  static Future<void> addContribution(DateTime date, {int delta = 1}) async {
    if (delta == 0) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, int> map = await loadContributionMap();
    final String key = _dateKey(date);
    final int current = map[key] ?? 0;
    map[key] = (current + delta).clamp(0, 9999);
    await prefs.setString(_kContribMapKey, json.encode(map));
  }

  /// 明示的に値を設定したい場合（未使用だが将来拡張用）
  static Future<void> setContribution(DateTime date, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, int> map = await loadContributionMap();
    final String key = _dateKey(date);
    map[key] = value.clamp(0, 9999);
    await prefs.setString(_kContribMapKey, json.encode(map));
  }

  /// 初回プレイ日を保存（起点設定用）
  static Future<void> saveFirstPlayDate(DateTime date) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = _dateKey(date);
    await prefs.setString(_kFirstPlayDateKey, key);
  }

  /// 初回プレイ日を読み込み（未設定時は null）
  static Future<DateTime?> loadFirstPlayDate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? key = prefs.getString(_kFirstPlayDateKey);
    if (key == null) return null;

    // yyyy-MM-dd から DateTime に復元
    final List<String> parts = key.split('-');
    if (parts.length != 3) return null;
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}

/// 設定値（読み書きに使用）
class UserSettings {
  final int workTime; // 分: 1..60
  final int restTime; // 分: 1..10
  final int resp; // 回: 1..10

  const UserSettings({
    required this.workTime,
    required this.restTime,
    required this.resp,
  });

  /// 値をクランプして下限/上限を超えないようにする
  UserSettings clamped() {
    return UserSettings(
      workTime: workTime.clamp(1, 60),
      restTime: restTime.clamp(1, 10),
      resp: resp.clamp(1, 10),
    );
  }
}

/// 日別実績データ構造
class DailyActualData {
  final int workSec;
  final int restSec;
  final int workTimeSetting;
  final int restTimeSetting;
  final int respSetting;

  const DailyActualData({
    required this.workSec,
    required this.restSec,
    required this.workTimeSetting,
    required this.restTimeSetting,
    required this.respSetting,
  });
}
