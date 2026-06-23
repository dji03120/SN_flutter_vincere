// UWB 앵커와 착용 태그 위치를 실내 지도 카드로 시각화하기 위한 기능

import 'package:flutter/material.dart';

// 실내 앵커 배치와 착용 태그 위치를 카드 형태로 표시하기 위한 기능
class IndoorActivityMapCard extends StatelessWidget {
  final Offset tagPosition;

  const IndoorActivityMapCard({super.key, required this.tagPosition});

  @override
  Widget build(BuildContext context) {
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
            const Text('실내 공간 활동량',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('앵커 4대를 기준으로 태그 위치와 이동 밀도를 추정합니다.',
                style: TextStyle(color: Color(0xFF777777), fontSize: 15)),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.35,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F8F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD7E8DE)),
                ),
                child: CustomPaint(
                  painter: _IndoorMapPainter(tagPosition: tagPosition),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 실내 지도 위에 앵커와 착용 태그 위치를 그리기 위한 기능
class _IndoorMapPainter extends CustomPainter {
  final Offset tagPosition;

  const _IndoorMapPainter({required this.tagPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD8E8DE)
      ..strokeWidth = 1;
    final anchorPaint = Paint()..color = const Color(0xFF007130);
    final tagPaint = Paint()..color = const Color(0xFFFFB84D);

    for (int i = 1; i < 4; i++) {
      final dx = size.width * i / 4;
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final anchors = [
      const Offset(0.08, 0.12),
      const Offset(0.92, 0.12),
      const Offset(0.08, 0.88),
      const Offset(0.92, 0.88),
    ];
    for (final anchor in anchors) {
      final point = Offset(anchor.dx * size.width, anchor.dy * size.height);
      canvas.drawCircle(point, 8, anchorPaint);
      canvas.drawCircle(point, 14,
          Paint()..color = const Color(0xFF007130).withOpacity(0.14));
    }

    final tag =
        Offset(tagPosition.dx * size.width, tagPosition.dy * size.height);
    canvas.drawCircle(
        tag, 18, Paint()..color = const Color(0xFFFFB84D).withOpacity(0.24));
    canvas.drawCircle(tag, 9, tagPaint);
  }

  @override
  bool shouldRepaint(covariant _IndoorMapPainter oldDelegate) {
    return oldDelegate.tagPosition != tagPosition;
  }
}
