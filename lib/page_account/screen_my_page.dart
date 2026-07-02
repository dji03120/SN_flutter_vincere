// 마이페이지 회원정보와 프로필 사진 관리를 위한 기능

import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:Vincere/page_account/screen_kakao_address.dart';
import 'package:Vincere/page_account/screen_update_pswd.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// 생년월일 숫자 입력값을 날짜 표시 형식으로 변환하기 위한 기능
class BymInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formattedText = _formatDigits(limitedDigits);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  // 생년월일 숫자를 yyyy.MM.dd 형태로 화면에 표시하기 위한 기능
  static String _formatDigits(String digits) {
    if (digits.length <= 4) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 4)}.${digits.substring(4)}';
    }
    return '${digits.substring(0, 4)}.${digits.substring(4, 6)}.${digits.substring(6)}';
  }
}

class MyPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(String?) onProfileImageChange; // 콜백 함수
  final Function(String?) onActivityLevelChange; // 콜백 함수

  const MyPage({
    Key? key,
    this.userData,
    required this.onProfileImageChange,
    required this.onActivityLevelChange,
  }) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? currentActivityLevel = "";
  // ignore: unused_field
  XFile? _profileImage;
  bool _isLoading = false;
  String? _profileImageUrl; // 프로필 이미지 URL 저장용 변수
  String? userId;
  String sex = '';
  bool _isAgreed = false;

  // 모바일 웹에서만 브라우저 사진 촬영 선택지를 안내하기 위한 기능
  bool get _isMobileWeb {
    return kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);
  }

  TextEditingController userNmCon = TextEditingController();
  TextEditingController emailCon = TextEditingController();
  TextEditingController phoneCon = TextEditingController();
  TextEditingController bymCon = TextEditingController();
  TextEditingController zipCdCon = TextEditingController();
  TextEditingController addrCon = TextEditingController();
  TextEditingController addrDtlCon = TextEditingController();

  bool _validateUserNm = false;
  bool _validateEmail = false;
  bool _validatePhone = false;
  bool _validateBym = false;
  bool _validateZipCd = false;
  bool _validateAddr = false;
  bool _validateActivityLevel = false;

  @override
  void initState() {
    super.initState();

    currentActivityLevel =
        widget.userData?["activityLevel"]?.toUpperCase() ?? "LOW";
    userId = widget.userData?["userId"];

    //이름 초기값 설정
    userNmCon.text = widget.userData?["userNm"] ?? "N/A";
    emailCon.text = widget.userData?["email"] ?? "N/A";
    phoneCon.text = widget.userData?["phone"] ?? "N/A";
    bymCon.text = _formatBymForDisplay(widget.userData?["bym"] ?? "");
    zipCdCon.text = widget.userData?["zipCd"] ?? "N/A";
    addrCon.text = widget.userData?["addr"] ?? "N/A";
    addrDtlCon.text = widget.userData?["addrDtl"] ?? "N/A";

    _initializeData();
  }

  Future<void> _initializeData() async {
    final ApiService apiService = ApiService();
    try {
      // 기존 프로필 이미지 가져오기 호출
      await _getProfileImage();

      // 사용자 정보 API 호출
      final userInfo = await apiService.fetchGetUserMyPage(userId!);
      print('Fetched User Info: $userInfo');

      setState(() {
        userNmCon.text = userInfo['userNm'] ?? "";
        emailCon.text = userInfo['email'] ?? "";
        phoneCon.text = userInfo['hpNo'] ?? "";
        bymCon.text = _formatBymForDisplay(userInfo['bym'] ?? "");
        zipCdCon.text = userInfo['zipCd'] ?? "";
        addrCon.text = userInfo['addr'] ?? "";
        addrDtlCon.text = userInfo['addrDtl'] ?? "";
        currentActivityLevel = userInfo['activityLevel'] ?? "LOW";
        sex = userInfo['sex'] ?? "M";
      });
    } catch (e) {
      print('Error fetching user info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 불러오는 중 오류가 발생했습니다.')),
      );
    }
  }

  // 서버 저장용 생년월일 8자리를 화면 표시용 날짜 형식으로 바꾸기 위한 기능
  String _formatBymForDisplay(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return value;
    return '${digits.substring(0, 4)}.${digits.substring(4, 6)}.${digits.substring(6, 8)}';
  }

  // 화면 표시용 생년월일에서 서버 저장용 숫자만 추출하기 위한 기능
  String _normalizeBymForSave(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // 생년월일 값이 실제 날짜로 유효한지 확인하기 위한 기능
  bool _isValidBym(String value) {
    if (value.length != 8) return false;

    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(4, 6));
    final day = int.tryParse(value.substring(6, 8));
    if (year == null || month == null || day == null) return false;

    final parsedDate = DateTime(year, month, day);
    final today = DateTime.now();

    return parsedDate.year == year &&
        parsedDate.month == month &&
        parsedDate.day == day &&
        !parsedDate.isAfter(today);
  }

  // 생년월일 입력값 또는 기본값으로 달력 초기 날짜를 계산하기 위한 기능
  DateTime _getInitialBirthDate() {
    final digits = _normalizeBymForSave(bymCon.text);
    if (_isValidBym(digits)) {
      return DateTime(
        int.parse(digits.substring(0, 4)),
        int.parse(digits.substring(4, 6)),
        int.parse(digits.substring(6, 8)),
      );
    }

    return DateTime(1990, 1, 1);
  }

  // 선택한 년월 기준의 마지막 일자를 계산하기 위한 기능
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // 커스텀 바텀시트로 생년월일을 선택해 입력칸에 반영하기 위한 기능
  Future<void> _pickBirthDate() async {
    final initialDate = _getInitialBirthDate();
    final currentYear = DateTime.now().year;
    final years =
        List<int>.generate(currentYear - 1899, (index) => currentYear - index);
    final months = List<int>.generate(12, (index) => index + 1);

    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDay = initialDate.day;

    final yearController =
        FixedExtentScrollController(initialItem: years.indexOf(selectedYear));
    final monthController =
        FixedExtentScrollController(initialItem: selectedMonth - 1);
    final dayController =
        FixedExtentScrollController(initialItem: selectedDay - 1);

    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final days = List<int>.generate(
                _daysInMonth(selectedYear, selectedMonth),
                (index) => index + 1);
            if (selectedDay > days.length) {
              selectedDay = days.length;
              // 월 변경으로 일수가 줄어든 경우 일자 휠 위치를 보정하기 위한 기능
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dayController.hasClients) {
                  dayController.jumpToItem(selectedDay - 1);
                }
              });
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 10, 20, MediaQuery.of(context).padding.bottom + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E5EA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '생년월일 선택',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                              context,
                              DateTime(
                                  selectedYear, selectedMonth, selectedDay));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007331),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFEDEDED)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: yearController,
                            itemExtent: 44,
                            magnification: 1.08,
                            squeeze: 1.05,
                            useMagnifier: true,
                            selectionOverlay:
                                const CupertinoPickerDefaultSelectionOverlay(
                              background: Color(0x12007331),
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedYear = years[index];
                                selectedDay = selectedDay.clamp(1,
                                    _daysInMonth(selectedYear, selectedMonth));
                              });
                            },
                            children: years
                                .map((year) => Center(child: Text('$year년')))
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: monthController,
                            itemExtent: 44,
                            magnification: 1.08,
                            squeeze: 1.05,
                            useMagnifier: true,
                            selectionOverlay:
                                const CupertinoPickerDefaultSelectionOverlay(
                              background: Color(0x12007331),
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedMonth = months[index];
                                selectedDay = selectedDay.clamp(1,
                                    _daysInMonth(selectedYear, selectedMonth));
                              });
                            },
                            children: months
                                .map((month) => Center(child: Text('$month월')))
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: dayController,
                            itemExtent: 44,
                            magnification: 1.08,
                            squeeze: 1.05,
                            useMagnifier: true,
                            selectionOverlay:
                                const CupertinoPickerDefaultSelectionOverlay(
                              background: Color(0x12007331),
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedDay = days[index];
                              });
                            },
                            children: days
                                .map((day) => Center(child: Text('$day일')))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (pickedDate == null) return;

    setState(() {
      bymCon.text = _formatBymForDisplay(
        '${pickedDate.year.toString().padLeft(4, '0')}'
        '${pickedDate.month.toString().padLeft(2, '0')}'
        '${pickedDate.day.toString().padLeft(2, '0')}',
      );
      _validateBym = false;
    });
  }

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
      hintStyle: const TextStyle(
          color: Color(0xFF8D8D8D), fontSize: 16, fontWeight: FontWeight.w400),
      // 에러 상태에 따라 보더 색상 변경
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color:
              isError ? Color(0xFFAA4743) : Color(0xFFEDEDED), // 에러 상태 시 빨간색 보더
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(
          color: isError
              ? Color(0xFFAA4743)
              : Color(0xFFEDEDED), // 에러 상태 시 빨간색 포커스 보더
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

  void _validateFields() {
    setState(() {
      final normalizedBym = _normalizeBymForSave(bymCon.text);
      _validateUserNm = userNmCon.text.isEmpty;
      _validateBym = !_isValidBym(normalizedBym);
      _validatePhone = phoneCon.text.isEmpty;
      _validateEmail = emailCon.text.isEmpty;
      // 주소 관련 검증 상태 추가
      _validateZipCd = zipCdCon.text.isEmpty; // 우편번호 필드
      _validateAddr = addrCon.text.isEmpty; // 주소 필드

      _validateActivityLevel = currentActivityLevel == null;
    });
  }

  void _saveUserInfo() async {
    // 필드 검증
    _validateFields();

    // 검증 실패 시 중단
    if (_validateUserNm ||
        _validateEmail ||
        _validatePhone ||
        _validateBym ||
        _validateZipCd ||
        _validateAddr ||
        _validateActivityLevel) {
      return;
    }

    // 로딩 상태 시작
    setState(() {
      _isLoading = true;
    });

    try {
      // API 호출
      final result = await ApiService().fetchUpdateUserMyPage(
        userId!,
        userNmCon.text,
        emailCon.text,
        phoneCon.text,
        _normalizeBymForSave(bymCon.text),
        zipCdCon.text,
        addrCon.text,
        addrDtlCon.text,
        currentActivityLevel!,
        sex,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 정보가 성공적으로 저장되었습니다.')),
        );

        widget.onActivityLevelChange(currentActivityLevel);

        // 필요 시 추가 로직 (e.g., 화면 갱신)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${result['message'] ?? '알 수 없는 오류'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      // 로딩 상태 종료
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // 수직 정렬을 위쪽으로 맞춤
                  children: [
                    // 회원정보 텍스트와 비밀번호 변경
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10), // 위쪽 간격 추가
                          const Text(
                            '회원정보',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const UpdatePswd()),
                              );
                            },
                            child: Row(
                              children: const [
                                Text(
                                  '비밀번호 변경',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF555555)),
                                ),
                                Icon(Icons.chevron_right,
                                    color: Color(0xFF555555)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 프로필 사진 및 편집 버튼
                    Column(
                      children: [
                        const SizedBox(height: 10), // 위쪽 공백 추가
                        Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Container(
                              width: 100, // CircleAvatar의 두 배 크기
                              height: 100, // CircleAvatar의 두 배 크기
                              decoration: BoxDecoration(
                                color: Colors.white, // CircleAvatar의 배경색
                                shape: BoxShape.circle, // 원형 테두리
                                border: Border.all(
                                  color: Color(0xFFEDEDED), // 테두리 색상
                                  width: 1.0, // 테두리 두께
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 58, // Avatar 크기
                                backgroundColor: Colors.white,
                                backgroundImage: _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                                child: _profileImageUrl == null
                                    ? Image.asset('images/profile_user.png',
                                        width: 60, height: 60)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.photo_library),
                                              title: Text(_isMobileWeb
                                                  ? '사진 선택 또는 촬영'
                                                  : kIsWeb
                                                      ? '사진 선택'
                                                      : '갤러리에서 선택'),
                                              onTap: () async {
                                                Navigator.pop(context);
                                                final ImagePicker picker =
                                                    ImagePicker();
                                                // 모바일 갤러리 이미지의 업로드 용량을 줄이기 위한 기능
                                                final XFile? image =
                                                    await picker.pickImage(
                                                  source: ImageSource.gallery,
                                                  maxWidth: 1024,
                                                  maxHeight: 1024,
                                                  imageQuality: 85,
                                                );
                                                if (image != null) {
                                                  setState(() {
                                                    _profileImage = image;
                                                  });
                                                  await _uploadImage(image);
                                                }
                                              },
                                            ),
                                            // 네이티브 앱에서만 별도 카메라 촬영 메뉴를 제공하기 위한 기능
                                            if (!kIsWeb)
                                              ListTile(
                                                leading: const Icon(
                                                    Icons.photo_camera),
                                                title: const Text('카메라로 촬영'),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  final ImagePicker picker =
                                                      ImagePicker();
                                                  // 모바일 촬영 이미지의 업로드 용량을 줄이기 위한 기능
                                                  final XFile? image =
                                                      await picker.pickImage(
                                                    source: ImageSource.camera,
                                                    maxWidth: 1024,
                                                    maxHeight: 1024,
                                                    imageQuality: 85,
                                                  );
                                                  if (image != null) {
                                                    setState(() {
                                                      _profileImage = image;
                                                    });
                                                    await _uploadImage(image);
                                                  }
                                                },
                                              ),
                                            if (_profileImageUrl != null)
                                              ListTile(
                                                leading:
                                                    const Icon(Icons.delete),
                                                title: const Text('프로필 사진 삭제'),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  await _deleteProfileImage();
                                                },
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEDEDED),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'images/upload_photo.png',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 30),
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
                    const SizedBox(width: 8),
                    if (_validateUserNm)
                      const Text(
                        '이름을 입력해 주세요',
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
                  controller: userNmCon,
                  decoration: getInputDecoration(
                    '이름을 입력해 주세요',
                    isError: _validateUserNm,
                  ).copyWith(
                    fillColor: Colors.white, // 배경색을 화이트로 설정
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '이메일주소',
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFAA4743),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCon,
                  decoration: getInputDecoration('이메일을 입력해 주세요',
                      isError: _validateEmail),
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
                    const SizedBox(width: 8),
                    if (_validatePhone)
                      const Text(
                        '연락처를 입력해 주세요',
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
                  controller: phoneCon,
                  decoration: getInputDecoration('연락처를 입력해 주세요',
                      isError: _validatePhone),
                ),
                const SizedBox(height: 30),
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
                  decoration:
                      getInputDecoration('YYYY.MM.DD', isError: _validateBym)
                          .copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month,
                          color: Color(0xFF555555)),
                      onPressed: _pickBirthDate,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    BymInputFormatter(),
                  ],
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
                            fontWeight: FontWeight.w500,
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
                            decoration: getInputDecoration('우편번호',
                                isError: _validateZipCd // 우편번호 미입력 시 에러 처리
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
                                  builder: (context) =>
                                      KakaoAddressSearchScreen(),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  zipCdCon.text = result['zipCd'];
                                  addrCon.text = result['roadAddress'];
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: const BorderSide(
                                  color: Color(0xFF555555), width: 1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                            ),
                            child: const Text(
                              '주소찾기',
                              style: TextStyle(
                                fontSize: 18, // 텍스트 크기
                                fontWeight: FontWeight.w500, // 텍스트 굵기
                                color: Color(
                                    0xFF555555), // 텍스트 색상 (foregroundColor와 동일하게 설정)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 주소 입력 필드
                    TextFormField(
                      controller: addrCon,
                      readOnly: true,
                      decoration: getInputDecoration('주소',
                          isError: _validateAddr && addrDtlCon.text.isEmpty),
                    ),
                    const SizedBox(height: 8),
                    // 상세 주소 입력 필드
                    TextFormField(
                      controller: addrDtlCon,
                      decoration: getInputDecoration('상세 주소를 입력해 주세요',
                          isError: _validateAddr && addrDtlCon.text.isEmpty),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3, // 좌측 title 영역
                        child: Text(
                          '육체활동 설정',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _validateActivityLevel
                                  ? Color(0xFFAA4743)
                                  : Color(0xFF555555), // 설정하지 않으면 빨간색
                              width: 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(12.0), // 모서리 둥글게
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 16.0), // 내부 여백
                          child: DropdownButtonHideUnderline(
                            // 기본 밑줄 제거
                            child: DropdownButton<String>(
                              value: currentActivityLevel,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16.0),
                              hint: Center(
                                child: Text(
                                  '선택',
                                  style: TextStyle(
                                      color: Color(0xFF555555),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'LOW',
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center, // 수직 가운데 정렬
                                    children: [
                                      SizedBox(
                                        width: 100, // "좌업자" 텍스트의 고정 너비
                                        child: Text('좌업자',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '일일활동량 30분 미만',
                                          style: TextStyle(
                                              color: Color(0xFF00914B),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'NORMAL',
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 100, // "보통활동"과 동일한 너비
                                        child: Text('보통활동',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '일일활동량 30분에서 60분 사이',
                                          style: TextStyle(
                                              color: Color(0xFF00914B),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'HIGH',
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 100, // "많은 육체활동"과 동일한 너비
                                        child: Text('많은 육체활동',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '일일활동량 60분 이상',
                                          style: TextStyle(
                                              color: Color(0xFF007331),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
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
                SizedBox(height: 30),
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
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
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
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 54),
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
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400),
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
                SizedBox(height: 40),
                SizedBox(
                    width: double.infinity, // 버튼이 부모 너비에 맞게 확장됨
                    height: 56, // 버튼 높이 설정
                    child: ElevatedButton(
                      onPressed: _isAgreed ? _saveUserInfo : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isAgreed ? const Color(0xFF007331) : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: const Text(
                        '저장하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )),
                SizedBox(height: 40),
                // Row(
                //   children: const [
                //     Text(
                //       '회원탈퇴',
                //       style: TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.w500,
                //         color: Color(0xFF555555),
                //       ),
                //     ),
                //     Icon(Icons.chevron_right, color: Color(0xFF555555)),
                //   ],
                // ),
                // SizedBox(height: 60)
              ],
            ),
          ),
        ),
      ),
    );
  }
/*
  Widget _editProfileButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('갤러리에서 선택'),
                    onTap: () async {
                      Navigator.pop(context);
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          _profileImage = image;
                        });
                        await _uploadImage(image);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('카메라로 촬영'),
                    onTap: () async {
                      Navigator.pop(context);
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        setState(() {
                          _profileImage = image;
                        });
                        await _uploadImage(image);
                      }
                    },
                  ),
                  if (_profileImageUrl != null)
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('프로필 사진 삭제'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _deleteProfileImage();
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
      child: const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Icon(Icons.edit, color: Colors.blue),
      ),
    );
  }

  Widget _buildUserInfoCard({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(value),
        ),
      ),
    );
  }
  */

  Future<void> _getProfileImage() async {
    try {
      ApiService apiService = ApiService();
      print('Fetching profile image for user: $userId');

      Map<String, dynamic> result =
          await apiService.fetchProfileImage(userId.toString());
      //print('Profile image API response: $result');

      final profileImageUrl = apiService.extractProfileImageUrl(result);
      if (result['success'] == true && profileImageUrl != null) {
        print('Setting profile image URL: $profileImageUrl');
        setState(() {
          _profileImageUrl = profileImageUrl;
          widget.onProfileImageChange(_profileImageUrl); // main화면의 상태 업데이트
        });
      } else {
        print('Failed to get profile image: ${result['message']}');
        setState(() {
          _profileImageUrl = null;
        });
        widget.onProfileImageChange(null);
      }
    } catch (e) {
      print('Error getting profile image: $e');
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      setState(() {
        _isLoading = true;
      });

      ApiService apiService = ApiService();
      var result = await apiService.uploadProfileImage(
        userId.toString(),
        await image.readAsBytes(), // XFile을 bytes로 변환
        image.name, // 파일 이름 전달
      );

      if (result['success'] == true) {
        await _getProfileImage();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 이미지가 업로드되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '이미지 업로드에 실패했습니다: ${result['message'] ?? '서버 응답을 확인해 주세요.'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 업로드에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      ApiService apiService = ApiService();
      var result = await apiService.deleteProfileImage(
        userId.toString(),
      );

      if (result['success'] == true) {
        setState(() {
          _profileImage = null;
          _profileImageUrl = null;
        });
        widget.onProfileImageChange(null); // main화면의 상태 업데이트
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 이미지가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 삭제에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
