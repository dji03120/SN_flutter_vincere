import 'dart:convert';
import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FindId extends StatefulWidget {
  @override
  _FindIdState createState() => _FindIdState();
}

class _FindIdState extends State<FindId> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController userNameCon = TextEditingController();
  TextEditingController contactEmailCon = TextEditingController();
  TextEditingController contactPhoneCon = TextEditingController();

  // 에러 상태를 추적하기 위한 Map
  Map<String, bool> errorStates = {
    'userName': false,
    'contactEmail': false,
    'contactPhone': false,
  };

  InputDecoration getInputDecoration(String hint, bool hasError) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(
          color: Color(0xFF8D8D8D),
          fontFamily: 'NotoSansKR',
          fontSize: 16,
          fontWeight: FontWeight.w400),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: hasError ? Color(0xFFAA4743) : const Color(0xFFEDEDED),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: hasError ? Color(0xFFAA4743) : const Color(0xFFEDEDED),
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

  void _validateFields() {
    setState(() {
      errorStates['userName'] = userNameCon.text.trim().isEmpty;
      errorStates['contactEmail'] = contactPhoneCon.text.trim().isEmpty &&
          contactEmailCon.text.trim().isEmpty;
      errorStates['contactPhone'] = contactEmailCon.text.trim().isEmpty &&
          contactPhoneCon.text.trim().isEmpty;
    });
  }

  void _submitForm() async {
    // 이름은 필수, 이메일 또는 연락처 둘 중 하나는 필수
    bool isNameValid = userNameCon.text.trim().isNotEmpty;
    bool isContactValid = contactEmailCon.text.trim().isNotEmpty ||
        contactPhoneCon.text.trim().isNotEmpty;

    // 조건 3: 이름만 입력했을 경우 제출 불가
    bool isOnlyNameEntered = isNameValid && !isContactValid;

    // 조건 4: 이메일 주소와 연락처만 입력했을 경우 제출 불가
    bool isOnlyContactEntered = !isNameValid && isContactValid;

    if (!isNameValid ||
        !isContactValid ||
        isOnlyNameEntered ||
        isOnlyContactEntered) {
      setState(() {
        errorStates['userName'] = !isNameValid;
        errorStates['contactEmail'] = !isContactValid;
        errorStates['contactPhone'] = !isContactValid;
      });
      return; // 폼 제출 중단
    }

    // 검증 통과 후 서버 요청
    try {
      final apiService = ApiService();
      final response = await apiService.fetchIdQnA(
        userNameCon.text.trim(),
        contactEmailCon.text.trim(),
        contactPhoneCon.text.trim(),
      );

      if (response.containsKey('message')) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('성공'),
              content: const Text('아이디 문의 등록이 완료되었습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청 실패: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  '아이디 문의',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),
                // 사용자 이름 필드
                Row(
                  children: [
                    const Text(
                      '사용자 이름',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (errorStates['userName'] == true)
                      const Text(
                        '이름은 필수 입력입니다',
                        style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFAA4743),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: userNameCon,
                  decoration: getInputDecoration(
                    '이름을 입력해 주세요',
                    errorStates['userName'] ?? false,
                  ),
                  onChanged: (value) {
                    setState(() {
                      errorStates['userName'] = value.trim().isEmpty;
                    });
                  },
                ),
                const SizedBox(height: 30),
                // 이메일 주소 필드
                Row(
                  children: [
                    const Text(
                      '이메일 주소',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (errorStates['contactEmail'] == true)
                      const Text(
                        '이메일 또는 연락처는 필수 입력입니다',
                        style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFAA4743),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: contactEmailCon,
                  decoration: getInputDecoration(
                    'user01@naver.com',
                    errorStates['contactEmail'] ?? false,
                  ),
                  onChanged: (value) {
                    setState(() {
                      errorStates['contactEmail'] =
                          contactPhoneCon.text.trim().isEmpty &&
                              value.trim().isEmpty;
                    });
                  },
                ),
                const SizedBox(height: 30),
                // 연락처 필드
                Row(
                  children: [
                    const Text(
                      '연락처',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (errorStates['contactPhone'] == true)
                      const Text(
                        '이메일 또는 연락처는 필수 입력입니다',
                        style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFAA4743),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: contactPhoneCon,
                  decoration: getInputDecoration(
                    '010-0000-0000',
                    errorStates['contactPhone'] ?? false,
                  ),
                  onChanged: (value) {
                    setState(() {
                      errorStates['contactPhone'] =
                          contactEmailCon.text.trim().isEmpty &&
                              value.trim().isEmpty;
                    });
                  },
                ),
                const SizedBox(height: 80),
                // 제출 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007130),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Text(
                      '문의하기',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansKR'),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
