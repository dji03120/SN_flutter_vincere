// 사용자 로그인 화면과 자동 로그인 이동을 위한 기능

import 'package:Vincere/main.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:Vincere/utils/export/screens.dart';
import 'package:Vincere/page_account/screen_find_account.dart';
import 'package:Vincere/page_home/splash_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 아이디 입력값을 관리하기 위한 기능
  final TextEditingController idController = TextEditingController();

  // 비밀번호 입력값을 관리하기 위한 기능
  final TextEditingController pwController = TextEditingController();

  // 아이디 입력 후 비밀번호 칸으로 포커스를 이동하기 위한 기능
  final FocusNode pwFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 저장된 로그인 정보로 자동 로그인 여부를 확인하기 위한 기능
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // 브라우저에 저장된 로그인 정보를 불러오기 위한 기능
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId') ?? '';
      String password = prefs.getString('password') ?? '';

      // 저장된 로그인 정보가 없을 때 자동 로그인 요청을 중단하기 위한 기능
      if (userId.isEmpty || password.isEmpty) return;

      // 저장된 로그인 정보가 서버에서 유효한지 확인하기 위한 기능
      ApiService apiService = ApiService();
      Map<String, dynamic> result =
          await apiService.fetchUserLogin(userId, password);
      if (!mounted) return;

      // 자동 로그인 성공 시 스플래시 화면으로 이동하기 위한 기능
      if (result['result'] == true) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const SplashPage()));
      }
      setState(() {});
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  // 로그인 처리
  Future<void> _login() async {
    // 로그인 입력값을 API 요청값으로 준비하기 위한 기능
    final id = idController.text;
    final password = pwController.text;

    // 입력한 아이디와 비밀번호로 로그인을 요청하기 위한 기능
    ApiService apiService = ApiService();
    Map<String, dynamic> result = await apiService.fetchUserLogin(id, password);
    if (!mounted) return;

    // 로그인 성공 시 세션 저장과 화면 이동을 처리하기 위한 기능
    if (result['result'] == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', id);
      await prefs.setString('password', password);

      // 브라우저 자동완성 저장 흐름을 완료하기 위한 기능
      TextInput.finishAutofillContext();
      if (!mounted) return;

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SplashPage()));
    } else {
      // 로그인 실패 안내 메시지를 표시하기 위한 기능
      showSnackBar(
        context,
        const Text('로그인 실패: 아이디 또는 비밀번호가 잘못되었습니다.'),
      );
    }
  }

  @override
  void dispose() {
    // 로그인 입력 컨트롤러와 포커스 노드를 정리하기 위한 기능
    idController.dispose();
    pwController.dispose();
    pwFocusNode.dispose();
    super.dispose();
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

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 112),

                    /// 로고
                    SizedBox(
                        width: 216,
                        height: 50,
                        child: SvgPicture.asset('assets/images/logo.svg',
                            fit: BoxFit.contain)),
                    const SizedBox(height: 60),

                    /// 입력 폼
                    Theme(
                      data: ThemeData(
                        primaryColor: Colors.white,
                        inputDecorationTheme: const InputDecorationTheme(
                            labelStyle:
                                TextStyle(color: Colors.teal, fontSize: 15.0)),
                      ),
                      child: AutofillGroup(
                        child: Column(
                          children: [
                            /// 아이디
                            _inputBox(
                              child: TextField(
                                // 아이디 입력값을 화면 상태와 연결하기 위한 기능
                                controller: idController,
                                autofocus: false, // 웹 안정화

                                // 브라우저가 아이디 필드로 인식하도록 하기 위한 기능
                                autofillHints: const [
                                  AutofillHints.username,
                                ],

                                // 모바일 키보드와 웹 입력 형식을 아이디 입력에 맞추기 위한 기능
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,

                                // 아이디 입력 후 엔터 입력 시 비밀번호 칸으로 이동하기 위한 기능
                                onSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(pwFocusNode),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: '아이디',
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 20),
                                  hintStyle: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8D8D8D)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// 비밀번호
                            _inputBox(
                              child: TextField(
                                // 비밀번호 입력값을 화면 상태와 연결하기 위한 기능
                                controller: pwController,

                                // 아이디 입력 후 비밀번호 칸에 포커스를 주기 위한 기능
                                focusNode: pwFocusNode,
                                obscureText: true,

                                // 브라우저가 비밀번호 필드로 인식하도록 하기 위한 기능
                                autofillHints: const [
                                  AutofillHints.password,
                                ],

                                // 모바일 키보드와 웹 입력 완료 동작을 로그인에 맞추기 위한 기능
                                textInputAction: TextInputAction.done,

                                // 비밀번호 입력 후 엔터 입력 시 로그인을 실행하기 위한 기능
                                onSubmitted: (_) => _login(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: '비밀번호',
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 20),
                                  hintStyle: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8D8D8D)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 60),

                            /// 로그인 버튼
                            SizedBox(
                              width: 300,
                              height: 56,
                              child: ElevatedButton(
                                // 로그인 버튼 클릭 시 로그인 요청을 실행하기 위한 기능
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('로그인',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),

                            const SizedBox(height: 54),

                            /// 아이디/비밀번호 문의
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _linkText(
                                    '아이디 문의하기',
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => FindId()))),
                                const SizedBox(width: 10),
                                Container(
                                    width: 1,
                                    height: 13,
                                    color: const Color(0xFF8D8D8D)),
                                const SizedBox(width: 10),
                                _linkText(
                                    '비밀번호 문의하기',
                                    () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => FindPswd()))),
                              ],
                            ),

                            const SizedBox(height: 40),

                            /// 회원가입
                            RichText(
                              text: TextSpan(
                                text: '계정이 없으신가요? ',
                                style: const TextStyle(
                                    color: Color(0xFF555555),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(
                                    text: '회원가입하기',
                                    style: const TextStyle(
                                        color: Color(0xFF00914B),
                                        fontWeight: FontWeight.w600),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const SingUpScreen()));
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 40),
                  ],
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
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEDEDED)),
          borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }

  /// 링크 텍스트
  Widget _linkText(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8D8D8D))),
    );
  }
}

/// 스낵바
void showSnackBar(BuildContext context, Text text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: text, backgroundColor: const Color.fromARGB(255, 112, 48, 48)),
  );
}

Future<void> logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!context.mounted) return;

  UserModel userModel = Provider.of<UserModel>(context, listen: false);
  userModel.reset();
  appRootKey.currentState?.resetProviders();
}
