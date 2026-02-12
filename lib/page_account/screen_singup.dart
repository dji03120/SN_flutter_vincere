import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/export/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:Vincere/page_account/screen_kakao_address.dart';

class SingUpScreen extends StatefulWidget {
  const SingUpScreen({super.key});

  @override
  _SingUpScreenState createState() => _SingUpScreenState();
}

class HangulEnglishInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 한글, 영문만 허용하는 정규식
    final RegExp reg = RegExp(r'^[a-zA-Z가-힣\s]*$');

    // 입력된 텍스트가 정규식과 일치하지 않으면 이전 값을 반환
    if (!reg.hasMatch(newValue.text)) {
      return oldValue;
    }
    return newValue;
  }
}

class IdInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 영문, 숫자만 허용하는 정규식
    final RegExp reg = RegExp(r'^[a-zA-Z0-9]*$');

    // 입력된 텍스트가 정규식과 일치하지 않으면 이전 값을 반환
    if (!reg.hasMatch(newValue.text)) {
      return oldValue;
    }
    return newValue;
  }
}

class _SingUpScreenState extends State<SingUpScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController userIdCon = TextEditingController();
  TextEditingController userNmCon = TextEditingController();
  TextEditingController passWdCon = TextEditingController();
  TextEditingController passWdChkCon = TextEditingController();
  TextEditingController bymCon = TextEditingController();
  TextEditingController addressCon = TextEditingController();
  TextEditingController addressDtCon = TextEditingController();
  TextEditingController phoneCon = TextEditingController();
  TextEditingController emailLocalPartCon = TextEditingController(); // 이메일 로컬 파트 (앞 부분)
  TextEditingController emailCustomDomainCon = TextEditingController(); // 직접 입력 도메인
  TextEditingController zipCdCon = TextEditingController(); // 우편번호 입력 필드

  String userId = '';
  String userNm = '';
  String passWd = '';
  String bym = '';
  String sex = 'M';
  String activityLevel = 'LOW'; // 새로 추가: 활동량 레벨
  String emailDomain = 'naver.com'; // 기본 도메인
  String hpNo = '';
  String zipCd = '';
  String addr = '';
  String addrDtl = '';
  String email = '';

  bool _isObscure = true;
  bool _isObscureChk = true;
  bool _validateUserId = false;
  bool _validatePw = false;
  bool _validatePwChk = false;
  bool _validateUserNm = false;
  bool _validateBym = false;
  bool _validateEmail = false;
  bool _validateZipCd = false;
  bool _validateAddr = false;
  bool _validatePhone = false;
  bool _isCustomDomain = false; // 직접 입력 여부 플래그
  bool _isUserIdChecked = false; // 아이디 중복 확인 여부
  bool _isAgreed = false; // 체크박스 상태 변수
  bool _validateActivityLevel = false;

  // ignore: unused_field
  String _passWdError = '';
  // ignore: unused_field
  String _passWdChkError = '';

  var currentDropVal = 'M';
  String? currentActivityLevel; // 새로 추가: 현재 선택된 활동량

  void _validateFields() {
    setState(() {
      _validateUserId = userIdCon.text.isEmpty;
      _validateUserNm = userNmCon.text.isEmpty;
      _validateBym = bymCon.text.isEmpty || bymCon.text.length != 8;
      _validatePhone = phoneCon.text.isEmpty;
      _validateEmail = emailLocalPartCon.text.isEmpty || (_isCustomDomain && emailCustomDomainCon.text.isEmpty); // 직접 입력 도메인 확인

      // 주소 관련 검증 상태 추가
      _validateZipCd = zipCdCon.text.isEmpty; // 우편번호 필드
      _validateAddr = addressCon.text.isEmpty; // 주소 필드

      _validateActivityLevel = currentActivityLevel == null;
    });
  }

  void _validatePassWd() {
    setState(() {
      _passWdError = '';
      _passWdChkError = '';
      _validatePw = passWdCon.text.isEmpty; // 비밀번호 필드 검증
      _validatePwChk = passWdChkCon.text.isEmpty || passWdCon.text != passWdChkCon.text; // 재확인 필드 검증

      if (passWdCon.text.isEmpty) {
        _passWdError = '비밀번호를 입력해 주세요.';
      }

      if (passWdChkCon.text.isEmpty) {
        _passWdChkError = '비밀번호를 입력해 주세요.';
      } else if (passWdCon.text != passWdChkCon.text) {
        _passWdChkError = '비밀번호가 일치하지 않습니다.';
      }
    });
  }

  // 육체활동 설정 여부 확인
  bool _validateActLev() {
    if (currentActivityLevel == null) {
      _showAlert('육체활동 수준을 선택해 주세요.');
      return false; // 유효성 검사 실패 시 false 반환
    }
    return true; // 유효성 검사 통과 시 true 반환
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('알림'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 아이디 중복 확인
  void _checkDuplicateUserId() async {
    String userId = userIdCon.text; // 사용자가 입력한 아이디

    if (userId.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('아이디 입력 오류'),
          content: const Text('아이디를 입력해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchUserIdDuplication(userId);

      if (result.containsKey('result')) {
        int duplicationResult = result['result']; // API에서 반환한 중복 여부 (0 또는 1)

        if (duplicationResult == 0) {
          setState(() {
            _isUserIdChecked = true;
            _validateUserId = false;
          });
          // 0: 사용 가능한 아이디
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('사용 가능한 아이디'),
              content: Text('이 아이디는 사용 가능합니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else if (duplicationResult == 1) {
          // 1: 중복된 아이디
          setState(() {
            _isUserIdChecked = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('중복된 아이디'),
              content: const Text('이미 사용 중인 아이디입니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else {
          // 예상치 못한 값 처리
          throw Exception('Unexpected result value: $duplicationResult');
        }
      } else {
        throw Exception('Invalid API response: Key "result" not found');
      }
    } catch (e) {
      // 예외 처리
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류 발생'),
          content: Text('중복 확인 중 오류가 발생했습니다: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _regUser() async {
    _validateFields();
    _validatePassWd();

    if (!_isUserIdChecked) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('아이디 중복 확인 필요'),
                content: const Text('아이디 중복 확인을 완료해주세요.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ));
      return;
    }

    if (_validateUserId || _validatePw || _validatePwChk || _validateUserNm || _validateBym || _validateEmail || _validateZipCd || _validateAddr || _validatePhone) {
      _showMissingFieldsAlert();
      return; // 유효하지 않은 필드가 있으면 함수 종료
    }

    hpNo = phoneCon.text;
    addr = addressCon.text; // 주소 입력값
    addrDtl = addressDtCon.text; // 상세주소 입력값
    zipCd = zipCdCon.text; // 우편번호 입력값
    email = _isCustomDomain ? '${emailLocalPartCon.text}@${emailCustomDomainCon.text}' : '${emailLocalPartCon.text}@$emailDomain';

    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchUserRegist(
        userIdCon.text,
        userNmCon.text,
        bymCon.text,
        sex,
        passWdCon.text,
        activityLevel,
        hpNo,
        zipCd,
        addr,
        addrDtl,
        email,
      );

      if (result['result'] == 1) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('회원가입 완료'),
            content: const Text('회원가입이 완료되었습니다. 로그인을 해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text('로그인 하기'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('회원가입 실패');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showMissingFieldsAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미입력 항목이 존재합니다'),
        content: const Text('가입에 필요한 항목을 모두 입력해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  //
  // void _showPwdMismatchAlert() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('비밀번호 오류'),
  //       content: const Text('비밀번호를 확인해주세요.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('확인'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  InputDecoration getInputDecoration(
    String hint, {
    String? errorText,
    bool obscureToggle = false,
    VoidCallback? onToggleObscure,
    bool obscureText = false,
    bool isError = false,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      hintStyle: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 16, fontWeight: FontWeight.w400),
      // 에러 상태에 따라 보더 색상 변경
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: isError ? Color(0xFFAA4743) : Color(0xFFEDEDED), // 에러 상태 시 빨간색 보더
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: isError ? Color(0xFFAA4743) : Color(0xFFEDEDED), // 에러 상태 시 빨간색 포커스 보더
          width: 1.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(
          color: Color(0xFFAA4743), // 에러 상태
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
      suffixIcon: obscureToggle
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onToggleObscure,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    );
  }

  String selectedActivity = '선택';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      backgroundColor: Colors.white, // 전체 페이지 배경색을 화이트로 설정
      body: ScrollConfiguration(
        behavior: DesktopDragScrollBehavior(),
        child: Container(
          color: Colors.white, // 페이지 배경색 설정
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //const SizedBox(height: 30),
                      //Align(
                      //  alignment: Alignment.centerLeft, // 왼쪽 정렬
                      //    child: Image.asset(
                      //     'images/top_logo.png',
                      //     width: 128,
                      //     height: 20,
                      //     fit: BoxFit.contain, // 이미지 크기 조정 방식
                      //   ),
                      // ),
                      //const SizedBox(height: 48), // 로고 아래 여백 추가
                      const Text(
                        '회원가입하기', // 여기에 원하는 텍스트 입력
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '아이디',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8), // 라벨과 문구 간 간격
                          if (_validateUserId) // 아이디 입력 검증 실패 시
                            const Text(
                              '아이디를 입력해 주세요',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFAA4743), // 빨간색
                              ),
                            ),
                          if (_isUserIdChecked && !_validateUserId) // 중복 확인 성공 시
                            const Text(
                              '사용 가능한 아이디입니다',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF00914B), // 초록색
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8), // 라벨과 입력 필드 간 간격
                      Row(
                        children: [
                          Expanded(
                            flex: 7, // 아이디 입력 필드
                            child: TextFormField(
                              controller: userIdCon,
                              inputFormatters: [IdInputFormatter()],
                              decoration: InputDecoration(
                                hintText: '아이디를 입력해 주세요',
                                filled: true,
                                fillColor: const Color(0xFFF8F9FB),
                                hintStyle: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 16, fontWeight: FontWeight.w400),
                                // 보더 색상 처리
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: BorderSide(
                                    color: _validateUserId
                                        ? Color(0xFFAA4743) // 에러 상태
                                        : _isUserIdChecked
                                            ? const Color(0xFF007331) // 중복 확인 성공 시 초록색
                                            : Color(0xFFEDEDED), // 기본 상태
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: BorderSide(
                                    color: _validateUserId
                                        ? Color(0xFFAA4743) // 에러 상태
                                        : Color(0xFFEDEDED), // 포커스 상태
                                    width: 1.0,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              ),
                              keyboardType: TextInputType.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 111,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _checkDuplicateUserId, // 버튼 동작
                              style: ElevatedButton.styleFrom(
                                // 버튼 배경색
                                backgroundColor: Colors.white, // 배경 흰색
                                // 버튼 텍스트 색상
                                foregroundColor: Color(0xFF555555), // 텍스트 색상
                                // 버튼 테두리 색상과 굵기
                                side: const BorderSide(
                                  color: Color(0xFF555555), // 테두리 색상
                                  width: 1.0, // 테두리 굵기
                                ),
                                // 그림자 높이 (0이면 그림자 없음)
                                elevation: 0,
                                // 둥근 모서리 설정
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0), // 둥글기 조절
                                ),
                                // 버튼 내부 패딩 조정
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              ),
                              child: const Text(
                                '중복확인',
                                style: TextStyle(
                                  fontSize: 18, // 텍스트 크기
                                  fontWeight: FontWeight.w500, // 텍스트 굵기
                                  color: Color(0xFF555555), // 텍스트 색상 (foregroundColor와 동일하게 설정)
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // 비밀번호 라벨 및 에러 메시지 표시
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '비밀번호',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8), // 라벨과 에러 메시지 간격
                          if (_validatePw) // 비밀번호 검증 실패 시 에러 메시지 표시
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
                      const SizedBox(height: 8),
                      // 비밀번호 입력 필드
                      TextFormField(
                        controller: passWdCon,
                        obscureText: _isObscure,
                        decoration: getInputDecoration(
                          '비밀번호를 입력해 주세요',
                          isError: _validatePw,
                        ),
                      ),

                      const SizedBox(height: 8),
                      // 비밀번호 재확인 입력 필드
                      TextFormField(
                        controller: passWdChkCon,
                        obscureText: _isObscureChk,
                        decoration: getInputDecoration(
                          '비밀번호 재확인',
                          isError: _validatePwChk,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '이름',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8), // 간격 추가
                          if (_validateUserNm) // 이름이 비어있으면 에러 메시지 표시
                            const Text(
                              '이름을 입력해 주세요',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFAA4743),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: userNmCon,
                        decoration: getInputDecoration('이름을 입력해 주세요', isError: _validateUserNm),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 주소 라벨 및 에러 문구
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                '주소',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_validateAddr) // 주소 필드 에러 시 문구 표시
                                const Text(
                                  '주소를 입력해 주세요',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFAA4743),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 우편번호 입력 필드
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: zipCdCon,
                                  readOnly: true,
                                  decoration: getInputDecoration('우편번호', isError: _validateZipCd // 우편번호 미입력 시 에러 처리
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 주소 찾기 버튼
                              SizedBox(
                                width: 111,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => KakaoAddressSearchScreen(),
                                      ),
                                    );
                                    if (result != null) {
                                      setState(() {
                                        zipCdCon.text = result['zipCd'];
                                        addressCon.text = result['roadAddress'];
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(color: Color(0xFF555555), width: 1),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  ),
                                  child: const Text(
                                    '주소찾기',
                                    style: TextStyle(
                                      fontSize: 18, // 텍스트 크기
                                      fontWeight: FontWeight.w500, // 텍스트 굵기
                                      color: Color(0xFF555555), // 텍스트 색상 (foregroundColor와 동일하게 설정)
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 주소 입력 필드
                          TextFormField(
                            controller: addressCon,
                            readOnly: true,
                            decoration: getInputDecoration('주소', isError: _validateAddr && addressDtCon.text.isEmpty),
                          ),
                          const SizedBox(height: 8),
                          // 상세 주소 입력 필드
                          TextFormField(
                            controller: addressDtCon,
                            decoration: getInputDecoration('상세 주소를 입력해 주세요', isError: _validateAddr && addressDtCon.text.isEmpty),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '연락처',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8), // 간격 추가
                          if (_validatePhone) // 연락처 비어있을 때 메시지 표시
                            const Text(
                              '연락처를 입력해 주세요',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFAA4743),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: phoneCon,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d-]')), // 숫자와 -만 허용
                        ],
                        decoration: getInputDecoration('전화번호를 입력해 주세요', isError: _validatePhone),
                        keyboardType: TextInputType.phone,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                '이메일 주소',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_validateEmail)
                                const Text(
                                  '이메일을 입력해 주세요',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFAA4743),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          IntrinsicHeight(
                            // 높이 맞춤
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 이메일 아이디 입력 필드
                                Expanded(
                                  flex: 4,
                                  child: TextFormField(
                                    controller: emailLocalPartCon,
                                    decoration: getInputDecoration('user01', isError: _validateEmail),
                                  ),
                                ),
                                // @ 문자
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '@',
                                    style: TextStyle(fontSize: 20, color: Colors.black),
                                  ),
                                ),
                                // 도메인 드롭다운 또는 직접 입력 필드
                                Expanded(
                                  flex: 6,
                                  child: Row(
                                    children: [
                                      // 직접 입력 텍스트 필드 (왼쪽에 배치)
                                      if (_isCustomDomain)
                                        Expanded(
                                          flex: 5,
                                          child: TextFormField(
                                            controller: emailCustomDomainCon,
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: getInputDecoration(
                                              '도메인을 입력해 주세요', // 힌트 텍스트만 사용
                                              errorText: _validateEmail && emailCustomDomainCon.text.isEmpty ? "도메인을 입력해 주세요" : null,
                                            ),
                                          ),
                                        ),
                                      if (_isCustomDomain) const SizedBox(width: 8), // 간격 추가

                                      // 도메인 선택 드롭다운 (오른쪽에 배치)
                                      Expanded(
                                        flex: 5,
                                        child: DropdownButtonFormField<String>(
                                          value: _isCustomDomain ? 'custom' : emailDomain,
                                          items: [
                                            DropdownMenuItem(value: 'naver.com', child: Text('naver.com')),
                                            DropdownMenuItem(value: 'gmail.com', child: Text('gmail.com')),
                                            DropdownMenuItem(value: 'daum.net', child: Text('daum.net')),
                                            DropdownMenuItem(value: 'hanmail.net', child: Text('hanmail.net')),
                                            DropdownMenuItem(value: 'nate.com', child: Text('nate.com')),
                                            DropdownMenuItem(value: 'custom', child: Text('직접 입력')),
                                          ],
                                          onChanged: (String? value) {
                                            setState(() {
                                              if (value == 'custom') {
                                                _isCustomDomain = true; // 직접 입력 활성화
                                                emailDomain = ''; // 도메인 초기화
                                              } else {
                                                _isCustomDomain = false; // 드롭다운 활성화
                                                emailDomain = value ?? ''; // 도메인 값 설정
                                                emailCustomDomainCon.clear(); // 직접 입력 값 초기화
                                              }
                                            });
                                          },
                                          decoration: getInputDecoration(
                                            '도메인을 선택해주세요', // 힌트 텍스트
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '생년월일',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_validateBym)
                            const Text(
                              '생년월일을 입력해 주세요',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFAA4743),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: bymCon,
                        decoration: getInputDecoration('YYYYMMDD', isError: _validateBym),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(8),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(height: 30),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3, // 좌측 title 영역
                              child: Text(
                                '육체활동 설정',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _validateActivityLevel ? Color(0xFFAA4743) : Color(0xFF555555), // 설정하지 않으면 빨간색
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(16.0), // 모서리 둥글게
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16.0), // 내부 여백
                                child: DropdownButtonHideUnderline(
                                  // 기본 밑줄 제거
                                  child: DropdownButton<String>(
                                    value: currentActivityLevel,
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(16.0),
                                    hint: Center(
                                      child: Text(
                                        '선택',
                                        style: TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w500, fontSize: 18),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'LOW',
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center, // 수직 가운데 정렬
                                          children: [
                                            SizedBox(
                                              width: 100, // "좌업자" 텍스트의 고정 너비
                                              child: Text('좌업자', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '일일활동량 30분 미만',
                                                style: TextStyle(color: Color(0xFF00914B), fontSize: 13, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'NORMAL',
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 100, // "보통활동"과 동일한 너비
                                              child: Text('보통활동', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '일일활동량 30분에서 60분 사이',
                                                style: TextStyle(color: Color(0xFF00914B), fontSize: 13, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'HIGH',
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 100, // "많은 육체활동"과 동일한 너비
                                              child: Text('많은 육체활동', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '일일활동량 60분 이상',
                                                style: TextStyle(color: Color(0xFF007331), fontSize: 13, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (String? value) {
                                      setState(() {
                                        currentActivityLevel = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Container(),
                      ),
                      // 성별 select box
                      Container(
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
                          crossAxisAlignment: CrossAxisAlignment.center, // 수직 가운데 정렬
                          children: [
                            // 성별 라벨
                            Text(
                              '성별',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 16), // 라벨과 라디오 버튼 사이의 간격
                            // 라디오 버튼 그룹
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: 'M',
                                      groupValue: sex,
                                      activeColor: const Color(0xFF007331),
                                      onChanged: (String? value) {
                                        setState(() {
                                          sex = value!;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8), // 라디오 버튼과 "남성" 라벨 간의 간격
                                    const Text(
                                      '남성',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 30), // 남성 버튼과 여성 버튼 사이 간격
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: 'F',
                                      groupValue: sex,
                                      activeColor: const Color(0xFF007331),
                                      onChanged: (String? value) {
                                        setState(() {
                                          sex = value!;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8), // 라디오 버튼과 "여성" 라벨 간의 간격
                                    const Text(
                                      '여성',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 54,
                        child: Container(),
                      ),
                      //체크박스
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
                        children: [
                          SizedBox(
                            width: 24, // 체크박스 너비 24
                            height: 24, // 체크박스 높이 24
                            child: Checkbox(
                              value: _isAgreed,
                              activeColor: const Color(0xFF007331),
                              onChanged: (bool? value) {
                                setState(() {
                                  _isAgreed = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12), // 체크박스와 텍스트 사이 간격 추가
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAgreed = !_isAgreed; // 체크박스 상태 토글
                              });
                            },
                            child: const Text(
                              '개인정보 제공 및 이용에 동의합니다.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                            ),
                          ),
                          const SizedBox(width: 10), // 텍스트 간 간격 추가
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('개인정보 제공 및 이용 동의 안내'),
                                  content: const Text(
                                    '개인정보 제공 및 이용에 대한 안내 내용입니다.\n'
                                    '1. 수집 목적: 회원가입 및 서비스 제공\n'
                                    '2. 수집 항목: 이름, 연락처, 이메일, 주소 등\n'
                                    '3. 이용 기간: 회원 탈퇴 시까지 보관 후 파기\n'
                                    '4. 기타 자세한 내용은 회사 정책을 참고해주세요.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text(
                              '전체보기',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8D8D8D),
                                decoration: TextDecoration.underline, // 밑줄 추가
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity, // 버튼이 부모 너비에 맞게 확장됨
                        height: 56, // 버튼 높이 설정
                        child: ElevatedButton(
                          onPressed: _isAgreed
                              ? () {
                                  _validateFields(); // 다른 필드 검증
                                  _validatePassWd(); // 비밀번호 검증

                                  if (!_validateActLev()) {
                                    //육체활동 검증
                                    return;
                                  }

                                  if (_formKey.currentState?.validate() ?? false) {
                                    _regUser(); // 회원가입 처리
                                  }
                                }
                              : null, // 체크박스 동의 여부에 따라 버튼 활성화
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAgreed
                                ? const Color(0xFF007331) // 체크박스 동의 시 녹색 배경
                                : Colors.grey, // 체크박스 미동의 시 회색 배경
                            foregroundColor: Colors.white, // 텍스트 색상 흰색
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // 버튼 모서리 둥글게
                            ),
                          ),
                          child: const Text(
                            '가입하기',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      SizedBox(height: 60)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
