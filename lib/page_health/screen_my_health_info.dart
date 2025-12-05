import 'dart:async';

import 'package:Vincere/component/custom_drawer.dart';
import 'package:Vincere/component/radar_chart.dart';
import 'package:Vincere/export/screens.dart';
import 'package:Vincere/http/webReqFastapi.dart';
import 'package:Vincere/http/webReqSpring.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/page_ble_device/page_connect_fitrux_weight.dart';
import 'package:Vincere/page_health/page_select_device.dart';
import 'package:Vincere/page_health/screen_my_health_info_raw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenHealthInfo extends StatefulWidget {
  final dynamic healthData;
  final Future<dynamic> healthInfoItemsFuture;
  final String? userId;
  final Function initializeData;
  final dynamic msmtItemData;

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
  Map userHealthData = {};
  Map userGradeList = {};
  Map userInfo = {};
  bool _isLoading = true;
  // 예시 데이터
  final List<String> _radarNames = ['신체질량지수(BMI)', '체지방률', '근육량', '앉았다 일어서기', '걷기', '악력'];
  final Map<String, List<double>> _radarValues = {
    '1': [],
    '2': [60, 60, 60, 60, 60, 60],
  };
  double animatedMuscle = 0;
  double animatedWeight = 0;
  double animatedHeight = 0;

  //
  //
  //
  void _animateValue(double targetMuscle, double targetWeight, double targetHeight) {
    const int steps = 10; // 애니메이션 프레임 수
    int currentStep = 0;

    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      currentStep++;

      setState(() {
        animatedMuscle = (targetMuscle * (currentStep / steps));
        animatedWeight = (targetWeight * (currentStep / steps));
        animatedHeight = (targetHeight * (currentStep / steps));
      });

      if (currentStep >= steps) {
        timer.cancel();
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      ApiServiceFast apiService = ApiServiceFast();
      userHealthData = (await apiService.selectUserHealth(userId.toString()))['result'];
      print(userHealthData);

      _animateValue(
        userHealthData['근육량']?.elementAt(0) ?? 0,
        userHealthData['몸무게']?.elementAt(0) ?? 0,
        userHealthData['키']?.elementAt(0) ?? 0,
      );
      for (int i = 0; i < _radarNames.length; i++) {
        int grade = userHealthData[_radarNames[i]]?[4] ?? 5;
        if (grade == 0) {
          grade = 5;
        }
        double value = (6 - (grade)) * 20;
        _radarValues['1']?.add(value);
      }
      _isLoading = false;
      setState(() {});
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

//
//
//
//
//
//
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFF3F3F3),
      appBar: const Header(),
      drawer: const CustomDrawer(isLogin: true),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(children: [
                Container(
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: _content_radar(context, widget, _radarNames, _radarValues, userHealthData)),
                SizedBox(height: 20),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black87, width: 1.6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HisHealth(),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '나의 건강정보 이력',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 25),
                        dataRow('신체질량지수(BMI)', userHealthData, -1),
                        dataRow('체지방률', userHealthData, -1),
                        dataRow('근육량', userHealthData, 1),
                        dataRow('앉았다 일어서기', userHealthData, 1),
                        dataRow('걷기', userHealthData, 1),
                        dataRow('악력', userHealthData, 1),
                        SizedBox(height: 25),
                      ]),
                    )),
                SizedBox(height: 50),
              ]),
            ),
    );
  }

//
//
//
  Widget _content_radar(context, widget, List<String> _radarNames, Map _radarValues, Map userHealthData) {
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
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectMeasureDevice(),
                          /*ScreenHealthInfoInput(
                            healthData: widget.healthData,
                            healthInfoItemsFuture: widget.healthInfoItemsFuture,
                            userId: widget.userId,
                            initializeData: widget.initializeData,
                            msmtItemData: widget.msmtItemData,
                          ),*/
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      fixedSize: Size(width * 0.7, 50),
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
                        Icon(Icons.bluetooth, color: Color(0xFF92D2B0), size: 20),
                        SizedBox(width: 6),
                        Text('건강정보 측정하기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF92D2B0))),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(width: 320, child: Divider(color: Colors.white.withOpacity(0.15), thickness: 2)), //divider
              SizedBox(height: 32),

              // 하단: Radar
              SizedBox(
                height: 350 * 0.8 + 10,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    //['체질량지수', '체지방률', '근육량', '앉았다 일어나기(횟수)', '걷기(m/sec)', '악력(kg)'];
                    CustomRadarChart(
                      features: _radarNames,
                      data: _radarValues['1'],
                      sides: _radarNames.length,
                      graphColors: [Colors.green],
                      ticks: [20, 40, 60, 80, 100],
                      size: 350 * 0.85,
                    ),
                    CustomRadarChart(
                      features: _radarNames,
                      data: _radarValues['2'],
                      sides: _radarNames.length,
                      graphColors: [Colors.orangeAccent],
                      ticks: [20, 40, 60, 80, 100],
                      size: 350 * 0.85,
                    ),
                    Transform.translate(
                      offset: const Offset(-130, -10),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 30, height: 3, color: Colors.orangeAccent),
                              const SizedBox(width: 6),
                              const Text('목표', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 30, height: 3, color: Colors.green), // 텍스트와 막대 간격
                              const SizedBox(width: 6),
                              const Text('현재', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22),
              Container(
                width: 312,
                child: Divider(color: Colors.white.withOpacity(0.15), thickness: 2),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 38.0, top: 12.0, bottom: 24.0, right: 12.0),
                    child: _buildHealthMetric('키', animatedHeight, 'cm'),
                  ),
                  Container(
                    height: 74,
                    child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1, width: 1),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 24.0, right: 12.0),
                    child: _buildHealthMetric('몸무게', animatedWeight, 'kg'),
                  ),
                  Container(
                    height: 74,
                    child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1, width: 1),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 24.0, right: 38.0),
                    child: _buildHealthMetric('근육량', animatedMuscle, 'kg'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//
//
//
Widget dataRow(String name, Map healthData, int direction) {
  int grade = healthData[name]?[4] ?? 5;
  if (grade == 0) grade = 5;

  double value = healthData[name]?.elementAt(0) ?? 0;
  double progress = 0.2;
  if (direction == 1) progress = (6 - grade) / 5;
  if (direction == -1) progress = grade / 5;

  String label = '${name} (${healthData[name]?.elementAt(3) ?? 0})';
  String state = '평균';

  Color color = Colors.greenAccent;
  if (progress < 0.33) {
    color = Colors.blueGrey.withOpacity(0.7);
    state = '낮음';
  } else if (0.66 <= progress) {
    if (direction == -1) color = Colors.orangeAccent;
    state = '높음';
  }
  if (0.85 <= progress) {
    state = '매우 높음';
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이름 + 수치
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // 애니메이션으로 차오르는 부분
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, animatedValue, child) {
                return FractionallySizedBox(
                  widthFactor: animatedValue,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              },
            ),

            // 3등분 구분선
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(child: SizedBox()),
                  SizedBox(height: 25, child: VerticalDivider(color: Colors.white, thickness: 1, width: 2)),
                  Expanded(child: SizedBox()),
                  SizedBox(height: 25, child: VerticalDivider(color: Colors.white, thickness: 1, width: 2)),
                  Expanded(child: SizedBox()),
                ],
              ),
            ),

            // 상태 텍스트
            Positioned.fill(
              child: Center(
                child: Text(
                  state,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
          ],
        )
      ],
    ),
  );
}

// 건강 정보 지표를 위한 새로운 위젯
Widget _buildHealthMetric(String label, double value, String unit) {
  return Column(
    children: [
      Text(label, style: TextStyle(fontSize: 15, color: Color(0xFFFFFF).withOpacity(0.8))), //이름
      SizedBox(height: 2),
      Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)), //값
      SizedBox(height: 2),
      Text(unit, style: TextStyle(fontSize: 15, color: Color(0xFFFFFF).withOpacity(0.8))), //단위
    ],
  );
}
