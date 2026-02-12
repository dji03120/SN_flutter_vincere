import 'dart:async';

import 'package:Vincere/services/page_health/insight_card.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/radar_chart.dart';
import 'package:Vincere/utils/export/screens.dart';
import 'package:Vincere/page_home/screen_home_widgets.dart';
import 'package:Vincere/services/page_ble_device/page_select_device.dart';
import 'package:Vincere/provider_models.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ScreenHealthInfo extends StatefulWidget {
  const ScreenHealthInfo({super.key});

  @override
  State<ScreenHealthInfo> createState() => _ScreenHealthInfo();
}

//
//
class _ScreenHealthInfo extends State<ScreenHealthInfo> {
  Map userHealthData = {};
  Map userGradeList = {};
  Map userInfo = {};
  bool _isLoading = true;
  // 예시 데이터
  final List<String> _radarNames = ['걷기', '앉았다 일어서기', '근육', '신체질량지수(BMI)', '체지방률', '악력'];
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
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      setState(() {
        animatedMuscle = (targetMuscle * (currentStep / steps));
        animatedWeight = (targetWeight * (currentStep / steps));
        animatedHeight = (targetHeight * (currentStep / steps));
      });
      if (currentStep >= steps) timer.cancel();
    });
  }

  Future<void> _initializeData() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.set_user_info();
      print(userModel.userHealthData);
      _animateValue(
        userModel.userHealthData?['근육'][0] ?? 0.0,
        userModel.userHealthData?['몸무게'][0] ?? 0.0,
        userModel.userHealthData?['키'][0] ?? 0.0,
      );
      for (int i = 0; i < _radarNames.length; i++) {
        int grade = userModel.userHealthData?[_radarNames[i]][4] ?? 5;
        if (grade == 0) grade = 5;
        double value = (6 - (grade)) * 20;
        _radarValues['1']?.add(value);
      }
      print(_radarValues);
      _isLoading = false;
      if (mounted) setState(() {});
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
    UserModel userModel = Provider.of<UserModel>(context);
    return Scaffold(
      backgroundColor: Color(0xFFF3F3F3),
      appBar: const Header(),
      drawer: const CustomDrawer(isLogin: true),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ScrollConfiguration(
              behavior: DesktopDragScrollBehavior(),
              child: SingleChildScrollView(
                child: Column(children: [
                  Container(
                    decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                    child: _content_radar(context, widget, _radarNames, _radarValues),
                  ),
                  SizedBox(height: 10),
                  ProfileMuscleCard(userModel: userModel),
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: InsightSummaryCard(
                      title: "건강 인사이트",
                      summary: "ex) 체지방률과 BMI가 기준보다 높습니다. 체중 관리 중심의 생활습관 개선이 권장됩니다.",
                      insights: [
                        {
                          "icon": Icons.warning_amber_rounded,
                          "color": Colors.orange,
                          "text": "ex) 체지방률이 기준 대비 높습니다.",
                        },
                        {
                          "icon": Icons.trending_up, //trending_down
                          "color": Colors.green,
                          "text": "ex) 최근 3개월간 근육량이 증가하였습니다.",
                        },
                        {
                          "icon": Icons.directions_walk,
                          "color": Colors.red,
                          "text": "ex) 최근 활동량이 감소하였습니다.",
                        },
                      ],
                      onActionTap: () {
                        // 행동 가이드 페이지 이동
                      },
                    ),
                  ),
                  SizedBox(height: 60),
                  Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: Offset(0, 3))],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => HisHealth()));
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('나의 건강정보 이력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.black),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  SizedBox(height: 25),
                                  Row(children: [
                                    Icon(Icons.person, color: Colors.green, size: 30),
                                    const SizedBox(width: 12),
                                    Text("신체조성", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ]),
                                  Divider(),
                                  SizedBox(height: 10),
                                  dataRow('신체질량지수(BMI)', -1),
                                  dataRow('근육', 1),
                                  dataRow('체지방률', -1),
                                  SizedBox(height: 25),
                                ]),
                              )),
                          SizedBox(height: 20),
                          Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  SizedBox(height: 25),
                                  Row(children: [
                                    Icon(Icons.directions_run, color: Colors.green, size: 30),
                                    const SizedBox(width: 12),
                                    Text("신체기능", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ]),
                                  Divider(),
                                  SizedBox(height: 10),
                                  dataRow('악력', 1),
                                  dataRow('걷기', 1),
                                  dataRow('앉았다 일어서기', 1),
                                  SizedBox(height: 25),
                                ]),
                              )),
                          SizedBox(height: 20),
                          Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  SizedBox(height: 25),
                                  Row(children: [
                                    Icon(Icons.more_horiz, color: Colors.green, size: 30),
                                    const SizedBox(width: 12),
                                    Text("기타 항목", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ]),
                                  Divider(),
                                  SizedBox(height: 10),
                                  dataRow('몸무게', -1),
                                  dataRow('근육량', 1),
                                  dataRow('체지방량', -1),
                                  dataRow('기초대사량', 2),
                                  dataRow('세포내 수분(ICW)', 2),
                                  dataRow('세포외 수분(ECW)', 2),
                                  dataRow('단백질량', 2),
                                  dataRow('무기질량', 2),
                                  SizedBox(height: 25),
                                ]),
                              )),
                          Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  SizedBox(height: 25),
                                  Row(children: [
                                    Icon(Icons.self_improvement, color: Colors.green, size: 30),
                                    const SizedBox(width: 12),
                                    Text("기타 항목", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ]),
                                  Divider(),
                                  SizedBox(height: 10),
                                  dataRow('심박수', 2),
                                  dataRow('혈압(고)', 2),
                                  dataRow('혈압(저)', 2),
                                  dataRow('산소포화도', 2),
                                  dataRow('심박변이도', 2),
                                  dataRow('스트레스지수', 2),
                                  SizedBox(height: 25),
                                ]),
                              )),
                          SizedBox(height: 25),
                        ]),
                      )),
                  SizedBox(height: 60),
                ]),
              ),
            ),
    );
  }

//
//
//
  Widget _content_radar(context, widget, List<String> _radarNames, Map _radarValues) {
    double width = MediaQuery.of(context).size.width;
    //UserModel userModel = Provider.of<UserModel>(context);

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
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SelectMeasureDevice()));
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
              Container(width: 312, child: Divider(color: Colors.white.withOpacity(0.15), thickness: 2)),
              SizedBox(height: 32),

              // 하단: Radar
              SizedBox(
                  height: 350 * 0.7 + 10,
                  child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                    //['체질량지수', '체지방률', '근육', '앉았다 일어나기(횟수)', '걷기(m/sec)', '악력(kg)'];
                    CustomRadarChart(
                      features: _radarNames,
                      data: _radarValues['2'],
                      sides: _radarNames.length,
                      graphColors: [Colors.orangeAccent],
                      ticks: [20, 40, 60, 80, 100],
                      size: 350 * 0.8,
                    ),
                    CustomRadarChart(
                      features: _radarNames,
                      data: _radarValues['1'],
                      sides: _radarNames.length,
                      graphColors: [Colors.green],
                      ticks: [20, 40, 60, 80, 100],
                      size: 350 * 0.8,
                    ),
                    Transform.translate(
                        offset: const Offset(-130, -10),
                        child: Column(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 30, height: 3, color: Colors.orangeAccent),
                              const SizedBox(width: 6),
                              const Text('목표', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ],
                          ),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 30, height: 3, color: Colors.green), // 텍스트와 막대 간격
                            const SizedBox(width: 6),
                            const Text('현재', style: TextStyle(fontSize: 12, color: Colors.white)),
                          ])
                        ]))
                  ])),
              SizedBox(height: 32),
              Container(width: 312, child: Divider(color: Colors.white.withOpacity(0.15), thickness: 2)),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(margin: const EdgeInsets.fromLTRB(38, 12, 12, 24), child: _buildHealthMetric('키', animatedHeight, 'cm')),
                  Container(height: 74, child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1, width: 1)),
                  Container(margin: const EdgeInsets.fromLTRB(12, 12, 12, 24), child: _buildHealthMetric('몸무게', animatedWeight, 'kg')),
                  Container(height: 74, child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1, width: 1)),
                  Container(margin: const EdgeInsets.fromLTRB(12, 12, 38, 24), child: _buildHealthMetric('근육', animatedMuscle, '%')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

//
  Widget dataRow(String name, int direction) {
    UserModel userModel = Provider.of<UserModel>(context);
    int grade = userModel.userHealthData?[name][4] ?? 5;
    double value = userModel.userHealthData?[name][0] ?? 0;
    double progress = 0.2;
    double standard = userModel.userHealthData?[name][5] ?? 0.0;
    double standardDiff = value - standard;

    if (grade == 0) grade = 5;
    if (direction == 1) progress = (6 - grade) / 5;
    if (direction == -1) progress = grade / 5;

    String state = '평균';
    String label = '${name} (${userModel.userHealthData?[name][3] ?? 0})';
    String standardDiffStr = standardDiff.toStringAsFixed(1);
    if (standardDiff >= 0) {
      standardDiffStr = " +$standardDiffStr ▲";
    } else {
      standardDiffStr = " $standardDiffStr ▼";
    }

    Color color = Colors.greenAccent;
    if (progress <= 0.20) {
      color = Colors.blueGrey.withOpacity(0.7);
      state = '매우 낮음';
    } else if (progress <= 0.4) {
      color = Colors.blueGrey.withOpacity(0.7);
      state = '낮음';
    } else if (progress <= 0.6) {
      if (direction == -1) color = Colors.greenAccent;
      state = '보통';
    } else if (progress <= 0.8) {
      if (direction == -1) color = Colors.orangeAccent;
      state = '높음';
    } else {
      if (direction == -1) color = Colors.deepOrange;
      state = '매우 높음';
    }
    if (direction == 2) {
      state = '';
      color = Colors.greenAccent;
      progress = 1;
      standardDiffStr = '-';
    }

    // 화면에 보일 때 애니메이션 시작하도록 상태 변수 추가
    double animatedProgress = 0.0;
    bool hasAnimated = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return VisibilityDetector(
          key: Key("detector_$name"),
          onVisibilityChanged: (info) {
            // 화면에 20% 이상 보이는 순간 애니메이션 시작
            if (info.visibleFraction > 0.2 && !hasAnimated) {
              hasAnimated = true;
              setState(() => animatedProgress = progress);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    AutoSizeText(label, maxLines: 1, minFontSize: 12, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${value.toStringAsFixed(1)}  ",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          TextSpan(
                            text: "($standardDiffStr)",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(height: 45, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: animatedProgress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, animatedValue, child) {
                        return FractionallySizedBox(
                          widthFactor: animatedValue,
                          child: Container(height: 45, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                        );
                      },
                    ),
                    const Positioned.fill(
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: SizedBox()),
                      SizedBox(height: 25, child: VerticalDivider(color: Colors.white, thickness: 1, width: 2)),
                      Expanded(child: SizedBox()),
                      SizedBox(height: 25, child: VerticalDivider(color: Colors.white, thickness: 1, width: 2)),
                      Expanded(child: SizedBox()),
                    ])),
                    Positioned.fill(
                      child: Center(child: Text("$state (${standard.toStringAsFixed(1)})", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black))),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

// 건강 정보 지표를 위한 새로운 위젯
  Widget _buildHealthMetric(String label, double value, String unit) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Color(0xFFFFFF).withOpacity(0.8))), //이름
        SizedBox(height: 2),
        Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)), //값
        SizedBox(height: 2),
        Text(unit, style: TextStyle(fontSize: 15, color: Color(0xFFFFFF).withOpacity(0.8))), //단위
      ],
    );
  }
}
