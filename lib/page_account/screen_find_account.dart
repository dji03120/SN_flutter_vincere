import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';

//
//
//
InputDecoration getInputDecoration(String hint, bool hasError) {
  Color red = Color(0xFFAA4743);
  Color white = Color(0xFFEDEDED);
  OutlineInputBorder border1 = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16.0),
    borderSide: BorderSide(color: red, width: 1.0),
  );
  OutlineInputBorder border2 = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16.0),
    borderSide: BorderSide(color: hasError ? red : white, width: 1.0),
  );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8F9FB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
    hintStyle: const TextStyle(color: Color(0xFF8D8D8D), fontFamily: 'NotoSansKR', fontSize: 16, fontWeight: FontWeight.w400),
    enabledBorder: border2,
    focusedBorder: border2,
    errorBorder: border1,
    focusedErrorBorder: border1,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
  );
}

//
//
//
Widget input_form({
  required String label, // 라벨 텍스트 (예: '연락처')
  required String hint, // 힌트 텍스트 (예: '010-0000-0000')
  required TextEditingController controller, // 컨트롤러
  required Map<String, bool> errorStates, // 에러 상태 맵
  required String errorKey, // 에러 키 (예: 'contactPhone')
  required String errorMessage, // 에러 메시지
  required Function(String) onChanged, // 값 변경 시 콜백
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'NotoSansKR', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          const SizedBox(width: 8),
          if (errorStates[errorKey] == true)
            Text(
              errorMessage,
              style: const TextStyle(fontFamily: 'NotoSansKR', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFAA4743)),
            ),
        ],
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        decoration: getInputDecoration(hint, errorStates[errorKey] ?? false),
        onChanged: onChanged,
      ),
      const SizedBox(height: 30),
    ],
  );
}

//
//
//
class FindId extends StatefulWidget {
  @override
  _FindIdState createState() => _FindIdState();
}

class _FindIdState extends State<FindId> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController userNameCon = TextEditingController();
  TextEditingController contactEmailCon = TextEditingController();
  TextEditingController contactPhoneCon = TextEditingController();

  Map<String, bool> errorStates = {
    'userName': false,
    'contactEmail': false,
    'contactPhone': false,
  };

  //
  //
  //
  void _submitForm() async {
    // conditions
    // 이름은 필수, 이메일 또는 연락처 둘 중 하나는 필수
    bool isNameValid = userNameCon.text.trim().isNotEmpty;
    bool isContactValid = contactEmailCon.text.trim().isNotEmpty || contactPhoneCon.text.trim().isNotEmpty;
    bool isOnlyNameEntered = isNameValid && !isContactValid; // 조건 3: 이름만 입력했을 경우 제출 불가
    bool isOnlyContactEntered = !isNameValid && isContactValid; // 조건 4: 이메일 주소와 연락처만 입력했을 경우 제출 불가

    if (!isNameValid || !isContactValid || isOnlyNameEntered || isOnlyContactEntered) {
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
                actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
              );
            });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청 실패: $error')),
      );
    }
  }

  //
  //
  //
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

                input_form(
                  label: '사용자 이름',
                  hint: '이름을 입력해 주세요',
                  controller: userNameCon,
                  errorStates: errorStates,
                  errorKey: 'userName',
                  errorMessage: '이름은 필수 입력입니다',
                  onChanged: (value) {
                    setState(() {
                      errorStates['userName'] = value.trim().isEmpty;
                    });
                  },
                ),
                input_form(
                  label: '이메일 주소',
                  hint: 'user01@naver.com',
                  controller: contactEmailCon,
                  errorStates: errorStates,
                  errorKey: 'contactEmail',
                  errorMessage: '이메일 또는 연락처는 필수 입력입니다',
                  onChanged: (value) {
                    setState(() {
                      errorStates['contactEmail'] = contactPhoneCon.text.trim().isEmpty && value.trim().isEmpty;
                    });
                  },
                ),
                input_form(
                  label: '연락처',
                  hint: '010-0000-0000',
                  controller: contactPhoneCon,
                  errorStates: errorStates,
                  errorKey: 'contactPhone',
                  errorMessage: '이메일 또는 연락처는 필수 입력입니다',
                  onChanged: (value) {
                    setState(() {
                      errorStates['contactPhone'] = contactEmailCon.text.trim().isEmpty && value.trim().isEmpty;
                    });
                  },
                ),
                const SizedBox(height: 50),
                // 제출 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007130),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                    ),
                    child: const Text('문의하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansKR',
                        )),
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

//
//
//
//--------------------------------------
class FindPswd extends StatefulWidget {
  @override
  _FindPswdState createState() => _FindPswdState();
}

class _FindPswdState extends State<FindPswd> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController userIdCon = TextEditingController();
  TextEditingController userNameCon = TextEditingController();
  TextEditingController contactEmailCon = TextEditingController();
  TextEditingController contactPhoneCon = TextEditingController();

  // 에러 상태를 추적하기 위한 Map
  Map<String, bool> errorStates = {
    'userId': false,
    'userName': false,
    'contactEmail': false,
    'contactPhone': false,
  };

  void _submitForm() async {
    // 아이디, 이름은 필수, 이메일 또는 연락처 둘 중 하나는 필수
    bool isIdValid = userIdCon.text.trim().isNotEmpty;
    bool isNameValid = userNameCon.text.trim().isNotEmpty;
    bool isContactValid = contactEmailCon.text.trim().isNotEmpty || contactPhoneCon.text.trim().isNotEmpty;

    // 이름만 입력했을 경우 제출 불가
    bool isOnlyNameEntered = isNameValid && !isContactValid;

    // 이메일 주소와 연락처만 입력했을 경우 제출 불가
    bool isOnlyContactEntered = !isNameValid && isContactValid;

    if (!isIdValid || !isNameValid || !isContactValid || isOnlyNameEntered || isOnlyContactEntered) {
      setState(() {
        errorStates['userId'] = !isIdValid;
        errorStates['userName'] = !isNameValid;
        errorStates['contactEmail'] = !isContactValid;
        errorStates['contactPhone'] = !isContactValid;
      });
      return; // 폼 제출 중단
    }

    // 검증 통과 후 서버 요청
    try {
      final apiService = ApiService();
      final response = await apiService.fetchPswdQnA(
        userIdCon.text.trim(),
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
              content: const Text('비밀번호 문의 등록이 완료되었습니다.'),
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
      body: SingleChildScrollView(
        // 추가된 부분
        child: Container(
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
                    '비밀번호 문의',
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 사용자 아이디 필드
                  input_form(
                    label: '아이디',
                    hint: '아이디를 입력해 주세요',
                    controller: userIdCon,
                    errorStates: errorStates,
                    errorKey: 'userId',
                    errorMessage: '아이디는 필수 입력입니다',
                    onChanged: (value) {
                      setState(() {
                        errorStates['userId'] = value.trim().isEmpty;
                      });
                    },
                  ),
                  input_form(
                    label: '사용자 이름',
                    hint: '이름을 입력해 주세요',
                    controller: userNameCon,
                    errorStates: errorStates,
                    errorKey: 'userName',
                    errorMessage: '이름은 필수 입력입니다',
                    onChanged: (value) {
                      setState(() {
                        errorStates['userName'] = value.trim().isEmpty;
                      });
                    },
                  ),
                  input_form(
                    label: '이메일 주소',
                    hint: 'user01@naver.com',
                    controller: contactEmailCon,
                    errorStates: errorStates,
                    errorKey: 'contactEmail',
                    errorMessage: '이메일 또는 연락처는 필수 입력입니다',
                    onChanged: (value) {
                      setState(() {
                        errorStates['contactEmail'] = contactPhoneCon.text.trim().isEmpty && value.trim().isEmpty;
                      });
                    },
                  ),
                  input_form(
                    label: '연락처',
                    hint: '010-0000-0000',
                    controller: contactPhoneCon,
                    errorStates: errorStates,
                    errorKey: 'contactPhone',
                    errorMessage: '이메일 또는 연락처는 필수 입력입니다',
                    onChanged: (value) {
                      setState(() {
                        errorStates['contactPhone'] = contactEmailCon.text.trim().isEmpty && value.trim().isEmpty;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  // 제출 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 55,
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
  void _validateFields() {
    setState(() {
      errorStates['userName'] = userNameCon.text.trim().isEmpty;
      errorStates['contactEmail'] = contactPhoneCon.text.trim().isEmpty &&
          contactEmailCon.text.trim().isEmpty;
      errorStates['contactPhone'] = contactEmailCon.text.trim().isEmpty &&
          contactPhoneCon.text.trim().isEmpty;
    });
  }
*/

  /*void _validateFields() {
    setState(() {
      errorStates['userId'] = userIdCon.text.trim().isEmpty;
      errorStates['userName'] = userNameCon.text.trim().isEmpty;
      errorStates['contactEmail'] = contactPhoneCon.text.trim().isEmpty &&
          contactEmailCon.text.trim().isEmpty;
      errorStates['contactPhone'] = contactEmailCon.text.trim().isEmpty &&
          contactPhoneCon.text.trim().isEmpty;
    });
  }*/