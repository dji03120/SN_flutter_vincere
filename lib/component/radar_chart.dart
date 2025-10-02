import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';

class RadarChartWidget extends StatelessWidget {
  final List<String> features;
  final List<List<num>> data;
  final List<int> ticks;
  final List<Color> colors;

  const RadarChartWidget({
    super.key,
    required this.features,
    required this.data,
    this.ticks = const [6, 12, 18, 24, 30],
    this.colors = const [Colors.orangeAccent],
  });

  @override
  Widget build(BuildContext context) {
    return RadarChart(
      features: features,
      data: data,
      ticks: ticks,
      featuresTextStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF111111),
        fontWeight: FontWeight.bold,
      ),
      // 줄 높이 → 글자가 더 멀어짐
      outlineColor: Color(0xFF888888), // ✅ 테두리 색 설정
      graphColors: colors,
      sides: features.length,
    );
  }
}
