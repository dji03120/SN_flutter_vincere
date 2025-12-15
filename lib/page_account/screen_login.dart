import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:Vincere/utils/export/screens.dart';
import 'package:Vincere/page_account/screen_find_account.dart';
import 'package:Vincere/page_home/splash_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();

  // 로그인 처리
  Future<void> _login(BuildContext context) async {
    final id = idController.text;
    final password = pwController.text;

    ApiService apiService = ApiService();
    Map<String, dynamic> result = await apiService.fetchUserLogin(id, password);

    if (result['result'] == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', id);
      await prefs.setString('password', password);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashPage()),
      );
    } else {
      showSnackBar(
        context,
        const Text('로그인 실패: 아이디 또는 비밀번호가 잘못되었습니다.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 웹 최초 로딩 height = 0 방어
          if (constraints.maxHeight == 0) {
            return const SizedBox();
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 112),

                      /// 로고
                      SizedBox(width: 216, height: 50, child: SvgPicture.asset('assets/images/logo.svg', fit: BoxFit.contain)),
                      const SizedBox(height: 60),

                      /// 입력 폼
                      Theme(
                        data: ThemeData(
                          primaryColor: Colors.white,
                          inputDecorationTheme: const InputDecorationTheme(labelStyle: TextStyle(color: Colors.teal, fontSize: 15.0)),
                        ),
                        child: Column(
                          children: [
                            /// 아이디
                            _inputBox(
                              child: TextField(
                                controller: idController,
                                autofocus: false, // 웹 안정화
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: '아이디',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                                  hintStyle: TextStyle(fontSize: 16, fontFamily: 'NotoSansKR', fontWeight: FontWeight.w600, color: Color(0xFF8D8D8D)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// 비밀번호
                            _inputBox(
                              child: TextField(
                                controller: pwController,
                                obscureText: true,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: '비밀번호',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                                  hintStyle: TextStyle(fontSize: 16, fontFamily: 'NotoSansKR', fontWeight: FontWeight.w600, color: Color(0xFF8D8D8D)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 60),

                            /// 로그인 버튼
                            SizedBox(
                              width: 300,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => _login(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                            ),

                            const SizedBox(height: 54),

                            /// 아이디/비밀번호 문의
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _linkText('아이디 문의하기', () => Navigator.push(context, MaterialPageRoute(builder: (_) => FindId()))),
                                const SizedBox(width: 10),
                                Container(width: 1, height: 13, color: const Color(0xFF8D8D8D)),
                                const SizedBox(width: 10),
                                _linkText('비밀번호 문의하기', () => Navigator.push(context, MaterialPageRoute(builder: (_) => FindPswd()))),
                              ],
                            ),

                            const SizedBox(height: 40),

                            /// 회원가입
                            RichText(
                              text: TextSpan(
                                text: '계정이 없으신가요? ',
                                style: const TextStyle(color: Color(0xFF555555), fontSize: 15, fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(
                                    text: '회원가입하기',
                                    style: const TextStyle(color: Color(0xFF00914B), fontWeight: FontWeight.w600),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SingUpScreen()));
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 입력 박스 공통 위젯
  Widget _inputBox({required Widget child}) {
    return Container(
      width: 300,
      height: 53,
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEDEDED)), borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }

  /// 링크 텍스트
  Widget _linkText(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF8D8D8D))),
    );
  }
}

/// 스낵바
void showSnackBar(BuildContext context, Text text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: text, backgroundColor: const Color.fromARGB(255, 112, 48, 48)),
  );
}
