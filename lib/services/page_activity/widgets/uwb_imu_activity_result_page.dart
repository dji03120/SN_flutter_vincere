// UWB/IMU 활동 측정 결과 화면과 문장형 해석 UI를 제공하기 위한 기능

import 'package:Vincere/services/page_activity/logic/activity_insight_resolver.dart';
import 'package:Vincere/services/page_activity/models/uwb_imu_activity_models.dart';
import 'package:Vincere/utils/component/custom_drawer.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:flutter/material.dart';

// 측정 종료 후 문장형 활동 해석과 권장 행동을 보여주기 위한 기능
class UwbImuActivityResultPage extends StatelessWidget {
  final ActivitySessionSummary summary;

  const UwbImuActivityResultPage({super.key, required this.summary});

  // 활동 결과 해석 로직을 UI에서 분리해 사용하기 위한 기능
  ActivityInsightResolver get _resolver => ActivityInsightResolver(summary);

  // 결과 화면 전체 레이아웃을 구성하기 위한 기능
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: true),
      body: ScrollConfiguration(
        behavior: DesktopDragScrollBehavior(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildResultHero(context),
              const SizedBox(height: 16),
              if (_resolver.hasMeasuredActivity) ...[
                _buildSummaryNumbers(),
                const SizedBox(height: 16),
                _buildInsightList(),
              ] else
                _buildEmptyResultCard(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // 결과 화면의 대표 문장과 상태 라벨을 보여주기 위한 기능
  Widget _buildResultHero(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('뒤로가기'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF92D2B0),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF92D2B0).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF92D2B0), width: 1.4),
                ),
                child: const Icon(Icons.fact_check_rounded,
                    color: Color(0xFF92D2B0), size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('활동 측정 결과',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(_resolver.headline,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.45)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE2FFF0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(_resolver.movementTrend,
                style: const TextStyle(
                    color: Color(0xFF007130),
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // 측정 데이터가 없을 때 결과 화면의 빈 상태를 안내하기 위한 기능
  Widget _buildEmptyResultCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Color(0xFF007130), size: 34),
            SizedBox(height: 14),
            Text('측정된 활동 결과가 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('활동 측정을 진행해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // 결과 화면의 핵심 숫자 요약을 보여주기 위한 기능
  Widget _buildSummaryNumbers() {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
                child: _buildResultStat(Icons.timer_rounded, '활동 시간',
                    _formatDuration(summary.activeSeconds))),
            Container(width: 1, height: 44, color: const Color(0xFFE6E6E6)),
            Expanded(
                child: _buildResultStat(Icons.directions_run_rounded, '움직임',
                    '${summary.movementCount}회')),
            Container(width: 1, height: 44, color: const Color(0xFFE6E6E6)),
            Expanded(
                child: _buildResultStat(Icons.self_improvement_rounded, '휴식',
                    _formatDuration(summary.restSeconds))),
          ],
        ),
      ),
    );
  }

  // 결과 화면의 숫자 항목 하나를 표시하기 위한 기능
  Widget _buildResultStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00914B), size: 26),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  // 결과 화면의 문장형 해석 목록을 보여주기 위한 기능
  Widget _buildInsightList() {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘의 활동 해석',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildResultInsight(
                Icons.trending_up_rounded, _resolver.movementTrend),
            _buildResultInsight(
                Icons.event_seat_rounded, '휴식 감지 ${summary.restEventCount}회'),
            _buildResultInsight(
                Icons.recommend_rounded, _resolver.recommendation),
          ],
        ),
      ),
    );
  }

  // 결과 화면의 문장형 해석 한 줄을 표시하기 위한 기능
  Widget _buildResultInsight(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE2FFF0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF007130), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.45)),
          ),
        ],
      ),
    );
  }

  // 결과 화면에서 초 단위 시간을 읽기 쉽게 변환하기 위한 기능
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainSeconds = seconds % 60;
    if (minutes == 0) {
      return '$remainSeconds초';
    }
    return '$minutes분 $remainSeconds초';
  }
}
