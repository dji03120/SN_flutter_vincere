import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'dart:math';

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

class CustomRadarChart extends StatelessWidget {
  final List<String> features; // 꼭짓점 이름
  final List<double> data; // 0~100 값
  final int sides; // 꼭짓점 개수
  final List<Color> graphColors; // 그래프 색상
  final List<int> ticks; // 눈금 값
  final double size; // 차트 크기

  const CustomRadarChart({
    super.key,
    required this.features,
    required this.data,
    this.sides = 6,
    this.graphColors = const [Colors.orangeAccent],
    this.ticks = const [33, 66, 100],
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarChartPainter(
          features: features,
          data: data,
          sides: sides,
          graphColors: graphColors,
          ticks: ticks,
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<String> features;
  final List<double> data;
  final int sides;
  final List<Color> graphColors;
  final List<int> ticks;

  _RadarChartPainter({
    required this.features,
    required this.data,
    required this.sides,
    required this.graphColors,
    required this.ticks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8; // padding 비율
    final angle = 2 * pi / sides;

    final Paint tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke;

    final Paint outlinePaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Paint graphPaint = Paint()
      ..color = graphColors.first
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 1️⃣ Tick(눈금) 그리기
    for (int t in ticks) {
      double r = radius * (t / 100);
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final x = center.dx + r * cos(i * angle - pi / 2);
        final y = center.dy + r * sin(i * angle - pi / 2);
        if (i == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      if (t == 66) {
        final fillPaint = Paint()
          ..color = Colors.grey.withOpacity(0.15)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);
      } else {
        canvas.drawPath(path, tickPaint);
      }
    }

    // 2️⃣ 데이터 그래프 그리기
    final path = Path();
    for (int i = 0; i < sides; i++) {
      double value = (i < data.length) ? data[i] : 0;
      double r = radius * (value / 100);
      final x = center.dx + r * cos(i * angle - pi / 2);
      final y = center.dy + r * sin(i * angle - pi / 2);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();

    // 채우기(PaintingStyle.fill) + 50% 투명도
    final fillPaint = Paint()
      ..color = graphColors.first.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

// 외곽선 유지
    final strokePaint = Paint()
      ..color = graphColors.first
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(path, strokePaint);

    // 3️⃣ Feature 이름 중앙 배치
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      final r = radius + 16; // 글자 간격
      double x = center.dx + r * cos(i * angle - pi / 2);
      double y = center.dy + r * sin(i * angle - pi / 2);
      if (r * cos(i * angle - pi / 2) > 5) {
        x += 15;
      } else if (r * cos(i * angle - pi / 2) < -5) {
        x -= 15;
      }

      textPainter.text = TextSpan(
        text: feature,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.normal),
      );
      textPainter.layout();
      final offset = Offset(x - textPainter.width / 2, y - textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
