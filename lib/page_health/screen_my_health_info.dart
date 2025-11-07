import 'package:Vincere/component/custom_drawer.dart';
import 'package:Vincere/component/radar_chart.dart';
import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';

class ScreenHealthInfo extends StatefulWidget {
  final dynamic healthData; // 사용자 건강 데이터
  final Future<dynamic> healthInfoItemsFuture; // 건강 정보 항목 Future
  final String? userId; // 사용자 ID
  final Function initializeData; // 초기화 함수
  final dynamic msmtItemData; // 측정 항목 데이터

  const ScreenHealthInfo({
    super.key,
    required this.healthData,
    required this.healthInfoItemsFuture,
    required this.userId,
    required this.initializeData,
    required this.msmtItemData,
  });

  @override
  State<ScreenHealthInfo> createState() => _ScreenHealthInfo();
}

//
//
class _ScreenHealthInfo extends State<ScreenHealthInfo> {
  final PageController _pageController = PageController();

  // 예시 데이터
  final List<String> _radarNames = ['체지방률', '체지방량', '골격근량', '기초대사량', '체질량지수', '체중'];
  final Map<String, List<double>> _radarValues = {
    '1': [50, 60, 70, 80, 60, 70],
    '2': [60, 70, 80, 90, 70, 80],
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFF3F3F3),
      appBar: const Header(),
      drawer: const CustomDrawer(isLogin: true),
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // 그림자 색상
                    blurRadius: 8, // 흐림 정도
                    offset: const Offset(0, 4), // 그림자 위치
                  ),
                ],
              ),
              child: _content_radar(context, _radarNames, _radarValues)),
          SizedBox(height: 25),
          Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                child: Column(children: [
                  SizedBox(height: 25),
                  Container(
                    width: width * 0.85,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white, // 버튼 배경색
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // 그림자 색상
                          blurRadius: 4, // 흐림 정도
                          offset: const Offset(0, 4), // 그림자 위치
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        // 버튼 클릭 시 동작
                      },
                      child: const Center(
                        child: Text(
                          '나의 건강정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  dataRow('Body Fat Percentage (%)', 16.2, 0.60, '평균'),
                  dataRow('Body Fat Percentage (%)', 16.2, 0.80, '높음'),
                  dataRow('Body Fat Percentage (%)', 16.2, 0.40, '평균'),
                  dataRow('Body Fat Percentage (%)', 16.2, 0.91, '높음'),
                  dataRow('Body Fat Percentage (%)', 16.2, 0.30, '낮음'),
                  SizedBox(height: 25),
                ]),
              )),
          SizedBox(height: 50),
        ]),
      ),
    );
  }
}

Widget _content_radar(context, _radarNames, _radarValues) {
  double width = MediaQuery.of(context).size.width;
  return Column(
    children: [
      // 프로필 카드
      Card(
        color: Colors.black87,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
        ),
        child: Column(
          children: [
            // 상단: 버튼
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    fixedSize: Size(width * 0.7, 40),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF92D2B0), width: 2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min, // 텍스트 + 아이콘 크기만큼
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: Color(0xFF92D2B0),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '건강정보 측정하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92D2B0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              width: 312,
              child: Divider(
                color: Colors.white.withOpacity(0.15),
                thickness: 2,
              ),
            ),
            SizedBox(height: 15),

            // 하단: Radar
            SizedBox(
              height: 300 * 0.8,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CustomRadarChart(
                    features: _radarNames,
                    data: [40, 50, 80, 70, 30, 50],
                    sides: _radarNames.length,
                    graphColors: [Colors.green],
                    ticks: [33, 66, 100],
                    size: 300 * 0.78,
                  ),
                  CustomRadarChart(
                    features: _radarNames,
                    data: [50, 60, 60, 60, 35, 40],
                    sides: _radarNames.length,
                    graphColors: [Colors.orangeAccent],
                    ticks: [33, 66, 100],
                    size: 300 * 0.78,
                  ),
                  Transform.translate(
                    offset: const Offset(-105, -10),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 20, height: 3, color: Colors.orangeAccent),
                            const SizedBox(width: 6),
                            const Text(
                              '건강정보(3달 전)',
                              style: TextStyle(fontSize: 11, color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 텍스트와 막대 간격
                            Container(width: 20, height: 3, color: Colors.green),
                            const SizedBox(width: 6),
                            const Text(
                              '건강정보(현재)',
                              style: TextStyle(fontSize: 11, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 312,
              child: Divider(
                color: Colors.white.withOpacity(0.15),
                thickness: 2,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 30.0, top: 12.0, bottom: 24.0, right: 12.0),
                  child: _buildHealthMetric('키', 123, 'cm'),
                ),
                Container(
                  height: 74,
                  child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1, width: 1),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 24.0, right: 12.0),
                  child: _buildHealthMetric('몸무게', 12, 'kg'),
                ),
                Container(
                  height: 74,
                  child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1, width: 1),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 24.0, right: 30.0),
                  child: _buildHealthMetric('근육량', 12, 'kg'),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

Widget dataRow(String name, double value, double progress, String label) {
  Color color = Colors.greenAccent;
  if (progress < 0.33) {
    color = Colors.blueGrey.withOpacity(0.7);
  } else if (0.66 <= progress) {
    color = Colors.orangeAccent;
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이름 + 수치
        Row(
          children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        // 진행률 바 + 구분선 + 레이블
        Stack(
          children: [
            // 배경 바
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // 그림자 색상
                    blurRadius: 4, // 흐림 정도
                    offset: const Offset(0, 4), // 그림자 위치
                  ),
                ],
              ),
            ),
            // 진행률 바
            FractionallySizedBox(
              widthFactor: progress, // 0.0 ~ 1.0
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // 3등분 구분선
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  // 1/3 위치
                  VerticalDivider(
                    color: Colors.white,
                    thickness: 2,
                    width: 1,
                  ),
                  // 2/3 위치
                  VerticalDivider(
                    color: Colors.white,
                    thickness: 2,
                    width: 1,
                  ),
                ],
              ),
            ),
            // 텍스트 라벨
            Positioned.fill(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// 건강 정보 지표를 위한 새로운 위젯
Widget _buildHealthMetric(String label, double value, String unit) {
  return Column(
    children: [
      Text(
        label, // 라벨(키, 몸무게 등) 위치를 위로 이동
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFFFFFF).withOpacity(0.8),
        ),
      ),
      SizedBox(height: 2),
      Text(
        // 숫자 값
        value.toString(),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      SizedBox(height: 2),
      Text(
        // 단위(cm, kg 등)만 아래에 표시
        unit,
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFFFFFF).withOpacity(0.8),
        ),
      ),
    ],
  );
}
