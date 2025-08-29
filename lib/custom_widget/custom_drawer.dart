import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/account/screen_update_pswd.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Vincere/export/screens.dart';
import '../screen/screen_newsboard_list.dart';

class CustomDrawer extends StatefulWidget {
  final bool isLogin;
  final String? userId;

  const CustomDrawer({Key? key, required this.isLogin, this.userId})
      : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? userNm; // 사용자 이름 상태 변수
  String? userId;
  Map<String, dynamic>? userData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserName(); // 사용자 이름 불러오기
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    userNm = prefs.getString('userNm');

    if (userId != null) {
      await _getUserInfo();
    }

    setState(() {
      isLoading = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: 300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // BorderRadius 제거
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // DrawerHeader 대신 Container 사용
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24), // 원하는 패딩 적용
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 정렬
              children: [
                Image.asset(
                  'images/top_logo.png',
                  width: 128,
                  height: 20,
                  fit: BoxFit.contain, // 로고 비율 유지
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Drawer 닫기
                  },
                  child: Image.asset(
                    'images/close.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain, // close 아이콘 비율 유지
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isLogin
                      ? '${userNm ?? "사용자"}님, 환영합니다.'
                      : '로그인이 필요합니다.',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12), // 문구와 버튼 사이 여백
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (widget.isLogin) {
                          _showLogoutDialog(context);
                        } else {
                          // 로그인 화면으로 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // 버튼 배경색
                        side: const BorderSide(
                            color: Color(0xFFEDEDED), width: 1), // 테두리 설정
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                        ),
                        shadowColor: Colors.transparent, // 그림자 제거
                        fixedSize: const Size(76, 32), // 버튼 크기 설정
                        padding: EdgeInsets.zero, // 내부 여백 제거 (크기 고정에 필요)
                      ),
                      child: Text(
                        widget.isLogin ? '로그아웃' : '로그인', // 상태에 따른 텍스트
                        style: const TextStyle(
                            color: Color(0xFF555555), // 텍스트 색상
                            fontSize: 14,
                            fontWeight: FontWeight.w600 // 텍스트 크기
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          Divider(
            color: const Color(0xFFEDEDED),
            thickness: 1,
            height: 1,
          ),
          SizedBox(height: 30),
          _buildListTile(
              context, '홈으로', const MyHomePage(title: "vincere_App")),
          _buildListTileUser(
              context, '나의 건강 정보 이력', const HisHealth(), widget.isLogin),
          _buildListTileUser(context, 'Q&A', const Qna(), widget.isLogin),
          _buildListTileUser(
              context, '정보 및 기사', const NewsBoard(), widget.isLogin),
          _buildListTileUser(
              context, '비밀번호 재설정', const UpdatePswd(), widget.isLogin),
        ],
      ),
    );
  }

  static Future<void> _logout(BuildContext context) async {
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
                _logout(context); // 로그아웃 처리
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

  ListTile _buildListTile(BuildContext context, String title, Widget screen) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20), // 좌우 패딩 제거
      visualDensity:
          const VisualDensity(horizontal: 0, vertical: -4), // 상하 패딩 제거
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF555555), // 글씨 색상 #555555
          fontWeight: FontWeight.w500, // 글씨 두께 w500
          fontSize: 18, // 글씨 크기 18px
        ),
      ),
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      },
    );
  }

  ListTile _buildListTileUser(
      BuildContext context, String title, Widget screen, bool loginYn) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      visualDensity:
          const VisualDensity(horizontal: 0, vertical: -4), // 상하 패딩 제거
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF555555), // 글씨 색상 #555555
          fontWeight: FontWeight.w500, // 글씨 두께 w500
          fontSize: 18, // 글씨 크기 18px
        ),
      ),
      onTap: () {
        if (loginYn) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => screen));
        } else {
          _showLoginPrompt(context);
        }
      },
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용 불가'),
        content: const Text('로그인을 하셔야 이용 가능합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
            child: const Text('로그인 하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}
