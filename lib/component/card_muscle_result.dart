import 'package:Vincere/component/metric_chart_dialog.dart';
import 'package:Vincere/screen/utils.dart';
import 'package:flutter/material.dart';

class MuscleAgeCard extends StatelessWidget {
  final String muscleAge;
  final int msmt003Grade;
  final int msmt008Grade;
  final int msmt011Grade;
  final int msmt012Grade;
  final int msmt013Grade;
  final String userId;

  const MuscleAgeCard({
    super.key,
    required this.muscleAge,
    required this.msmt003Grade,
    required this.msmt008Grade,
    required this.msmt011Grade,
    required this.msmt012Grade,
    required this.msmt013Grade,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 왼쪽: 근육 나이 텍스트
              Container(
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width * 0.6,
                margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내 근육 나이',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: muscleAge,
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF007130)),
                          ),
                          const TextSpan(
                            text: ' 세',
                            style: TextStyle(fontSize: 22, color: Color(0xFF000000)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 오른쪽: 이미지
              Container(
                width: 60,
                height: 60,
                margin: EdgeInsets.only(
                  right: MediaQuery.of(context).size.width * 0.06,
                ),
                child: Image.asset(
                  'images/body.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),

          // ====== 메트릭 리스트 ======
          const SizedBox(height: 16),
          buildDivider(context, isBold: true),
          _buildMetricRow(context, '신체조성', '신체질량지수(BMI)', msmt003Grade, true, 'MSMT_003'),
          buildDashedDivider(context),
          _buildMetricRow(context, '', '체지방률(%)', msmt008Grade, true, 'MSMT_008'),
          buildDivider(context),
          _buildMetricRow(context, '신체기능', '악력(kg)', msmt011Grade, false, 'MSMT_011'),
          buildDashedDivider(context),
          _buildMetricRow(context, '', '걷기(m/sec)', msmt012Grade, false, 'MSMT_012'),
          buildDashedDivider(context),
          _buildMetricRow(context, '', '앉았다 일어나기(횟수)', msmt013Grade, true, 'MSMT_013'),
          buildDivider(context, isBold: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- Metric Row ---
  Widget _buildMetricRow(BuildContext context, String category, String title, int grade, bool isBest, String code) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 0,
        horizontal: MediaQuery.of(context).size.width * 0.06,
      ),
      child: Row(
        children: [
          // category
          SizedBox(
            width: 70,
            child: category.isNotEmpty
                ? Text(
                    category,
                    style: const TextStyle(color: Color(0xFF000000), fontSize: 13, fontWeight: FontWeight.w500),
                  )
                : const SizedBox(),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF555555), fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ),
          if (grade == 1)
            Container(
              width: 40,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00914B), width: 2),
              ),
              child: const Center(
                child: Text(
                  'BEST',
                  style: TextStyle(color: Color(0xFF007130), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Text(
            '$grade등급',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: grade == 1 ? const Color(0xFF00914B) : (grade == 2 ? const Color(0xFF9D895B) : const Color(0xFF8D8D8D)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Color(0xFF00914B)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return MetricChartDialog(title: title, code: code, userId: userId);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  // 생성자에서 컬러를 매개변수로 받음
  DashedLinePainter({
    this.color = Colors.grey, // 기본값 설정
  });

  @override
  void paint(Canvas canvas, Size size) {
    double dotRadius = 1; // 점의 반지름
    double dotSpace = 2; // 점 사이의 간격
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawCircle(
        Offset(startX, dotRadius), // y 위치를 반지름만큼 내려서 선이 중앙에 오도록 조정
        dotRadius,
        paint,
      );
      startX += (dotRadius * 2) + dotSpace; // 다음 점의 위치 계산
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
