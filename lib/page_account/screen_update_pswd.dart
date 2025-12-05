import 'package:Vincere/export/screens.dart';
import 'package:Vincere/http/webReqSpring.dart';
import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePswd extends StatefulWidget {
  const UpdatePswd({Key? key}) : super(key: key);

  @override
  _UpdatePswdState createState() => _UpdatePswdState();
}

class _UpdatePswdState extends State<UpdatePswd> {
  // 컨트롤러 선언
  TextEditingController currentPswdCon = TextEditingController();
  TextEditingController newPswdCon = TextEditingController();
  TextEditingController confirmPswdCon = TextEditingController();

  // 사용자 ID
  String? userId;
  String? password;
  bool _isLogIn = false;

  bool isCurrentPswdError = false;
  bool isNewPswdError = false;
  bool isConfirmPswdError = false;
  bool isConfirmPswdMatchError = false;

  @override
  // ignore: must_call_super
  void initState() {
    _loadSessionData().then((_) {
      if (_isLogIn) {
        _loadUserId();
      }
    });
  }

  // 세션에서 userId와 password 불러오기
  Future<void> _loadSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      password = prefs.getString('password');
      if (userId != null && password != null) {
        _isLogIn = true;
      }
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId'); // SharedPreferences에서 userId 가져오기
    });
  }

  InputDecoration getInputDecoration(String hint, {bool isError = false}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      hintStyle: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 16, fontWeight: FontWeight.w400),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: isError ? Color(0xFFAA4743) : const Color(0xFFEDEDED),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: isError ? Color(0xFFAA4743) : const Color(0xFFEDEDED),
          width: 1.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(
          color: Color(0xFFAA4743),
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(
          color: Color(0xFFAA4743),
          width: 1.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    );
  }

  void _validateAndSave() async {
    setState(() {
      isCurrentPswdError = currentPswdCon.text.isEmpty;
      isNewPswdError = newPswdCon.text.isEmpty;
      isConfirmPswdError = confirmPswdCon.text.isEmpty;
      isConfirmPswdMatchError = newPswdCon.text != confirmPswdCon.text;
    });

    if (isCurrentPswdError || isNewPswdError || isConfirmPswdError || isConfirmPswdMatchError) {
      return;
    }

    try {
      final response = await ApiService().fetchUpdatePassWd({
        'userId': userId!,
        'currentPassWd': currentPswdCon.text,
        'newPassWd': newPswdCon.text,
      });

      if (response['result'] == true || response['result'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Color(0xFFAA4743),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 비밀번호가 일치하지 않습니다.'),
          backgroundColor: Color(0xFFAA4743),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: _isLogIn),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              const Text(
                '비밀번호 재설정',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),

              // 기존 비밀번호 입력
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '기존 비밀번호',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrentPswdError)
                        const Text(
                          '기존 비밀번호를 입력해 주세요',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFAA4743),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8), // 라벨과 필드 간 간격
                  TextFormField(
                    controller: currentPswdCon,
                    obscureText: true,
                    decoration: getInputDecoration(
                      '기존 비밀번호를 입력하세요',
                      isError: isCurrentPswdError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 새 비밀번호 입력
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '비밀번호',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isNewPswdError)
                        const Text(
                          '비밀번호를 입력해 주세요',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFAA4743),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8), // 라벨과 필드 간 간격
                  TextFormField(
                    controller: newPswdCon,
                    obscureText: true,
                    decoration: getInputDecoration(
                      '새 비밀번호를 입력하세요',
                      isError: isNewPswdError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // 비밀번호 재확인 입력
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '비밀번호 확인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isConfirmPswdError)
                        const Text(
                          '비밀번호를 다시 한 번 입력해 주세요',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFAA4743),
                          ),
                        ),
                      if (!isConfirmPswdError && isConfirmPswdMatchError)
                        const Text(
                          '비밀번호가 일치하지 않습니다',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFAA4743),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8), // 라벨과 필드 간 간격
                  TextFormField(
                    controller: confirmPswdCon,
                    obscureText: true,
                    decoration: getInputDecoration(
                      '비밀번호 재확인',
                      isError: isConfirmPswdError || isConfirmPswdMatchError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
              // 저장 버튼
              SizedBox(
                width: double.infinity, // 버튼이 부모 너비에 맞게 확장됨
                height: 56, // 버튼 높이 설정
                child: ElevatedButton(
                  onPressed: _validateAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007130),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0), // 버튼 모서리 둥글게
                    ),
                  ),
                  child: const Text(
                    '비밀번호 변경',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
