import 'dart:math';

import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/page_home/screen_home_widgets.dart';
import 'package:Vincere/page_account/screen_my_page.dart';
import 'package:Vincere/services/page_consult/screen_newsboard_list.dart';
import 'package:Vincere/services/page_nutrition/screen_plate_widgets.dart';
import 'package:Vincere/services/page_workout/page_statistics.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/component/mission_card.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
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
  final List<Map<String, dynamic>> missionList = [];
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

      final userModel = Provider.of<UserModel>(context, listen: false);
      var daliyPlan = userModel.userHealthData?['daliyWorkoutPlan']['items'];
      for (int i = 0; i < daliyPlan.length; i++) {
        missionList.add({'title': daliyPlan[i]['title'], 'detail': "${daliyPlan[i]['value']} ${daliyPlan[i]['unit']}", 'complete': false});
      }
      print(missionList);

      final workoutModel = Provider.of<WorkoutModel>(context, listen: false);
      await sendCommandElexir(workoutModel.writeChar, elexir_commands["stop"]!);

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

  // demo progress
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
              DailyMissionCard(title: '오늘의 운동 목표', missionList: missionList),
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
