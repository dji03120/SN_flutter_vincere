import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:Vincere/screen/card_muscle_result.dart';
import 'package:Vincere/page_health/screen_my_health_info.dart';
import 'package:Vincere/page_account/screen_my_page.dart';
import 'package:Vincere/page_notice/screen_newsboard_list.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/screen/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import 'package:Vincere/http/webReqSpring.dart';
import 'package:Vincere/export/screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  Map<String, dynamic>? userData; // 마이페이지 회원 정보

  //
  //
  //
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _tabController = TabController(length: 3, vsync: this);
      _tabController.addListener(() => setState(() => _tabSelectedIndex = _tabController.index));

      final userModel = Provider.of<UserModel>(context, listen: false);
      final workoutModel = Provider.of<WorkoutModel>(context, listen: false);
      await sendCommandElexir(workoutModel.writeChar, elexir_commands["stop"]!);
      userModel.set_login_data();

      if (userModel.isLogin) {
        await userModel.set_user_info();
        setState(() {});
      }
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
    final userModel = Provider.of<UserModel>(context); // 상태 접근

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: userModel.isLogin),
      body: _tabSelectedIndex == 0
          ? SingleChildScrollView(
              child: Column(
                children: [
                  // 상단 제목과 나이
                  _profileCard(),
                  SizedBox(height: 12),
                  MuscleAgeCard(
                    muscleAge: '0',
                    msmt003Grade: 0,
                    msmt008Grade: 0,
                    msmt011Grade: 0,
                    msmt012Grade: 0,
                    msmt013Grade: 0,
                    userId: userModel.userId,
                  ),
                  SizedBox(height: 12),
                  SizedBox(height: 40),
                ],
              ),
            )
          : _tabSelectedIndex == 1
              // ? userInfoContainer(context, userData)
              ? MyPage(
                  userData: userData,
                  onProfileImageChange: updateProfileImage, // 콜백 함수 전달
                  onActivityLevelChange: updateActivityLevl,
                )
              : const Text(''),
      //
      //
      //
      bottomNavigationBar: TabBar(
        indicatorColor: Colors.transparent,
        labelColor: Colors.black,
        controller: _tabController,
        onTap: (index) {
          setState(() {
            if (_tabSelectedIndex == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NewsBoard()));
            }
          });
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
  // 상태 변수 추가 (클래스의 필드로)
  String currentActivityLevel = "LOW";
  void updateActivityLevl(String? actLevl) {
    setState(() {
      userData?["activityLevel"] = actLevl;
    });
  }

  // 건강 정보 지표를 위한 새로운 위젯
  Widget _buildHealthMetric(String label, List<dynamic> data, String code, String unit) {
    String value;
    if (code == 'muscleAmt') {
      value = ((1 * 10).round() / 10).toStringAsFixed(1);
    } else {
      value = data.firstWhere((item) => item['MSMT_ITEM_CD'] == code, orElse: () => {'MSMT_VALUE': '0'})['MSMT_VALUE']?.toString() ?? '0';
      value = ((double.parse(value) * 10).round() / 10.0).toStringAsFixed(1);
    }
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Color(0xFFFFFF).withOpacity(0.8))),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        SizedBox(height: 2),
        Text(unit, style: TextStyle(fontSize: 15, color: Color(0xFFFFFF).withOpacity(0.8))),
      ],
    );
  }

  //
  //
  //

  void updateProfileImage(String? url) {
    final userModel = Provider.of<UserModel>(context, listen: false);
    userModel.set_user_info();
    setState(() {});
  }

  //
  //
  //
  Widget _profileCard() {
    return Column(
      children: [
        Card(
          color: Colors.black87,
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // 상단: 프로필 정보
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: EdgeInsets.all(24.0), // 상하좌우 8픽셀의 여백 추가
                      decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                      child: Center(child: _buildProfileImage()),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24),
                        Row(
                          children: [
                            SizedBox(width: 10),
                            Text(userData?["userNm"] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(width: 15),
                            Text('만 ${calculateAge(userData?["bym"] ?? "정보없음").toString()}세', style: TextStyle(fontSize: 15, color: Colors.white)),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ScreenHealthInfo()));
                          },
                          style: TextButton.styleFrom(
                            fixedSize: Size(186, 40),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF92D2B0), width: 2)),
                          ),
                          child: const Text('내 건강정보 자세히보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF92D2B0))),
                        ),
                      ],
                    ),
                  ],
                ),
                // 하단: 건강 정보 그리드
                Container(width: 312, child: Divider(color: Colors.white.withOpacity(0.15), thickness: 1, height: 10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(margin: const EdgeInsets.fromLTRB(30.0, 24.0, 24.0, 12.0), child: _buildHealthMetric('키', [], 'MSMT_001', 'cm')),
                    Container(height: 74, child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1, width: 1)),
                    Container(margin: EdgeInsets.all(24.0), child: _buildHealthMetric('몸무게', [], 'MSMT_002', 'kg')),
                    Container(height: 74, child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1, width: 1)),
                    Container(margin: const EdgeInsets.fromLTRB(12.0, 24.0, 24.0, 30.0), child: _buildHealthMetric('근육량', [], 'muscleAmt', 'kg')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    Widget defaultAvatar = CircleAvatar(radius: 58, backgroundColor: Colors.grey[300], child: Icon(Icons.person, size: 35, color: Colors.grey[600]));
    return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: userModel.profileImageUrl != null
            ? ClipOval(
                child: Image.network(userModel.profileImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                  return defaultAvatar;
                }, loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                      child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                  ));
                }),
              )
            : defaultAvatar);
  }
}
