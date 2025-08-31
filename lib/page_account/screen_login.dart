import 'package:Vincere/provider_models.dart';
import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/export/screens.dart';
import 'package:Vincere/page_account/screen_find_id.dart';
import 'package:Vincere/page_account/screen_find_pswd.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider, Provider;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController pwController = TextEditingController();
  bool _isObscure = true;

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

      // 메인 페이지 이동 ( screen_home.dart )
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MyHomePage(title: "vincere_App"),
        ),
      );
    } else {
      // 로그인 실패 알림
      showSnackBar(context, const Text('로그인 실패: 아이디 또는 비밀번호가 잘못되었습니다.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // email, password 입력하는 부분을 제외한 화면을 탭하면, 키보드 사라지게 GestureDetector 사용
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 112),
              Image.asset(
                'images/Vincere_logo.png',
                width: 180,
                height: 42,
              ),
              const SizedBox(height: 30),
              Form(
                  child: Theme(
                data: ThemeData(primaryColor: Colors.white, inputDecorationTheme: const InputDecorationTheme(labelStyle: TextStyle(color: Colors.teal, fontSize: 15.0))),
                child: Container(child: Builder(builder: (context) {
                  return Column(
                    children: [
                      Container(
                        width: 300,
                        height: 53,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEDEDED)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: idController,
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                          decoration: const InputDecoration(
                            hintText: '아이디',
                            hintStyle: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontSize: 16,
                              fontWeight: FontWeight.w600, // semibold
                              color: const Color(0xFF8D8D8D),
                            ),
                            border: InputBorder.none, // 기본 border 제거
                            contentPadding: EdgeInsets.symmetric(horizontal: 20),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 300,
                        height: 53,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEDEDED)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: pwController,
                          obscureText: true, // 비밀번호 입력 시 텍스트 가림
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF000000), // 입력된 텍스트 색상
                          ),
                          decoration: const InputDecoration(
                            hintText: '비밀번호',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w600, // semibold
                              color: Color(0xFF8D8D8D), // 힌트 텍스트 색상
                            ),
                            border: InputBorder.none, // 기본 보더 제거
                            contentPadding: EdgeInsets.symmetric(horizontal: 20), // 좌우 패딩 설정
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: 300,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _login(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text('로그인', style: const TextStyle(fontFamily: 'NotoSansKR', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 54),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FindId()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: '아이디 ',
                                style: TextStyle(
                                  fontFamily: 'NotoSansKR',
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8D8D8D),
                                ),
                                children: [
                                  TextSpan(
                                    text: '문의하기',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 13, // 선의 높이
                            color: Color(0xFF8D8D8D), // 선 색상 (#8D8D8D)
                          ),
                          const SizedBox(width: 10), // 선과 다음 텍스트 간격
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FindPswd()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: '비밀번호 ', // '비밀번호' 텍스트
                                style: TextStyle(
                                  fontFamily: 'NotoSansKR',
                                  fontSize: 15.0, // 글자 크기
                                  fontWeight: FontWeight.w600, // 굵기 w600
                                  color: Color(0xFF8D8D8D),
                                ),
                                children: [
                                  TextSpan(
                                    text: '문의하기', // '문의하기' 텍스트
                                    style: TextStyle(
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w500, // 굵기 w500
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 40.0,
                      ),
                      RichText(
                        textAlign: TextAlign.center, // 텍스트 중앙 정렬
                        text: TextSpan(
                          text: '계정이 없으신가요? ', // 첫 번째 텍스트
                          style: const TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontSize: 15.0, // 글자 크기
                            fontWeight: FontWeight.w600, // semibold
                            color: Color(0xFF555555), // #555555 색상
                          ),
                          children: [
                            TextSpan(
                              text: '회원가입하기', // 링크 텍스트
                              style: const TextStyle(
                                fontFamily: 'NotoSansKR',
                                fontSize: 15.0, // 글자 크기
                                fontWeight: FontWeight.w600, // semibold
                                color: Color(0xFF00914B), // #00914B 색상
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SingUpScreen(), // 회원가입 화면으로 이동
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 90),
                    ],
                  );
                })),
              ))
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}

// 사용자 알림용
void showSnackBar(BuildContext context, Text text) {
  final snackBar = SnackBar(
    content: text,
    backgroundColor: const Color.fromARGB(255, 112, 48, 48),
  );

// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// 페이지 이동
class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
