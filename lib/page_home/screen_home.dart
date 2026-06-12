import 'dart:math';

import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/page_home/screen_home_widgets.dart';
import 'package:Vincere/services/page_health/screen_my_health_info.dart';
import 'package:Vincere/page_account/screen_my_page.dart';
import 'package:Vincere/services/page_consult/screen_newsboard_list.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:flutter/services.dart';

import 'package:Vincere/utils/export/screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

//
//
//
class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//
//
//
class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabSelectedIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);

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
      if (userModel.isLogin == true) {
        await userModel.set_user_info();
      }

      await sendCommandElexir(userModel.writeChar, elexir_commands["stop"]!);
      await sendCommandElexir(userModel.writeChar, fitrus_hand_commands["bfp_stop"]!);
      await sendCommandElexir(userModel.writeChar, fitrus_hand_commands["spo2_stop"]!);
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
    UserModel userModel = Provider.of<UserModel>(context); // 상태 접근
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: userModel.isLogin),
      body: _tabSelectedIndex == 0
          ? ScrollConfiguration(
              behavior: DesktopDragScrollBehavior(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ProfileCard(userModel: userModel),
                    SizedBox(height: 10),
                    ProfileMuscleCard(userModel: userModel),
                    SizedBox(height: 50),
                    pageViewContents(),
                    SizedBox(height: 60),
                  ],
                ),
              ),
            )
          : _tabSelectedIndex == 1
              // ? userInfoContainer(context, userData)
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
          //if (_tabSelectedIndex == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const NewsBoard()));
        },
        tabs: <Widget>[
          Tab(icon: Icon(Icons.home, color: _tabSelectedIndex == 0 ? Color(0xFF007130) : Colors.grey), text: "홈"),
          Tab(icon: Icon(Icons.person, color: _tabSelectedIndex == 1 ? Color(0xFF007130) : Colors.grey), text: "마이페이지"),
          Tab(icon: Icon(Icons.article, color: _tabSelectedIndex == 2 ? Color(0xFF007130) : Colors.grey), text: "건강뉴스"),
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

  Widget pageViewContents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // ← 왼쪽 정렬
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(32, 0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("빈체레가 제안하는 개인 맞춤", style: TextStyle(fontSize: 16)),
              Text("골든케어 솔루션", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        SizedBox(height: 4),
        SizedBox(
          height: 400,
          child: PageView(
            controller: _pageController,
            children: [
              contentsCardPlate(context),
              contentsCardActive(context),
            ],
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: SmoothPageIndicator(
            controller: _pageController,
            count: 2,
            effect: WormEffect(dotColor: Colors.grey.shade300, activeDotColor: Colors.orangeAccent, dotHeight: 15, dotWidth: 15),
          ),
        ),
      ],
    );
  }
}
