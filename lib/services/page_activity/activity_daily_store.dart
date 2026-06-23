// UWB/IMU 활동 데이터를 날짜별로 저장하고 조회하기 위한 기능

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// 하루 활동 요약 값을 화면과 통계에서 함께 사용하기 위한 기능
class DailyActivitySummary {
  final String dateKey;
  final int activeSeconds;
  final int restSeconds;
  final int movementCount;
  final int restEventCount;
  final double activityScore;
  final int sessionCount;

  const DailyActivitySummary({
    required this.dateKey,
    required this.activeSeconds,
    required this.restSeconds,
    required this.movementCount,
    required this.restEventCount,
    required this.activityScore,
    required this.sessionCount,
  });

  // 빈 하루 활동 데이터를 생성하기 위한 기능
  factory DailyActivitySummary.empty(String dateKey) {
    return DailyActivitySummary(
      dateKey: dateKey,
      activeSeconds: 0,
      restSeconds: 0,
      movementCount: 0,
      restEventCount: 0,
      activityScore: 0,
      sessionCount: 0,
    );
  }

  // 저장된 JSON 값을 하루 활동 데이터로 변환하기 위한 기능
  factory DailyActivitySummary.fromJson(Map<String, dynamic> json) {
    return DailyActivitySummary(
      dateKey: json['dateKey']?.toString() ?? ActivityDailyStore.todayKey(),
      activeSeconds: (json['activeSeconds'] ?? 0) as int,
      restSeconds: (json['restSeconds'] ?? 0) as int,
      movementCount: (json['movementCount'] ?? 0) as int,
      restEventCount: (json['restEventCount'] ?? 0) as int,
      activityScore: ((json['activityScore'] ?? 0) as num).toDouble(),
      sessionCount: (json['sessionCount'] ?? 0) as int,
    );
  }

  // 하루 활동 데이터를 JSON 저장 형태로 변환하기 위한 기능
  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'activeSeconds': activeSeconds,
      'restSeconds': restSeconds,
      'movementCount': movementCount,
      'restEventCount': restEventCount,
      'activityScore': activityScore,
      'sessionCount': sessionCount,
    };
  }

  // 변경된 활동 값을 반영한 새 하루 활동 데이터를 만들기 위한 기능
  DailyActivitySummary copyWith({
    int? activeSeconds,
    int? restSeconds,
    int? movementCount,
    int? restEventCount,
    double? activityScore,
    int? sessionCount,
  }) {
    return DailyActivitySummary(
      dateKey: dateKey,
      activeSeconds: activeSeconds ?? this.activeSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      movementCount: movementCount ?? this.movementCount,
      restEventCount: restEventCount ?? this.restEventCount,
      activityScore: activityScore ?? this.activityScore,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
}

// 날짜별 UWB/IMU 활동 데이터를 로컬에 보관하기 위한 기능
class ActivityDailyStore {
  static const String _storageKey = 'uwb_imu_daily_activity_records_v1';

  // 오늘 날짜를 저장 키 형태로 만들기 위한 기능
  static String todayKey() {
    return dateKey(DateTime.now());
  }

  // 날짜 값을 yyyy-MM-dd 키로 변환하기 위한 기능
  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // 저장된 전체 활동 데이터를 조회하고 테스트 데이터를 보강하기 위한 기능
  static Future<Map<String, DailyActivitySummary>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    final records = <String, DailyActivitySummary>{};

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        records[key] =
            DailyActivitySummary.fromJson(Map<String, dynamic>.from(value));
      });
    }

    final seededRecords = _withDebugRecords(records);
    if (seededRecords.length != records.length) {
      await saveAll(seededRecords);
    }
    return seededRecords;
  }

  // 오늘 활동 데이터를 조회하기 위한 기능
  static Future<DailyActivitySummary> loadToday() async {
    final records = await loadAll();
    final key = todayKey();
    return records[key] ?? DailyActivitySummary.empty(key);
  }

  // 오늘 활동 데이터를 저장하기 위한 기능
  static Future<void> saveToday(DailyActivitySummary summary) async {
    final records = await loadAll();
    records[summary.dateKey] = summary;
    await saveAll(records);
  }

  // 전체 활동 데이터를 저장하기 위한 기능
  static Future<void> saveAll(Map<String, DailyActivitySummary> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = records.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  // 최근 평균 비교용 테스트 데이터를 제공하기 위한 기능
  static Map<String, DailyActivitySummary> _withDebugRecords(
      Map<String, DailyActivitySummary> records) {
    final updated = Map<String, DailyActivitySummary>.from(records);
    final today = DateTime.now();
    final samples = [
      DailyActivitySummary(
          dateKey: dateKey(today.subtract(const Duration(days: 1))),
          activeSeconds: 920,
          restSeconds: 180,
          movementCount: 112,
          restEventCount: 2,
          activityScore: 78,
          sessionCount: 2),
      DailyActivitySummary(
          dateKey: dateKey(today.subtract(const Duration(days: 2))),
          activeSeconds: 760,
          restSeconds: 260,
          movementCount: 84,
          restEventCount: 3,
          activityScore: 66,
          sessionCount: 2),
      DailyActivitySummary(
          dateKey: dateKey(today.subtract(const Duration(days: 3))),
          activeSeconds: 1180,
          restSeconds: 120,
          movementCount: 148,
          restEventCount: 1,
          activityScore: 88,
          sessionCount: 3),
      DailyActivitySummary(
          dateKey: dateKey(today.subtract(const Duration(days: 4))),
          activeSeconds: 840,
          restSeconds: 210,
          movementCount: 96,
          restEventCount: 2,
          activityScore: 72,
          sessionCount: 2),
    ];

    for (final sample in samples) {
      updated.putIfAbsent(sample.dateKey, () => sample);
    }
    return updated;
  }
}
