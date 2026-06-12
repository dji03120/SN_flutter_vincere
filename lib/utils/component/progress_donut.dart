import 'package:flutter/material.dart';
import 'dart:math';

class DonutProgress extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  final Size size; // 도넛 크기
  final String centerText; // 가운데 표시할 글자
  final double strokeWidth;

  const DonutProgress({
    super.key,
    this.progress = 75,
    this.size = const Size(200, 200),
    this.centerText = '75%',
    this.strokeWidth = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: size,
          painter: DonutProgressPainter(progress, strokeWidth),
        ),
        Text(
          centerText,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 111, 163, 27),
          ),
        ),
      ],
    );
  }
}

class DonutProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  DonutProgressPainter(this.progress, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = Color.fromARGB(255, 111, 163, 27)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 배경 원
    canvas.drawCircle(center, radius, backgroundPaint);

    // 진행 원호
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
