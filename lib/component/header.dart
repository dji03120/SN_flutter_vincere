import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Vincere/export/screens.dart';

import '../http/webReq.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  _HeaderState createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderState extends State<Header> {
  String? userId;
  String? password;
  Map<String, dynamic>? userData;
  String? userNm;
  bool _isLogin = false;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      print("prefs >>> ${prefs.getString('userNm')}");
      userId = prefs.getString('userId');
      password = prefs.getString('password');
      if (userId != null && password != null) {
        _isLogin = true;
        _getUserInfo();
      }
    });
  }

  // 회원 정보 가져오기
  Future<void> _getUserInfo() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result =
          await apiService.fetchGetUserInfo(userId.toString());

      setState(() {
        userData = result["userOne"];
        userNm = userData?["userNm"] ?? "";
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  static Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('password');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃 하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // '예'를 선택하면 먼저 알림창을 닫음
                logout(context); // 로그아웃 처리
              },
              child: const Text('예'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // '아니오'를 선택하면 알림창만 닫힘
              },
              child: const Text('아니오'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0, // 스크롤 시 elevation 변화 제거
      surfaceTintColor: Colors.transparent, // surface tint 효과 제거
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // 첫 번째 행: 로고와 이름
          Row(
            children: [
              Image.asset(
                'images/top_logo.png',
                // width: 118,
                // height: 18,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 두 번째 행: 환영 메시지
          if (userId != null)
            Text(
              '안녕하세요. ${userNm}님',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
      centerTitle: false,
      actions: [
        // 로그인/로그아웃 버튼
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: SizedBox(
            width: 70,
            height: 28,
            child: OutlinedButton(
              onPressed: userId != null
                  ? () => _showLogoutDialog(context)
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDEDEDE)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                userId != null ? '로그아웃' : '로그인',
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
