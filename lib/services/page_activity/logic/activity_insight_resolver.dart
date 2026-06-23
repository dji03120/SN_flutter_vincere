// UWB/IMU 일일 활동 요약을 문장형 결과와 상태 라벨로 해석하기 위한 기능

import 'package:Vincere/services/page_activity/models/uwb_imu_activity_models.dart';

// 활동 요약 데이터 기반 결과 문구와 추천 행동을 계산하기 위한 기능
class ActivityInsightResolver {
  final ActivitySessionSummary summary;

  const ActivityInsightResolver(this.summary);

  // 실제 측정 데이터가 있는지 판단하기 위한 기능
  bool get hasMeasuredActivity {
    return summary.activeSeconds > 0 ||
        summary.restSeconds > 0 ||
        summary.movementCount > 0 ||
        summary.restEventCount > 0;
  }

  // 최근 활동 평균 대비 오늘 활동량 비율을 계산하기 위한 기능
  double get movementRatioToRecentAverage {
    final measured = summary.recentSummaries
        .where((record) => record.movementCount > 0)
        .toList();
    if (measured.isEmpty) return 1;
    final average =
        measured.map((record) => record.movementCount).reduce((a, b) => a + b) /
            measured.length;
    if (average == 0) return 1;
    return summary.movementCount / average;
  }

  // 오늘 휴식 비율을 계산하기 위한 기능
  double get restRatio {
    final totalSeconds = summary.activeSeconds + summary.restSeconds;
    if (totalSeconds == 0) return 0;
    return summary.restSeconds / totalSeconds;
  }

  // 활동 측정 결과를 한 문장으로 요약하기 위한 기능
  String get headline {
    if (!hasMeasuredActivity) {
      return '측정된 활동 결과가 없습니다.';
    }
    if (summary.restEventCount >= 2 ||
        summary.restSeconds >= 60 ||
        restRatio >= 0.45) {
      return '오래 앉아 있는 시간이 감지되었습니다.';
    }
    if (movementRatioToRecentAverage >= 1.18 || summary.activityScore >= 82) {
      return '오늘은 움직임이 평소보다 활발합니다.';
    }
    if (movementRatioToRecentAverage <= 0.72 || summary.activityScore < 65) {
      return '오늘은 움직임이 조금 적은 편입니다.';
    }
    return '오늘 활동 흐름이 안정적으로 유지되고 있습니다.';
  }

  // 활동 측정 결과에 따른 상태 라벨을 만들기 위한 기능
  String get movementTrend {
    if (!hasMeasuredActivity) {
      return '측정 필요';
    }
    if (summary.restEventCount >= 2 ||
        summary.restSeconds >= 60 ||
        restRatio >= 0.45) {
      return '오래 앉아 있음';
    }
    if (movementRatioToRecentAverage >= 1.18 || summary.activityScore >= 82) {
      return '움직임 증가';
    }
    if (movementRatioToRecentAverage <= 0.72 || summary.activityScore < 65) {
      return '움직임 감소';
    }
    return '활동 유지';
  }

  // 활동 측정 결과에 따른 추천 행동을 만들기 위한 기능
  String get recommendation {
    if (!hasMeasuredActivity) {
      return '활동 측정을 진행해 주세요.';
    }
    if (summary.restEventCount >= 2 || summary.restSeconds >= 60) {
      return '자리에서 일어나 3분 정도 천천히 걸어보세요.';
    }
    if (summary.sitToStandCount < 10) {
      return '앉았다 일어서기 5회를 추가로 진행해보세요.';
    }
    if (summary.walkSeconds > 5) {
      return '짧은 보폭으로 4m 걷기를 한 번 더 측정해보세요.';
    }
    return '현재 활동 흐름을 유지해도 좋습니다.';
  }
}
