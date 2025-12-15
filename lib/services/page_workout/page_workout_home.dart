import 'dart:math';

import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/page_home/screen_home_widgets.dart';
import 'package:Vincere/page_account/screen_my_page.dart';
import 'package:Vincere/services/page_notice/screen_newsboard_list.dart';
import 'package:Vincere/services/page_nutrition/screen_plate_widgets.dart';
import 'package:Vincere/services/page_workout/page_statistics.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/page_ble_device/ble_utils.dart';
import 'package:Vincere/utils/page_ble_device/page_connect_elexir.dart';
import 'package:flutter/services.dart';

import 'package:Vincere/utils/export/screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

//
//
//
class MyWorkoutPage extends StatefulWidget {
  const MyWorkoutPage({super.key});

  @override
  State<MyWorkoutPage> createState() => _MyWorkoutPage();
}

//
//
//
class _MyWorkoutPage extends State<MyWorkoutPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabSelectedIndex = 0;
  final List<Map<String, dynamic>> missionList = [
    {"title": "걸음수", "detail": "0 / 8000", "complete": false},
    {"title": "근력 운동", "detail": "0 / 20분", "complete": false},
    {"title": "물 마시기", "detail": "3 / 8컵", "complete": false},
    {"title": "스트레칭", "detail": "0 / 10분", "complete": false},
    {"title": "코어 운동", "detail": "0 / 15분", "complete": false},
  ];
  bool isExpanded = false;
  //
  //
  //
  @override
  void initState() {
    super.initState();
    _initializeData();
    setState(() {});
  }

  Future<void> _initializeData() async {
    try {
      _tabController = TabController(length: 3, vsync: this);
      _tabController.addListener(() => setState(() => _tabSelectedIndex = _tabController.index));

      final workoutModel = Provider.of<WorkoutModel>(context, listen: false);
      await sendCommandElexir(workoutModel.writeChar, elexir_commands["stop"]!);
      print("initialize user done");
      setState(() {});
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  //
  //
  //
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //
  //
  //
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    UserModel userModel = Provider.of<UserModel>(context); // 상태 접근
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: userModel.isLogin),
      body: _tabSelectedIndex == 0
          ? SingleChildScrollView(
              child: Column(children: [
              ProfileCard(userModel: userModel),
              SizedBox(height: 20),
              DailyMission(),
              SizedBox(height: 40),
              ExerciseSection(),
            ]))
          : _tabSelectedIndex == 1
              ? MyPage(
                  userData: userModel.userInfo,
                  onProfileImageChange: updateProfileImage,
                  onActivityLevelChange: updateActivityLevl,
                )
              : const NewsBoard(),
      //
      //
      //
      bottomNavigationBar: TabBar(
        indicatorColor: Colors.transparent,
        labelColor: Colors.black,
        controller: _tabController,
        onTap: (index) {
          if (_tabSelectedIndex == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MyHomePage(title: "vincere_App"),
              ),
            );
          }
        },
        tabs: <Widget>[
          Tab(icon: _tabSelectedIndex == 0 ? Image.asset('images/nav_home.png', width: 24, height: 24) : Image.asset('images/nav_home_off.png', width: 24, height: 24), text: "홈"),
          Tab(icon: _tabSelectedIndex == 1 ? Image.asset('images/nav_my.png', width: 24, height: 24) : Image.asset('images/nav_my_off.png', width: 24, height: 24), text: "마이페이지"),
          Tab(icon: _tabSelectedIndex == 2 ? Image.asset('images/nav_news.png', width: 24, height: 24) : Image.asset('images/nav_news_off.png', width: 24, height: 24), text: "건강뉴스"),
        ],
      ),
    );
  }

  //
  //
  //
  //
  //
  //
  //
  //
  Widget DailyMission() {
    return Container(
        child: Card(
            elevation: 6,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(Icons.flag, color: Colors.green, size: 30),
                        SizedBox(width: 20),
                        Text("오늘의 운동 목표", style: TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 20),
                    ClipRect(
                        child: AnimatedSize(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Column(
                                children: List.generate(
                                    isExpanded ? missionList.length : 3,
                                    (i) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: _buildMissionItem(
                                          title: missionList[i]["title"],
                                          detail: missionList[i]["detail"],
                                          completed: missionList[i]['complete'],
                                          onTap: () {
                                            setState(() {
                                              missionList[i]['complete'] = !missionList[i]['complete'];
                                            });
                                          },
                                        ))))))
                  ])),
              InkWell(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[800], size: 32),
                      )))
            ])));
  }

  Widget _buildMissionItem({
    required String title,
    required String detail,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[50],
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 6,
              height: 72,
              decoration: BoxDecoration(
                color: completed ? Colors.green : Colors.grey.shade300,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            SizedBox(width: 14),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed ? Colors.green : Colors.white,
                        border: Border.all(color: completed ? Colors.green : Colors.grey, width: 2),
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: completed ? Icon(Icons.check, key: ValueKey(true), color: Colors.white, size: 18) : SizedBox(key: ValueKey(false)),
                      )),
                  SizedBox(width: 15),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text(detail, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                  ])
                ])),
            Spacer(),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: completed ? Icon(Icons.check_circle, key: ValueKey("on"), color: Colors.green) : Icon(Icons.radio_button_unchecked, key: ValueKey("off"), color: Colors.blueGrey),
            ),
            SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  //
  //
  //
  //
  //
  //
  //
  //
  Widget ExerciseSection() {
    UserModel userModel = Provider.of<UserModel>(context); // 상태 접근
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        Container(
            margin: const EdgeInsets.only(left: 16, right: 16),
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.centerLeft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '${userModel.userInfo?["userNm"] ?? ""}', style: TextStyle(fontSize: 17, color: Colors.green, fontWeight: FontWeight.w600)),
                TextSpan(text: ' 님의', style: TextStyle(fontSize: 17, color: Colors.black)),
              ])),
              Text("운동등급에 따른 운동추천", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
            ])),
        Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                    flex: 1,
                    child: Card(
                        elevation: 6,
                        color: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('헬스케어 \n장치 연동', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                              SizedBox(height: screenHeight * 0.03),
                              HomeScreenButton(
                                text: '장치 연결',
                                width: double.infinity,
                                onPressed: () async {
                                  await userModel.set_login_data();
                                  userModel.set_user_info();
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => PageConnectBle()));
                                },
                              )
                            ])))),
                //const SizedBox(width: 1),
                Expanded(
                    flex: 1,
                    child: Card(
                        elevation: 6,
                        color: Colors.lightGreen[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('운동 이력\n', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                              SizedBox(height: screenHeight * 0.03),
                              HomeScreenButton(
                                  text: '통계 보기',
                                  width: double.infinity,
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsPage()));
                                  })
                            ]))))
              ],
            )),
      ],
    );
  }

  //
  //
  //
  //
  //
  //
  //
  //
  String currentActivityLevel = "LOW";
  void updateActivityLevl(String? actLevl) {
    final userModel = Provider.of<UserModel>(context, listen: false);
    setState(() {
      userModel.userInfo?["activityLevel"] = actLevl;
    });
  }

  void updateProfileImage(String? url) {
    final userModel = Provider.of<UserModel>(context, listen: false);
    userModel.set_user_info();
    setState(() {});
  }
}
