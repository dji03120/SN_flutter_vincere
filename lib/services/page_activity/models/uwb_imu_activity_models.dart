// UWB/IMU 활동 화면에서 공유하는 데이터 모델을 정의하기 위한 기능

import 'package:Vincere/services/page_activity/activity_daily_store.dart';
import 'package:flutter/material.dart';

// 활동 측정 카드에 필요한 값을 묶기 위한 기능
class ActivityMetric {
  final String title;
  final String value;
  final String unit;
  final String target;
  final IconData icon;

  const ActivityMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.target,
    required this.icon,
  });
}

// 측정 결과 화면에 전달할 활동 요약 데이터를 묶기 위한 기능
class ActivitySessionSummary {
  final int activeSeconds;
  final int restSeconds;
  final int movementCount;
  final int restEventCount;
  final double activityScore;
  final double sitToStandCount;
  final double walkSeconds;
  final List<DailyActivitySummary> recentSummaries;

  const ActivitySessionSummary({
    required this.activeSeconds,
    required this.restSeconds,
    required this.movementCount,
    required this.restEventCount,
    required this.activityScore,
    required this.sitToStandCount,
    required this.walkSeconds,
    required this.recentSummaries,
  });
}

// 수신 감도 표시 문구와 색상을 묶기 위한 기능
class SignalStatus {
  final String label;
  final Color color;

  const SignalStatus(this.label, this.color);
}
