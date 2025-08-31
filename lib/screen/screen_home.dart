import 'package:Vincere/page_ble_device/page_ble_connect.dart';
import 'package:Vincere/component/card_muscle_result.dart';
import 'package:Vincere/custom_widget/custom_button.dart';
import 'package:Vincere/custom_widget/custom_text.dart';
import 'package:Vincere/page_health/screen_my_health_info.dart';
import 'package:Vincere/page_account/screen_my_page.dart';
import 'package:Vincere/page_notice/screen_newsboard_list.dart';
import 'package:Vincere/page_workout/page_statistics.dart';
import 'package:Vincere/provider_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:math' show max;
import 'package:flutter/services.dart';

import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/export/screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../component/metric_chart_dialog.dart';
import '../page_nutrition/screen_nutrition_info_popup.dart';

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({
    super.key,
    required this.title,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController; // 하단 홈, 마이페이지 등의 버튼 컨트롤러
  int _selectedIndex = 0; // 하단 홈, 마이페이지 등의 버튼 선택 숫자
  bool _isLogIn = false;
  String? userId;
  String? password;
  Map<String, dynamic>? userData; // 마이페이지 회원 정보
  List<Map<String, dynamic>> userHlthData = []; // 마이페이지 회원 건강 정보
  List<Map<String, dynamic>> userPscpData = []; // 마이페이지 회원 처방 정보
  List<Map<String, dynamic>> userGradeData = []; // 회원 등급 정보
  List<Map<String, dynamic>> carbsFoodListData = []; // 탄수화물 기준 추천 리스트
  List<Map<String, dynamic>> proteinFoodListData = []; // 단백질 기준 추천 리스트
  List<Map<String, dynamic>> muscleAgeData = []; // 근육나이 리스트

  List<Map<String, dynamic>>? msmtItemData; // 측정항목 정보

  bool _isLoading = false;
  XFile? _profileImage;
  String? _profileImageUrl; // 프로필 이미지 URL 저장용 변수 추가
  int _futureBuilderKey = 0;

  double recEnergy = 0;
  double recDailyEnergy = 0;
  double recBreakfastEnergy = 0;
  double recLunchEnergy = 0;
  double recDinnerEnergy = 0;

  double breakfastRice = 0;
  double lunchRice = 0;
  double dinnerRice = 0;
  double totalRice = 0;

  double carbCalories = 0;
  double proteinCalories = 0;
  double totalCalories = 0;

  double recBreakfastCal = 0;
  double recLunchCal = 0;
  double recDinnerCal = 0;

  double recCarbs = 0; // 탄수화물 권장량
  double recProtein = 0; // 단백질 권장량
  double recBreakfastCarbs = 0; // 아침 탄수화물 권장량
  double recBreakfastProtein = 0; // 아침 단백질 권장량
  double recLunchCarbs = 0; // 점심 탄수화물 권장량
  double recLunchProtein = 0; // 점심 단백질 권장량
  double recDinnerCarbs = 0; // 저녁 탄수화물 권장량
  double recDinnerProtein = 0; // 저녁 단백질 권장량

  double dailyCarbsLackCal = 0;
  double dailyProteinLackCal = 0;

  int msmt003Grade = 0; // 신체질량지수
  int msmt008Grade = 0; // 체지방률
  int msmt011Grade = 0; // 악력
  int msmt012Grade = 0; // 걷기
  int msmt013Grade = 0; // 앉았다 일어서기
  double gradeAvg = 0.0; // 평균등급

  int userAge = 0;
  double muscleAmt = 0;
  String muscleAge = "--";

  double foodRecCarbsCal = 0;
  double foodRecProteinCal = 0;

  String strRec = "";

  bool isExpanded1 = false;
  bool isExpanded2 = false;

  late Future<List<Map<String, dynamic>>> healthInfoItemsFuture;

  // 초기 설정
  @override
  void initState() {
    super.initState();
    _initializeData();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() => _selectedIndex = _tabController.index));

    _initializeHealthInfo();
  }

  // 새로운 초기화 메서드
  Future<void> _initializeData() async {
    try {
      await _loadSessionData(); // check is login
      if (_isLogIn) {
        // 사용자 정보 먼저 로드
        await _getUserInfo();
        await _getUserHlthInfo();
        await _getMuscleAgeList();
        await _alertLastMstmtDte();

        double stdWeight = 0; // 기본값 설정
        final msmtValue = userHlthData
                .firstWhere(
                  (item) => item['MSMT_ITEM_CD'] == 'MSMT_004',
                  orElse: () => {'MSMT_VALUE': '0'},
                )['MSMT_VALUE']
                ?.toString() ??
            '';

        stdWeight = msmtValue.isEmpty ? 0 : (double.tryParse(msmtValue) ?? 0);
        print('Final stdWeight: $stdWeight'); // 최종 값 확인=

        // 일일 에너지 계산
        print("일일 에너지 계산 확인중 : $userData");
        recDailyEnergy = calculateEnergy(stdWeight, userData?["activityLevel"] ?? "LOW");

        // 나머지 데이터 로드
        await _getUserPscpInfo();
        await _getUserGrades();
        await _getProfileImage();
        await calculateIntakes();
        calculateRecCalories(); // 권장 칼로리 계산
        calculateRecFoodCalories(); // 추천 식품에 사용할 탄수화물, 단백질 칼로리 설정
        await _getRcmdFoodList(); // 추천 식품 목록 조회

        // 모든 데이터가 준비되면 UI 업데이트
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  void updateProfileImage(String? url) {
    setState(() {
      // 마이페이지용 콜백함수
      _profileImageUrl = url;
    });
  }

  void updateActivityLevl(String? actLevl) {
    setState(() {
      userData?["activityLevel"] = actLevl;
    });
  }

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

  // 회원 정보 가져오기
  Future<void> _getUserInfo() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetUserInfo(userId.toString());

      setState(() {
        userData = result["userOne"];
        print("getUserInfo의 userData 확인 !!! : $userData");
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  // 회원 건강 정보 가져오기
  Future<void> _getUserHlthInfo() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetUserHlthInfo(userId.toString());
      print("result 확인해야함 >>> $result");

      if (result.containsKey('listResultMap')) {
        setState(() {
          userHlthData = List<Map<String, dynamic>>.from(result["listResultMap"]);
          print("_getUserHlthInfo의 userHlthData 확인중 !!!!!! $userHlthData");

          // 근육량 계산
          var msmt002Value = double.parse(userHlthData.firstWhere(
                  //-- 체중
                  (data) => data['MSMT_ITEM_CD'] == 'MSMT_002',
                  orElse: () => {'MSMT_VALUE': '0'})['MSMT_VALUE'] ??
              '0');

          var msmt008Value = double.parse(userHlthData.firstWhere(
                  //-- 체지방률
                  (data) => data['MSMT_ITEM_CD'] == 'MSMT_008',
                  orElse: () => {'MSMT_VALUE': '0'})['MSMT_VALUE'] ??
              '0');

          // 체지방량 = 체중 * 체지방률
          var fatAmt = msmt002Value * msmt008Value * 0.01;
          // 근육량 = 체중 - 체지방량
          muscleAmt = msmt002Value - fatAmt;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 회원 건강 정보 가져오기
  Future<void> _alertLastMstmtDte() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.getLastMstmtDte(userId.toString());
      print("result 확인해야함111 >>> $result");

      if (result.containsKey('LAST_MSMT_DAT')) {
        setState(() {
          String lastMsmtDte = result['LAST_MSMT_DAT'];

          // 현재 날짜와 마지막 측정일 비교
          DateTime lastMeasureDate = DateTime.parse(lastMsmtDte);
          DateTime currentDate = DateTime.now();

          // 정확한 3,6,9개월 전 날짜 계산
          DateTime threeMonthsAgo = DateTime(currentDate.year, currentDate.month - 3, currentDate.day);
          DateTime sixMonthsAgo = DateTime(currentDate.year, currentDate.month - 6, currentDate.day);
          DateTime nineMonthsAgo = DateTime(currentDate.year, currentDate.month - 9, currentDate.day);

          // 마지막 측정일이 3/6/9개월 이전 일자일 경우 알림창 출력
          if (lastMeasureDate.isAtSameMomentAs(threeMonthsAgo) || lastMeasureDate.isAtSameMomentAs(sixMonthsAgo) || lastMeasureDate.isAtSameMomentAs(nineMonthsAgo)) {
            // 알림창 표시
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    '알림',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      letterSpacing: -0.02,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Text(
                    '변경된 건강 정보가 있다면 입력해 주세요.최신 사항을 반영 하겠습니다.',
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      child: Text(
                        '닫기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007130),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 회원 최신 처방 정보 가져오기
  Future<void> _getUserPscpInfo() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetLstPscpInfo(userId.toString());

      if (result.containsKey('lstPscpList')) {
        setState(() {
          userPscpData = List<Map<String, dynamic>>.from(result['lstPscpList']);
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _getUserGrades() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetUserGrades(
        userId.toString(),
        userData?["bym"] ?? '',
      );
      print("여기 오나???");
      print("result ??? : $result");
      print("userAge ??? : $userAge");

      if (result.containsKey('userGradeList')) {
        try {
          // setState 내부에 별도의 try-catch 추가
          setState(() {
            // 변수들 초기화
            msmt003Grade = 0;
            msmt008Grade = 0;
            msmt011Grade = 0;

            userGradeData = List<Map<String, dynamic>>.from(result['userGradeList']);
            print("userGradeData ====== $userGradeData");

            // 데이터 처리 전에 값 확인
            print("초기 grade 값들:");
            print("msmt003Grade: $msmt003Grade");
            print("msmt008Grade: $msmt008Grade");
            print("msmt011Grade: $msmt011Grade");

            for (int i = 0; i < userGradeData.length; i++) {
              String itemCd = userGradeData[i]['MSMT_ITEM_CD'];
              dynamic itemValue = userGradeData[i]['GRADE'];

              print("처리중인 항목 - CD: $itemCd, Value: $itemValue (${itemValue.runtimeType})");

              print("itemCd 확인중 : $itemCd");
              print("itemValue 확인중 : $itemValue");

              if (itemValue != null) {
                switch (itemCd) {
                  case 'MSMT_003':
                    msmt003Grade = itemValue;
                    break;
                  case 'MSMT_008':
                    msmt008Grade = itemValue;
                    break;
                  case 'MSMT_011':
                    msmt011Grade = itemValue;
                    break;
                  case 'MSMT_012':
                    msmt012Grade = itemValue;
                    break;
                  case 'MSMT_013':
                    msmt013Grade = itemValue;
                    break;
                }
              }
            }
            print("데이터 처리 후 grade 값들:");
            print("msmt003Grade: $msmt003Grade");
            print("msmt008Grade: $msmt008Grade");
            print("msmt011Grade: $msmt011Grade");

            // grade 값들이 모두 유효한지 확인   userAge
            if ((msmt003Grade != 0 && msmt008Grade != 0 && msmt011Grade != 0) && userAge < 40) {
              // 40세 미만인 경우
              // 평균등급 구하기
              gradeAvg = double.parse(((msmt003Grade + msmt008Grade + msmt011Grade) / 3).toStringAsFixed(1));
            } else if ((msmt003Grade != 0 && msmt008Grade != 0 && msmt011Grade != 0 && msmt012Grade != 0 && msmt013Grade != 0) && userAge >= 40) {
              print("msmt012Grade : $msmt012Grade");
              print("msmt013Grade : $msmt013Grade");

              // 평균등급 구하기
              gradeAvg = double.parse(((msmt003Grade + msmt008Grade + msmt011Grade + msmt012Grade + msmt013Grade) / 5).toStringAsFixed(1));
            } else {
              print("일부 grade 값이 null입니다");
              print("msmt003Grade: $msmt003Grade");
              print("msmt008Grade: $msmt008Grade");
              print("msmt011Grade: $msmt011Grade");

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color(0xFFFFFFFF),
                    // insetPadding: EdgeInsets.symmetric(horizontal: 24),
                    // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                    title: Text(
                      '알림',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        letterSpacing: -0.02,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: Text('데이터를 입력하고 내 근육 나이를 지금 확인해 보세요!'),
                    actions: <Widget>[
                      ElevatedButton(
                        child: Text(
                          '닫기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF007130),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }

            double? maxGrd = 0.0;
            double? minGrd = 0.0;
            double? ageAdj = 0.0;

            if ((muscleAgeData != null && muscleAgeData.length > 0) && (userAge != null && userAge != 0)) {
              for (int i = 0; i < muscleAgeData.length; i++) {
                maxGrd = double.tryParse(muscleAgeData[i]['MAX_GRADE'].toString() ?? '0');
                minGrd = double.tryParse(muscleAgeData[i]['MIN_GRADE'].toString() ?? '0');
                ageAdj = double.tryParse(muscleAgeData[i]['MUSCLE_AGE_ADJ'].toString() ?? '0');

                if ((maxGrd != null && minGrd != null && ageAdj != null) && (gradeAvg >= minGrd && gradeAvg <= maxGrd)) {
                  muscleAge = (userAge + ageAdj).toString();
                }
              }
            } else {
              gradeAvg = 0.0;
              muscleAge = "--";
              print("일부 grade 값이 0입니다");
            }
          });
        } catch (e, stackTrace) {
          print('setState 내부 에러: $e');
          print('에러 발생 위치: $stackTrace'); // 스택트레이스 추가
        }
      }
    } catch (e) {
      print('전체 Error: $e');
    }
  }

  // 로그인 세션에 아이디와 비밀번호 없을 시 알람
  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('사용 불가'),
        content: Text('로그인을 하셔야 이용 가능합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            ),
            child: Text('로그인 하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // '아니오'를 선택하면 알림창만 닫힘
            },
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // 프로필 이미지 가져오기
  Future<void> _getProfileImage() async {
    try {
      ApiService apiService = ApiService();
      print('Fetching profile image for user: $userId');

      Map<String, dynamic> result = await apiService.fetchProfileImage(userId.toString());
      print('Profile image API response: $result');

      if (result['success'] == true && result['imageUrl'] != null) {
        print('Setting profile image URL: ${result['imageUrl'].substring(0, 50)}...');
        setState(() {
          _profileImageUrl = result['imageUrl'];
        });
      } else {
        print('Failed to get profile image: ${result['message']}');
      }
    } catch (e) {
      print('Error getting profile image: $e');
    }
  }

  Widget _buildProfileImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: _profileImageUrl != null
          ? ClipOval(
              child: Image.network(
                _profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _defaultProfileIcon();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                    ),
                  );
                },
              ),
            )
          : _defaultProfileIcon(),
    );
  }

  Widget _defaultProfileIcon() {
    return CircleAvatar(
      radius: 58,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 35,
        color: Colors.grey[600],
      ),
    );
  }

  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String calculateAge(String bym) {
    if (bym.length != 8) return "--"; // 생년월일 형식이 맞지 않을 경우

    try {
      // bym이 'YYYYMMDD' 형식일 경우
      int birthYear = int.parse(bym.substring(0, 4));
      int birthMonth = int.parse(bym.substring(4, 6));
      int birthDay = int.parse(bym.substring(6, 8));

      DateTime birthDate = DateTime(birthYear, birthMonth, birthDay);
      DateTime currentDate = DateTime.now();

      int age = currentDate.year - birthDate.year;

      // 생일이 아직 지나지 않았다면 1을 빼줌
      if (currentDate.month < birthDate.month || (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age--;
      }

      userAge = age;
      print("ageeee : $age");

      return age.toString();
    } catch (e) {
      print('Error calculating age: $e');
      return "0";
    }
  }

  // 일일에너지 필요량 계산
  double calculateEnergy(double stdWeight, String activityLevel) {
    try {
      print("stdWeight : $stdWeight");
      print("activityLevel : $activityLevel");

      if (stdWeight <= 0) {
        print('Invalid standard weight');
        return 0;
      }

      double activityFactor1;
      double activityFactor2;
      switch (activityLevel) {
        case 'LOW':
          activityFactor1 = 25;
          activityFactor2 = 30;
          print('Activity Level: LOW (좌업자)');
        case 'NORMAL':
          activityFactor1 = 30;
          activityFactor2 = 35;
          print('Activity Level: NORMAL (보통활동)');
        case 'HIGH':
          activityFactor1 = 35;
          activityFactor2 = 40;
          print('Activity Level: HIGH (육체활동)');
        default:
          activityFactor1 = 0;
          activityFactor2 = 0;
      }
      recDailyEnergy = ((stdWeight * activityFactor1) - activityFactor2);
      calculateRecCalories();
      print("recDailyEnergy : $recDailyEnergy");
      return recDailyEnergy;
    } catch (e) {
      print('Error calculating energy: $e');
      return 0;
    }
  }

  double calculateRecCalories() {
    print("recDailyEnergy : $recDailyEnergy");

    print("breakfastRice : $breakfastRice"); // 아침에 먹은 탄수화물 양

    recEnergy = recDailyEnergy / 3; // 한끼 권장 칼로리
    recCarbs = recDailyEnergy / 3 * 0.55; // 탄수화물 일일권장량
    recProtein = recDailyEnergy / 3 * 0.3; // 단백질 일일권장량
    print("recCarbs : $recCarbs");
    print("recProtein : $recProtein");

    // 아침 권장량
    recBreakfastEnergy = recEnergy - breakfastRice * 1.46;
    recBreakfastCarbs = recCarbs - breakfastRice * 1.32;
    recBreakfastProtein = recProtein - breakfastRice * 0.092;
    print("recBreakfastCarbs 확인 : $recBreakfastCarbs");
    print("recBreakfastProtein 확인 : $recBreakfastProtein");

    // 점심 권장량
    print("breakfastRice양 확인 : $breakfastRice");
    // recLunchCarbs = breakfastRice != 0 ? recCarbs + recBreakfastCarbs/2 - (lunchRice * 1.32) : recCarbs - (lunchRice * 1.32);
    // recLunchCarbs = recCarbs + recBreakfastCarbs/2 - (lunchRice * 1.32);
    // recLunchProtein = breakfastRice != 0 ? recProtein + recBreakfastProtein/2 - (lunchRice * 0.092) : recProtein - (lunchRice * 0.092);
    // recLunchProtein = recProtein + recBreakfastProtein/2 - (lunchRice * 0.092);
    recLunchEnergy = recEnergy - (lunchRice * 1.46);
    recLunchCarbs = recCarbs - (lunchRice * 1.32);
    recLunchProtein = recProtein - (lunchRice * 0.092);

    recDinnerEnergy = recEnergy - (dinnerRice * 1.46);
    recDinnerCarbs = recCarbs - (dinnerRice * 1.32);
    recDinnerProtein = recProtein - (dinnerRice * 0.092);

    if (breakfastRice != 0) {
      // 아침 섭취량이 입력된 경우
      recLunchEnergy = recLunchEnergy + recBreakfastEnergy / 2; // 점심 권장 칼로리 = 점심 권장 칼로리 + (아침 부족or초과분)/2
      recLunchCarbs = recLunchCarbs + recBreakfastCarbs / 2; // 점심 권장 탄수화물 = 점심 권장 탄수화물 + (아침 부족or초과분)/2
      recLunchProtein = recLunchProtein + recBreakfastProtein / 2; // 점심 권장 단백질 = 점심 권장 단백질 + (아침 부족or초과분)/2

      recDinnerEnergy = recDinnerEnergy + recBreakfastEnergy / 2; // 저녁 권장 칼로리 = 저녁 권장 칼로리 + (아침 부족or초과불)/2
      recDinnerCarbs = recDinnerCarbs + recBreakfastCarbs / 2; // 저녁 권장 탄수화물 = 저녁 권장 탄수화물 + (아침 부족or초과분)/2
      recDinnerProtein = recDinnerProtein + recBreakfastProtein / 2; // 저녁 권장 단백질 = 저녁 권장 단백질 + (아침 부족or초과분)/2
    }

    if (lunchRice != 0) {
      // 점심 섭취량이 입력된 경우
      recDinnerEnergy = recDinnerEnergy + recLunchEnergy;
      recDinnerCarbs = recDinnerCarbs + recLunchCarbs;
      recDinnerProtein = recDinnerProtein + recLunchProtein;
    }

    if (dinnerRice != 0) {
      // 저녁 섭취량이 입력된 경우, 부족 칼로리 계산 진행
      // 일일 에너지 권장량 - 아침/점심/저녁 섭취 칼로리
      dailyCarbsLackCal = recDailyEnergy * 0.55 - (breakfastRice + lunchRice + dinnerRice) * 1.32;
      dailyProteinLackCal = recDailyEnergy * 0.3 - (breakfastRice + lunchRice + dinnerRice) * 0.092;

      print("dailyCarbsLackCal 111 : $dailyCarbsLackCal");
      dailyCarbsLackCal = dailyCarbsLackCal > 0 ? dailyCarbsLackCal.round() as double : 0;
      dailyProteinLackCal = dailyProteinLackCal > 0 ? dailyProteinLackCal.round() as double : 0;

      print("dailyCarbsLackCal : $dailyCarbsLackCal");
      print("dailyProteinLackCal : $dailyProteinLackCal");
    }

    checkNegativeValues();

    print("recLunchCarbs 확인 : $recLunchCarbs");
    print("recLunchProtein 확인 : $recLunchProtein");

    // 저녁 권장량
    // recDinnerCarbs = lunchRice
    // recDinnerCarbs = recCarbs + recBreakfastCarbs/2 + recLunchCarbs - (dinnerRice * 1.32);
    // recDinnerProtein = recProtein + recBreakfastProtein/2 + recLunchProtein - (dinnerRice * 0.092);
    print("recDinnerCarbs 확인 : $recDinnerCarbs");
    print("recDinnerProtein 확인 : $recDinnerProtein");

    return 0;
  }

  // 끼니별 쌀 섭취량이 0이 아닐 경우에는 권장량 대신 섭취량 출력
  void checkNegativeValues() {
    recBreakfastEnergy = breakfastRice != 0 ? breakfastRice * 1.46 : recBreakfastEnergy;
    recBreakfastCarbs = breakfastRice != 0 ? breakfastRice * 1.32 : recBreakfastCarbs;
    recBreakfastProtein = breakfastRice != 0 ? breakfastRice * 0.092 : recBreakfastProtein;

    recLunchEnergy = lunchRice != 0 ? lunchRice * 1.46 : recLunchEnergy;
    recLunchCarbs = lunchRice != 0 ? lunchRice * 1.32 : recLunchCarbs;
    recLunchProtein = lunchRice != 0 ? lunchRice * 0.092 : recLunchProtein;

    recDinnerEnergy = dinnerRice != 0 ? dinnerRice * 1.46 : recDinnerEnergy;
    recDinnerCarbs = dinnerRice != 0 ? dinnerRice * 1.32 : recDinnerCarbs;
    recDinnerProtein = dinnerRice != 0 ? dinnerRice * 0.092 : recDinnerProtein;
  }

  // 추천식품을 위한 탄수화물, 단백질 필요 칼로리
  Map<String, int> calculateRecFoodCalories() {
    print("=======섭취량 확인=======");
    print("아침 : $breakfastRice");
    print("점심 : $lunchRice");
    print("저녁 : $dinnerRice");

    if (breakfastRice == 0) {
      foodRecCarbsCal = recBreakfastCarbs;
      foodRecProteinCal = recBreakfastProtein;
      strRec = "아침";
    }

    if (breakfastRice != 0) {
      // 아침 섭취량이 입력된 경우
      foodRecCarbsCal = recLunchCarbs; // 점심 권장 탄수화물 칼로리를 기준으로 함
      foodRecProteinCal = recLunchProtein; // 점심 권장 단백질 칼로리를 기준으로 함
      strRec = "점심";
    }

    if (lunchRice != 0) {
      // 점심 섭취량이 입력된 경우
      foodRecCarbsCal = recDinnerCarbs; // 저녁 권장 탄수화물 칼로리를 기준으로 함
      foodRecProteinCal = recDinnerProtein; // 저녁 권장 단백질 칼로리를 기준으로 함
      strRec = "저녁";
    }

    if (dinnerRice != 0) {
      // 저녁 섭취량이 입력된 경우
      foodRecCarbsCal = 0;
      foodRecProteinCal = 0;
      strRec = "";
    }

    print("calculateRecFoodCalories의 foodRecCarbsCal : $foodRecCarbsCal");
    print("calculateRecFoodCalories의 foodRecProteinCal : $foodRecProteinCal");

    return {
      'foodRecCarbsCal': foodRecCarbsCal.round(),
      'foodRecProteinCal': foodRecProteinCal.round(),
    };
  }

  Future<void> _getRcmdFoodList() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetRcmdFoodList(foodRecCarbsCal, foodRecProteinCal);

      print("_getRcmdFoodList의 result 확인 : $result");

      if (result.containsKey('carbsFoodMap') && foodRecCarbsCal > 0) {
        setState(() {
          if (foodRecCarbsCal > 0) {
            carbsFoodListData = List<Map<String, dynamic>>.from(result["carbsFoodMap"]);
          } else {
            carbsFoodListData = [];
          }
          print(" carbsFoodListData 있다 ======> $carbsFoodListData");
        });
      }

      if (result.containsKey('proteinFoodMap')) {
        setState(() {
          if (foodRecProteinCal > 0) {
            proteinFoodListData = List<Map<String, dynamic>>.from(result["proteinFoodMap"]);
          } else {
            proteinFoodListData = [];
          }
          print(" proteinFoodListData 확인 ======> $proteinFoodListData");
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Map<String, dynamic> calculateCalorie(double intake) {
    try {
      int carbCalorie = (intake * 1.32).round();
      // String carbCalorie = (((intake * 1.32) * 10).round()/10).toStringAsFixed(1);
      int proteinCalorie = (intake * 0.092).round();
      // String proteinCalorie = (((intake * 0.092) * 10).round()/10).toStringAsFixed(1);
      // double totalCalorie = carbCalorie + proteinCalorie;  // 총 칼로리
      int totalCalorie = (intake * 1.46).round(); // 총 칼로리
      // String totalCalorie = (((intake * 1.46) * 10).round()/10).toStringAsFixed(1); // 총 칼로리
      // (((intake * 1.46) * 10).round()/10).toStringAsFixed(1)

      return {
        'total': totalCalorie,
        'carb': carbCalorie,
        'protein': proteinCalorie,
      };
    } catch (e) {
      print('Error calculating calorie: $e');
      return {
        'total': 0,
        'carb': 0,
        'protein': 0,
      };
    }
  }

  // 섭취량 가져오기
  Future<Map<String, dynamic>> getRiceIntake() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchRiceIntake(userId.toString());
      print("result 확인 : $result");
      if (result != null) {
        return result;
      }
      return {};
    } catch (e) {
      print('Error getting rice intake: $e');
      return {};
    }
  }

  // 쌀 섭취량 입력
  Future<void> insertRiceIntake(String mealType, double amount) async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.insertRiceIntake(
        userId.toString(),
        mealType,
        amount,
      );
      print("insertRiceIntake의 result 확인 : $result");
      print("insertRiceIntake의 result['BREAKFAST'] 확인 : ${result['BREAKFAST']}");

      // mounted 체크 추가
      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('섭취량이 입력되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 아침/점심/저녁 섭취량을 double로 변환 (null이면 0으로 처리)
        breakfastRice = double.tryParse(result['BREAKFAST']?.toString() ?? '0') ?? 0;
        lunchRice = double.tryParse(result['LUNCH']?.toString() ?? '0') ?? 0;
        dinnerRice = double.tryParse(result['DINNER']?.toString() ?? '0') ?? 0;

        // 총 쌀 섭취량 계산
        totalRice = breakfastRice + lunchRice + dinnerRice;

        // 탄수화물과 단백질 칼로리 계산
        carbCalories = totalRice * 1.32; // 쌀의 탄수화물 비율 37%, 탄수화물 1g당 4kcal
        proteinCalories = totalRice * 0.092; // 쌀의 단백질 비율 2.5%, 단백질 1g당 4kcal
        totalCalories = carbCalories + proteinCalories;

        // FutureBuilder 새로고침을 위해 key 값 변경
        if (mounted) {
          setState(() {
            _futureBuilderKey++;
          });
        }

        calculateRecCalories();
        calculateRecFoodCalories();
        _getRcmdFoodList();
        // 필요한 경우 데이터 새로고침
        // _getUserInfo();
        // _getUserHlthInfo();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('섭취량 입력에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error inserting rice intake: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, double>> calculateIntakes() async {
    try {
      // 쌀 섭취량 데이터 가져오기
      Map<String, dynamic> riceIntake = await getRiceIntake();

      // 아침/점심/저녁 섭취량을 double로 변환 (null이면 0으로 처리)
      breakfastRice = double.tryParse(riceIntake['BREAKFAST']?.toString() ?? '0') ?? 0;
      lunchRice = double.tryParse(riceIntake['LUNCH']?.toString() ?? '0') ?? 0;
      dinnerRice = double.tryParse(riceIntake['DINNER']?.toString() ?? '0') ?? 0;

      // 총 쌀 섭취량 계산
      totalRice = breakfastRice + lunchRice + dinnerRice;

      // 탄수화물과 단백질 칼로리 계산
      carbCalories = totalRice * 1.32; // 쌀의 탄수화물 비율 37%, 탄수화물 1g당 4kcal
      proteinCalories = totalRice * 0.092; // 쌀의 단백질 비율 2.5%, 단백질 1g당 4kcal
      totalCalories = carbCalories + proteinCalories;

      print("recDailyEnergy : $recDailyEnergy");
      recBreakfastCal = recDailyEnergy / 3;
      print("recBreakfastCal : $recBreakfastCal");
      recLunchCal = recDailyEnergy / 3;
      recDinnerCal = recDailyEnergy / 3;

      print("아침,점심,저녁 칼로리 : $recBreakfastCal, $recLunchCal, $recDinnerCal");

      return {
        'totalRice': totalRice, // 총 쌀 섭취량 (g)
        'totalCalories': totalCalories, // 총 칼로리
        'carbCalories': carbCalories, // 탄수화물 칼로리
        'proteinCalories': proteinCalories, // 단백질 칼로리
      };
    } catch (e) {
      print('Error calculating intakes: $e');
      return {
        'totalRice': 0,
        'totalCalories': 0,
        'carbCalories': 0,
        'proteinCalories': 0,
      };
    }
  }

  Future<void> _getMuscleAgeList() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.getMuscleAgeList();
      muscleAgeData = List<Map<String, dynamic>>.from(result["list"]);

      print("getMuscleAgeList muscleAgeData 확인 : $muscleAgeData");
    } catch (e) {
      print('Error fetching nutrition info: $e');
    }
  }

  Future<Map<String, String>> getNutritionInfo(String foodName) async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetNutritionInfo(foodName);
      print("result 확인 : $result");

      if (result['success'] == true) {
        return {
          '칼로리': '${result['calories']}kcal',
          '단백질': '${result['protein']}g',
          '탄수화물': '${result['carbs']}g',
          '지방': '${result['fat']}g',
          '나트륨': '${result['sodium']}mg',
          '총 제공량': '${result['serving_size']}g',
          '1회 섭취량': '${result['recommended_intake']}g',
        };
      } else {
        throw Exception('Failed to load nutrition info');
      }
    } catch (e) {
      print('Error fetching nutrition info: $e');
      return {}; // 또는 기본값 반환
    }
  }

  // 건강 정보 위젯 추출
  Widget _buildHealthInfo(String label, List<Map<String, dynamic>> data, String code, String unit) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        SizedBox(width: 4),
        Text(
            data
                    .firstWhere(
                      (item) => item['MSMT_ITEM_CD'] == code,
                      orElse: () => {'MSMT_VALUE': '--', 'MSMT_UNIT': unit},
                    )['MSMT_VALUE']
                    ?.toString() ??
                '--',
            style: TextStyle(fontSize: 12)),
        Text(unit),
      ],
    );
  }

  // 비동기 초기화를 위한 새로운 메서드
  Future<void> _initializeHealthInfo() async {
    final result = await _getMsmtItemInfo();
    print("result 확인 <<<<<<<>>>>>>>>>>> : $result");
    setState(() {
      healthInfoItemsFuture = Future.value(result);
      print("healthInfoItemsFuture : $healthInfoItemsFuture");
    });
  }

  Future<List<Map<String, dynamic>>> _getMsmtItemInfo() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.getHealthInfoItems();
      print("result 확인중 !?!?! : $result");

      // msmtList를 가져옴
      List<Map<String, dynamic>> msmtList = List<Map<String, dynamic>>.from(result["msmtList"]);
      print("msmtList@@@@@ : $msmtList");

      msmtItemData = msmtList;

      print("msmtItemData 확인 : $msmtItemData");

      // setState를 return 전에 실행
      // setState(() {
      //   healthInfoItemsFuture = msmtList;
      //   print("healthInfoItemsFuture 확인중 !?!?! : $healthInfoItemsFuture");
      // });

      return msmtList;
    } catch (e) {
      print('Error: $e');
      // 에러 발생 시 빈 리스트 반환 또는 에러 던지기
      return []; // 또는 throw e;
    }
  }

  // 정보 행을 만드는 헬퍼 메서드
  Widget _buildInfoRow({
    required String label,
    required String value,
    required BoxConstraints constraints,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: constraints.maxWidth < 400 ? 4 : 8,
        vertical: constraints.maxWidth < 400 ? 2 : 4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: constraints.maxWidth < 400 ? 12 : 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: constraints.maxWidth < 400 ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 테이블 헤더 셀 위젯
  Widget _buildTableHeader(String text) {
    if (text.contains('아침') || text.contains('점심') || text.contains('저녁')) {
      return Container(
        // padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        height: 76,
        color: Colors.white,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Color(0xFF000000),
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.white,
        // padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        height: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '총',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: Color(0xFF000000),
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF000000),
                  ),
                ),
                Text(
                  'Kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3),
            Text(
              '기준',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            // SizedBox(height: 14),
          ],
        ),
      );
    }
  }

// 테이블 데이터 셀 위젯
  Widget _buildTableCell(String text, {bool isHeader = false, String? str = ' '}) {
    double numericValue = 0;

    try {
      numericValue = double.parse(text);
    } catch (e) {
      // text가 숫자로 변환할 수 없는 경우 기본값 0 사용
      print("숫자로 변환할 수 없는 텍스트입니다: $text");
    }
    Color dotColor;
    Color numberColor;

    if (!isHeader && str != null && ((str.contains('recBreakfastCarbs') && breakfastRice > 0) || (str.contains('recBreakfastProtein') && breakfastRice > 0) || (str.contains('recLunchCarbs') && lunchRice > 0) || (str.contains('recLunchProtein') && lunchRice > 0) || (str.contains('recDinnerCarbs') && dinnerRice > 0) || (str.contains('recDinnerProtein') && dinnerRice > 0))) {
      dotColor = const Color(0xFFFABE00);
    } else if (!isHeader && str != null && str.contains('TotalRecKcal') && ((str == 'breakfastTotalRecKcal' && breakfastRice > 0) || (str == 'lunchTotalRecKcal' && lunchRice > 0) || (str == 'dinnerTotalRecKcal' && dinnerRice > 0))) {
      dotColor = const Color(0xFFFABE00);
    } else if (!isHeader && str != ' ') {
      dotColor = const Color(0xFFDEDEDE);
    } else {
      dotColor = const Color(0xFFF5F5F5);
    }

    if (!isHeader && str != null && str.contains('Carbs')) {
      numberColor = const Color(0xFF00914B);
    } else if (!isHeader && str != null && str.contains('Protein')) {
      numberColor = const Color(0xFF9D895B);
    } else {
      numberColor = const Color(0xFF000000);
    }

    List<Widget> children = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
        children: [
          SizedBox(width: 10),
          if (!isHeader) ...[
            Container(
              width: 10, // 동그라미 크기
              height: 10,
              margin: EdgeInsets.only(top: 10, bottom: 3),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
          if (isHeader) ...[
            SizedBox(height: 15),
          ],
        ],
        // SizedBox(height: 10),
      ),
      Row(
        // 새로운 Row 추가
        mainAxisAlignment: isHeader ? MainAxisAlignment.center : MainAxisAlignment.end, // 중앙 정렬
        //crossAxisAlignment: isHeader ? CrossAxisAlignment.center : CrossAxisAlignment.start,  // 추가: 세로 중앙 정렬
        children: [
          Text(
            // textAlign: TextAlign.center,
            isHeader ? text : '${numericValue.round()}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: numberColor,
            ),
          ),
          if (!isHeader && str != null && !str.contains('totalRecKcal')) ...[
            Text(
              'kcal',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Color(0xFF555555),
              ),
            ),
            SizedBox(width: 10),
          ],
          if (!isHeader && str != null && str.contains('totalRecKcal')) ...[
            Text(
              'kcal',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Color(0xFF000000),
              ),
            ),
            SizedBox(width: 10),
          ],
          // SizedBox(width: 8),
        ],
      ),
    ];

    if (!isHeader && str != null && ((str.contains('recBreakfastCarbs') && breakfastRice > 0) || (str.contains('recBreakfastProtein') && breakfastRice > 0) || (str.contains('recLunchCarbs') && lunchRice > 0) || (str.contains('recLunchProtein') && lunchRice > 0) || (str.contains('recDinnerCarbs') && dinnerRice > 0) || (str.contains('recDinnerProtein') && dinnerRice > 0))) {
      children.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // 우측 정렬
          children: [
            Text(
              '${(numericValue / 4).round().toString()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
              ),
            ),
            Text(
              'g',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
      ]);
    } else if (!isHeader && str != ' ' && str != null && !str.contains('TotalRecKcal')) {
      // 탄수화물 필요량 또는 단백질 필요량 cell인 경우
      children.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // 우측 정렬
          children: [
            Text(
              '${(numericValue / 4).round().toString()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
              ),
            ),
            Text(
              'g',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
      ]);
    } else if (!isHeader && str != ' ' && str != null && str.contains('totalRecKcal')) {
      children.addAll([
        SizedBox(height: 20),
      ]);
    }

    Color cellColor;
    switch (str) {
      case String s when s.contains('Carbs'):
        cellColor = const Color(0xFFF0F9F4);
      case String s when s.contains('Protein'):
        cellColor = const Color(0xFFF9F8F5);
      default:
        cellColor = const Color(0xFFF5F5F5);
        break;
    }

    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      height: 76,
      decoration: BoxDecoration(
        color: !isHeader ? cellColor : Colors.white, // 헤더일 때만 초록색 배경
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  // 표 행을 생성하는 helper 메소드
  Widget _buildTableRow(String foodId, String name, String totalAmt, double carb, double protein) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      // padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              // height: 60,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              // height: 60,
              child: Text(
                totalAmt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              // height: 60,
              // decoration: BoxDecoration(
              //   color: Color(0xFFE8F5E9), // 연한 초록색 배경
              //   borderRadius: BorderRadius.circular(4), // 선택적: 모서리를 둥글게
              // ),
              padding: EdgeInsets.zero,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${carb.toString()}\n',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00914B), // 초록색
                      ),
                    ),
                    TextSpan(
                      text: 'kcal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8D8D8D), // 검정색
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              // height: 60,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${protein.toString()}\n',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9D859B), // 초록색
                      ),
                    ),
                    TextSpan(
                      text: 'kcal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8D8D8D), // 검정색
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              // height: 30,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // API 호출하여 상세 영양정보 조회
                    ApiService apiService = ApiService();
                    Map<String, dynamic> result = await apiService.fetchGetNutritionInfo(foodId);
                    print("result 확인 : $result");

                    if (result != null) {
                      // final nutritionData = jsonDecode(response.body);

                      // 팝업 표시
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => NutritionInfoPopup(
                          foodName: name,
                          result: result,
                        ),
                      );
                    } else {
                      // 에러 처리
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('영양정보를 불러오는데 실패했습니다.')),
                      );
                    }
                  } catch (e) {
                    print('Error fetching nutrition info: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('영양정보 조회 중 오류가 발생했습니다.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  minimumSize: Size(40, 15),
                  backgroundColor: Color(0xFF555555),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  '영양정보',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 메트릭 행을 만드는 함수
  Widget _buildMetricRow(String category, String title, int grade, bool isBest, String code) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 0,
        horizontal: MediaQuery.of(context).size.width * 0.06, // 화면 너비의 6% 로 설정
      ),
      child: Row(
        children: [
          // 카테고리가 있을 경우에만 표시
          if (category.isNotEmpty) ...[
            SizedBox(
              width: 70,
              child: Text(
                category,
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          // 카테고리가 없는 경우 들여쓰기
          if (category.isEmpty) SizedBox(width: 70),
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (grade == 1) ...[
            SizedBox(width: 8),
            Container(
              //padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              width: 40,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF00914B),
                  width: 2, // 테두리 두께
                ),
              ),
              child: Text(
                'BEST',
                style: TextStyle(
                  color: Color(0xFF007130),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          SizedBox(width: 10),
          Text(
            '${grade.toString()}등급',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: grade == 1 ? Color(0xFF00914B) : (grade == 2 ? Color(0xFF9D895B) : Color(0xFF8D8D8D)),
            ),
            textAlign: TextAlign.center,
          ),
          IconButton(
            icon: Icon(
              Icons.bar_chart,
              color: Color(0xFF00914B),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return MetricChartDialog(title: title, code: code, userId: userId);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 건강 정보 지표를 위한 새로운 위젯
  Widget _buildHealthMetric(String label, List<dynamic> data, String code, String unit) {
    String value;
    if (code == 'muscleAmt') {
      value = ((muscleAmt * 10).round() / 10).toStringAsFixed(1);
    } else {
      value = ((double.parse(data
                              .firstWhere(
                                (item) => item['MSMT_ITEM_CD'] == code,
                                orElse: () => {'MSMT_VALUE': '0'},
                              )['MSMT_VALUE']
                              ?.toString() ??
                          '0') *
                      10)
                  .round() /
              10.0)
          .toStringAsFixed(1);
    }

    return Column(
      children: [
        Text(
          // 라벨(키, 몸무게 등) 위치를 위로 이동
          label,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFFFFFF).withOpacity(0.8),
          ),
        ),
        SizedBox(height: 2),
        Text(
          // 숫자 값
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2),
        Text(
          // 단위(cm, kg 등)만 아래에 표시
          unit,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFFFFFF).withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context); // 상태 접근

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: _isLogIn),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Column(
                    children: [
                      // 프로필 카드
                      Card(
                        color: Colors.black87,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            children: [
                              // 상단: 프로필 정보
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    margin: EdgeInsets.all(24.0), // 상하좌우 8픽셀의 여백 추가
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: _buildProfileImage(),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 30),
                                      Row(
                                        children: [
                                          Text(
                                            userData?["userNm"] ?? '',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 15),
                                          Text(
                                            '만 ${calculateAge(userData?["bym"] ?? "정보없음")}세',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      TextButton(
                                        onPressed: () {
                                          if (_isLogIn) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ScreenHealthInfo(
                                                  healthData: userHlthData,
                                                  healthInfoItemsFuture: healthInfoItemsFuture,
                                                  userId: userId,
                                                  initializeData: _initializeData,
                                                  msmtItemData: msmtItemData,
                                                ),
                                              ),
                                            );
                                          } else {
                                            _showLoginPrompt();
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          fixedSize: Size(176, 40),
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: Color(0xFF92D2B0),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '내 건강정보 업데이트',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF92D2B0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // 하단: 건강 정보 그리드

                              // 구분선 추가
                              Container(
                                width: 312,
                                child: Divider(
                                  color: Colors.white.withOpacity(0.15),
                                  thickness: 1,
                                  height: 10,
                                ),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(left: 40.0, top: 24.0, bottom: 24.0, right: 24.0),
                                    child: _buildHealthMetric('키', userHlthData, 'MSMT_001', 'cm'),
                                  ),
                                  Container(
                                    height: 74,
                                    child: VerticalDivider(
                                      color: Colors.white.withOpacity(0.15),
                                      thickness: 1,
                                      width: 1,
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.all(24.0),
                                    child: _buildHealthMetric('몸무게', userHlthData, 'MSMT_002', 'kg'),
                                  ),
                                  Container(
                                    height: 74,
                                    child: VerticalDivider(
                                      color: Colors.white.withOpacity(0.15),
                                      thickness: 1,
                                      width: 1,
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 24.0, right: 40.0),
                                    child: _buildHealthMetric('근육량', userHlthData, 'muscleAmt', 'kg'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 상단 제목과 나이

                  SizedBox(height: 16),
                  MuscleAgeCard(
                    muscleAge: muscleAge,
                    msmt003Grade: msmt003Grade,
                    msmt008Grade: msmt008Grade,
                    msmt011Grade: msmt011Grade,
                    msmt012Grade: msmt012Grade,
                    msmt013Grade: msmt013Grade,
                    userId: userId!,
                  ),
                  SizedBox(height: 16),

                  // 에너지 권장량
                  Container(
                    width: max(380, MediaQuery.of(context).size.width),
                    color: Colors.white, // 흰색 배경 설정
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Wrap(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${userData?["userNm"] ?? ""}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF007130), // 초록색
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' 님의',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF000000), // 검정색
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width - 40, // padding 고려
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '일일 에너지 권장량',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF000000),
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '총 ',
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${NumberFormat('#,###').format(calculateEnergy(double.tryParse(userHlthData.firstWhere(
                                                  (item) => item['MSMT_ITEM_CD'] == 'MSMT_004',
                                                  orElse: () => {'MSMT_VALUE': '0'},
                                                )['MSMT_VALUE']?.toString() ?? '0') ?? 0.0, userData?["activityLevel"] ?? "LOW").round())}',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF000000),
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' kcal',
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 30),
                              Container(
                                width: MediaQuery.of(context).size.width - 40, // 좌우 padding(20씩) 고려
                                child: Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // 칼로리 계산기 다이얼로그 코드
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          TextEditingController intakeController = TextEditingController();
                                          Map<String, dynamic> calories = {
                                            'total': 0,
                                            'carb': 0,
                                            'protein': 0,
                                          };

                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                backgroundColor: Color(0xFFFFFFFF),
                                                insetPadding: EdgeInsets.symmetric(horizontal: 24),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                                title: Container(
                                                  margin: EdgeInsets.only(top: 9, bottom: 24),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '쌀 칼로리 계산',
                                                    style: TextStyle(
                                                      color: Color(0xFF000000),
                                                      letterSpacing: -0.02,
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Container(
                                                    width: double.maxFinite,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        // 섭취량 입력 Row
                                                        Row(
                                                          children: [
                                                            // 섭취량 입력 필드 (2/3 크기)
                                                            Expanded(
                                                              flex: 2,
                                                              child: SizedBox(
                                                                height: 54,
                                                                child: TextField(
                                                                  controller: intakeController, // 컨트롤러 추가
                                                                  textAlign: TextAlign.right,
                                                                  style: const TextStyle(
                                                                    // 입력 텍스트 스타일 지정
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 24,
                                                                    height: 1.0,
                                                                  ),
                                                                  decoration: const InputDecoration(
                                                                    filled: true, // 배경색을 적용하기 위해 필요
                                                                    fillColor: Color(0xFFF5F4F9), // 배경색 설정
                                                                    enabledBorder: OutlineInputBorder(
                                                                      borderRadius: BorderRadius.all(Radius.circular(16)),
                                                                      borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
                                                                    ),
                                                                    focusedBorder: OutlineInputBorder(
                                                                      borderRadius: BorderRadius.all(Radius.circular(16)),
                                                                      borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
                                                                    ),
                                                                    prefixIcon: Padding(
                                                                      padding: EdgeInsets.only(left: 16),
                                                                      child: Center(
                                                                        widthFactor: 1.0,
                                                                        child: Text(
                                                                          '중량',
                                                                          style: TextStyle(
                                                                            color: Color(0xFF000000),
                                                                            fontSize: 18,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    suffixText: ' g ', // 우측에 단위 추가
                                                                    suffixStyle: TextStyle(
                                                                      color: Color(0xFF555555),
                                                                      fontSize: 16,
                                                                      letterSpacing: -0.04,
                                                                    ),
                                                                  ),
                                                                  keyboardType: TextInputType.number,
                                                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 8),
                                                            // 입력 버튼 (1/3 크기)
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                // SizedBox로 감싸서 높이 제어
                                                                height: 54, // TextField의 기본 높이
                                                                child: ElevatedButton(
                                                                  onPressed: () {
                                                                    double intake = double.tryParse(intakeController.text) ?? 0;
                                                                    setState(() {
                                                                      calories = calculateCalorie(intake);
                                                                    });
                                                                  },
                                                                  child: Text(
                                                                    '입력',
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.w500,
                                                                      fontSize: 18,
                                                                      color: Color(0xFF555555),
                                                                    ),
                                                                  ),
                                                                  style: ElevatedButton.styleFrom(
                                                                    padding: EdgeInsets.zero, // 패딩 제거
                                                                    backgroundColor: Colors.white,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(16),
                                                                      side: BorderSide(
                                                                        width: 1,
                                                                        color: Color(0xFF555555),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 16),
                                                        // 칼로리 정보 표시
                                                        Container(
                                                          width: double.infinity,
                                                          padding: EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            // color: Colors.white,
                                                            borderRadius: BorderRadius.circular(16),
                                                            border: Border.all(
                                                              color: Color(0xFFEDEDED),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              // Text('섭취 예정 칼로리',
                                                              //     style: TextStyle(
                                                              //       fontSize: 16,
                                                              //       fontWeight: FontWeight.bold,
                                                              //     )),
                                                              SizedBox(height: 8),
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  const Text(
                                                                    '섭취예정 총 칼로리',
                                                                    style: TextStyle(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: Color(0xFF000000),
                                                                      letterSpacing: -0.02,
                                                                    ),
                                                                  ),
                                                                  RichText(
                                                                    text: TextSpan(
                                                                      children: [
                                                                        TextSpan(
                                                                          text: '${calories['total']} ',
                                                                          style: TextStyle(
                                                                            fontSize: 24,
                                                                            fontWeight: FontWeight.w700,
                                                                            color: Color(0xFF000000),
                                                                          ),
                                                                        ),
                                                                        TextSpan(
                                                                          text: ' kcal ',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontWeight: FontWeight.w500,
                                                                            color: Color(0xFF555555),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(height: 12),
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    '탄수화물 칼로리',
                                                                    style: TextStyle(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: Color(0xFF000000),
                                                                      letterSpacing: -0.02,
                                                                    ),
                                                                  ),
                                                                  RichText(
                                                                    text: TextSpan(
                                                                      children: [
                                                                        TextSpan(
                                                                          text: '${calories['carb']} ',
                                                                          style: TextStyle(
                                                                            fontSize: 24,
                                                                            fontWeight: FontWeight.w700,
                                                                            color: Color(0xFF00914B),
                                                                          ),
                                                                        ),
                                                                        TextSpan(
                                                                          text: ' kcal ',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontWeight: FontWeight.w500,
                                                                            color: Color(0xFF555555),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(height: 12),
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    '단백질 칼로리',
                                                                    style: TextStyle(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: Color(0xFF000000),
                                                                      letterSpacing: -0.02,
                                                                    ),
                                                                  ),
                                                                  RichText(
                                                                    text: TextSpan(
                                                                      children: [
                                                                        TextSpan(
                                                                          text: '${calories['protein']} ',
                                                                          style: TextStyle(
                                                                            fontSize: 24,
                                                                            fontWeight: FontWeight.w700,
                                                                            color: Color(0xFF927E52),
                                                                          ),
                                                                        ),
                                                                        TextSpan(
                                                                          text: ' kcal ',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontWeight: FontWeight.w500,
                                                                            color: Color(0xFF555555),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                actions: [
                                                  Container(
                                                    width: double.infinity,
                                                    margin: EdgeInsets.only(top: 30),
                                                    // padding: EdgeInsets.symmetric(horizontal: 4),
                                                    child: ElevatedButton(
                                                      child: Text(
                                                        '닫기',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(0xFF007130),
                                                        padding: EdgeInsets.symmetric(vertical: 16),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFA2BC11),
                                      minimumSize: Size(262, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      '쌀 칼로리 계산기',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFFFF).withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 오늘 히츠 섹션
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
                            width: constraints.maxWidth > 300 ? (constraints.maxWidth - 16) : constraints.maxWidth,
                            height: 200,
                            child: Card(
                              color: Color(0xFF0B8043), // 초록색 배경
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 좌우 정렬
                                      children: [
                                        Expanded(
                                          // 왼쪽 텍스트 부분
                                          child: Row(
                                            children: [
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '오늘하루',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: constraints.maxWidth > 300 ? 22 : 16,
                                                        color: Color(0xFFFFFFFF),
                                                        letterSpacing: -0.02,
                                                      ),
                                                    ),
                                                    Text(
                                                      '쌀 섭취량 입력',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: constraints.maxWidth > 300 ? 22 : 16,
                                                        color: Color(0xFFFFFFFF),
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Image.asset(
                                          'images/rice_img.png', // 이미지 파일 경로
                                          width: 90,
                                          height: 74,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          child: SizedBox(
                                            width: 144,
                                            height: 42,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                // 섭취량 데이터 조회
                                                Map<String, dynamic> currentIntake = await getRiceIntake();
                                                print("currentIntake['BREAKFAST'] 확인 : ${currentIntake['BREAKFAST']}");

                                                // 팝업창 표시
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    // 텍스트 입력을 위한 컨트롤러들
                                                    TextEditingController breakfastController = TextEditingController(text: currentIntake['BREAKFAST']?.toString() ?? '');
                                                    TextEditingController lunchController = TextEditingController(text: currentIntake['LUNCH']?.toString() ?? '');
                                                    TextEditingController dinnerController = TextEditingController(text: currentIntake['DINNER']?.toString() ?? '');

                                                    return AlertDialog(
                                                      insetPadding: EdgeInsets.symmetric(horizontal: 4),
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                                      titlePadding: EdgeInsets.only(top: 30, bottom: 30, left: 24, right: 24),
                                                      title: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          RichText(
                                                            text: const TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text: '섭취한 쌀의 ',
                                                                  style: TextStyle(
                                                                    fontSize: 22,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Color(0xFF000000),
                                                                    letterSpacing: -0.04,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: '총량',
                                                                  style: TextStyle(
                                                                    fontSize: 22,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Color(0xFF00914B),
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: '을 입력해주세요',
                                                                  style: TextStyle(
                                                                    fontSize: 22,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Color(0xFF000000),
                                                                    letterSpacing: -0.04,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(height: 18), // 두 줄 사이의 간격
                                                          Row(
                                                            // mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
                                                            children: [
                                                              const Text(
                                                                '백미,현미,흑미,잡곡 등 종류 상관없음',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w400,
                                                                  color: Color(0xFF555555),
                                                                ),
                                                              ),
                                                              Spacer(), // 남은 공간을 차지하여 우측 정렬 효과를 줌
                                                              Container(
                                                                alignment: Alignment.centerRight,
                                                                child: GestureDetector(
                                                                  onTap: () {
                                                                    showDialog(
                                                                      context: context,
                                                                      builder: (BuildContext context) {
                                                                        return Dialog(
                                                                          insetPadding: EdgeInsets.symmetric(horizontal: 24),
                                                                          child: SingleChildScrollView(
                                                                            // ScrollView 추가
                                                                            child: Container(
                                                                              // Container 추가
                                                                              // constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6), // 화면 높이의 80%로 제한
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Stack(
                                                                                    alignment: Alignment.topRight,
                                                                                    children: [
                                                                                      // 이미지
                                                                                      Image.asset(
                                                                                        'images/rice_calculate_info.png',
                                                                                        fit: BoxFit.contain,
                                                                                      ),
                                                                                      // 닫기 버튼
                                                                                      Positioned(
                                                                                        top: 1,
                                                                                        right: 1,
                                                                                        child: IconButton(
                                                                                          icon: Icon(Icons.close),
                                                                                          onPressed: () {
                                                                                            Navigator.of(context).pop();
                                                                                          },
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    );
                                                                  },
                                                                  child: Image.asset(
                                                                    'images/question_mark.png',
                                                                    width: 20,
                                                                    height: 20,
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      content: Container(
                                                        width: 300,
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            // 아침
                                                            Row(
                                                              children: [
                                                                SizedBox(width: 12),
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    '아침',
                                                                    style: TextStyle(
                                                                      color: Color(0xFF000000),
                                                                      fontSize: 20,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(width: 12),
                                                                Expanded(
                                                                  flex: 4,
                                                                  child: TextField(
                                                                    controller: breakfastController,
                                                                    textAlign: TextAlign.right,
                                                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF007330)),
                                                                    decoration: const InputDecoration(
                                                                      filled: true, // 배경색을 적용하기 위해 필요
                                                                      fillColor: Color(0xFFF5F4F9), // 배경색 설정
                                                                      enabledBorder: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                                        borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
                                                                      ),
                                                                      focusedBorder: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                                        borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
                                                                      ),
                                                                      suffixIcon: Center(
                                                                        widthFactor: 1.0,
                                                                        child: Padding(
                                                                          padding: EdgeInsets.only(right: 16),
                                                                          child: Text(
                                                                            'g',
                                                                            style: TextStyle(
                                                                              color: Color(0xFF555555),
                                                                              fontSize: 14,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    keyboardType: TextInputType.number,
                                                                    inputFormatters: [
                                                                      FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 허용
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(width: 8),
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: SizedBox(
                                                                    // SizedBox로 감싸서 높이 제어
                                                                    height: 54, // TextField의 기본 높이
                                                                    child: ElevatedButton(
                                                                      onPressed: () {
                                                                        // 입력값 유효성 검사
                                                                        if (breakfastController.text.isEmpty) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('섭취량을 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        // 숫자 변환 시도
                                                                        double? amount = double.tryParse(breakfastController.text);
                                                                        if (amount == null) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('올바른 숫자를 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        // 0 이상의 값인지 확인
                                                                        if (amount < 0) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('0보다 큰 값을 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        insertRiceIntake(
                                                                          'BREAKFAST',
                                                                          double.tryParse(breakfastController.text) ?? 0,
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        '입력',
                                                                        style: TextStyle(
                                                                          fontSize: 18,
                                                                          fontWeight: FontWeight.w500,
                                                                          color: Color(0xFF555555),
                                                                        ),
                                                                      ),
                                                                      style: ElevatedButton.styleFrom(
                                                                        padding: EdgeInsets.zero, // 패딩 제거
                                                                        backgroundColor: Colors.white,
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(16),
                                                                          side: BorderSide(
                                                                            width: 1,
                                                                            color: Color(0xFF555555),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(height: 8),
                                                            // 점심
                                                            Row(
                                                              children: [
                                                                SizedBox(width: 12),
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    '점심',
                                                                    style: TextStyle(
                                                                      color: Color(0xFF000000),
                                                                      fontSize: 20,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(width: 12),
                                                                Expanded(
                                                                  flex: 4,
                                                                  child: TextField(
                                                                    textAlign: TextAlign.right,
                                                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF007330)),
                                                                    controller: lunchController,
                                                                    decoration: const InputDecoration(
                                                                      filled: true, // 배경색을 적용하기 위해 필요
                                                                      fillColor: Color(0xFFF5F4F9), // 배경색 설정
                                                                      enabledBorder: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                                        borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
                                                                      ),
                                                                      focusedBorder: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                                        borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
                                                                      ),
                                                                      suffixIcon: Center(
                                                                        widthFactor: 1.0,
                                                                        child: Padding(
                                                                          padding: EdgeInsets.only(right: 16),
                                                                          child: Text(
                                                                            'g',
                                                                            style: TextStyle(
                                                                              color: Color(0xFF555555),
                                                                              fontSize: 14,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    keyboardType: TextInputType.number,
                                                                    inputFormatters: [
                                                                      FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 허용
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(width: 8),
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: SizedBox(
                                                                    // SizedBox로 감싸서 높이 제어
                                                                    height: 54, // TextField의 기본 높이
                                                                    child: ElevatedButton(
                                                                      onPressed: () {
                                                                        // 입력값 유효성 검사
                                                                        if (lunchController.text.isEmpty) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('섭취량을 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        // 숫자 변환 시도
                                                                        double? amount = double.tryParse(lunchController.text);
                                                                        if (amount == null) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('올바른 숫자를 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        // 0 이상의 값인지 확인
                                                                        if (amount < 0) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('0보다 큰 값을 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        insertRiceIntake(
                                                                          'LUNCH',
                                                                          double.tryParse(lunchController.text) ?? 0,
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        '입력',
                                                                        style: TextStyle(
                                                                          fontSize: 18,
                                                                          fontWeight: FontWeight.w500,
                                                                          color: Color(0xFF555555),
                                                                        ),
                                                                      ),
                                                                      style: ElevatedButton.styleFrom(
                                                                        padding: EdgeInsets.zero, // 패딩 제거
                                                                        backgroundColor: Colors.white,
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(16),
                                                                          side: BorderSide(
                                                                            width: 1,
                                                                            color: Color(0xFF555555),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(height: 8),
                                                            // 저녁
                                                            Row(
                                                              children: [
                                                                SizedBox(width: 12),
                                                                Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    '저녁',
                                                                    style: TextStyle(
                                                                      color: Color(0xFF000000),
                                                                      fontSize: 20,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(width: 12),
                                                                Expanded(
                                                                  flex: 4,
                                                                  child: TextField(
                                                                    textAlign: TextAlign.right,
                                                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF007330)),
                                                                    controller: dinnerController,
                                                                    decoration: const InputDecoration(
                                                                      filled: true, // 배경색을 적용하기 위해 필요
                                                                      fillColor: Color(0xFFF5F4F9), // 배경색 설정
                                                                      enabledBorder: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                                        borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
                                                                      ),
                                                                      focusedBorder: OutlineInputBorder(
                                                                        borderRadius: BorderRadius.all(Radius.circular(16)),
                                                                        borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
                                                                      ),
                                                                      suffixIcon: Center(
                                                                        widthFactor: 1.0,
                                                                        child: Padding(
                                                                          padding: EdgeInsets.only(right: 16),
                                                                          child: Text(
                                                                            'g',
                                                                            style: TextStyle(
                                                                              color: Color(0xFF555555),
                                                                              fontSize: 14,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    keyboardType: TextInputType.number,
                                                                    inputFormatters: [
                                                                      FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 허용
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(width: 8),
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: SizedBox(
                                                                    // SizedBox로 감싸서 높이 제어
                                                                    height: 54, // TextField의 기본 높이
                                                                    child: ElevatedButton(
                                                                      onPressed: () {
                                                                        // 입력값 유효성 검사
                                                                        if (dinnerController.text.isEmpty) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('섭취량을 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        // 숫자 변환 시도
                                                                        double? amount = double.tryParse(dinnerController.text);
                                                                        if (amount == null) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('올바른 숫자를 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        // 0 이상의 값인지 확인
                                                                        if (amount < 0) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('0보다 큰 값을 입력해주세요.'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        insertRiceIntake(
                                                                          'DINNER',
                                                                          double.tryParse(dinnerController.text) ?? 0,
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        '입력',
                                                                        style: TextStyle(
                                                                          fontSize: 18,
                                                                          fontWeight: FontWeight.w500,
                                                                          color: Color(0xFF555555),
                                                                        ),
                                                                      ),
                                                                      style: ElevatedButton.styleFrom(
                                                                        padding: EdgeInsets.zero, // 패딩 제거
                                                                        backgroundColor: Colors.white,
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(16),
                                                                          side: BorderSide(
                                                                            width: 1,
                                                                            color: Color(0xFF555555),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        Container(
                                                          width: double.infinity,
                                                          margin: EdgeInsets.only(top: 30),
                                                          // padding: EdgeInsets.symmetric(horizontal: 4),
                                                          child: ElevatedButton(
                                                            child: Text(
                                                              '닫기',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Color(0xFF007130),
                                                              padding: EdgeInsets.symmetric(vertical: 16),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(16),
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                backgroundColor: Color(0xFF0B8043), // 초록색 배경
                                                // foregroundColor: Color(0xFF0B8043),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                  side: BorderSide(
                                                    color: Color(0xFFFFFFFF),
                                                    width: 2.0, // 테두리 두께
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                '입력하기',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFFFFFFF),
                                                ),
                                                softWrap: false,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 2),
                                          child: SizedBox(
                                            width: 144,
                                            height: 42,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return MetricChartDialog(
                                                      title: '쌀 섭취량(g)',
                                                      code: 'riceIntake',
                                                      userId: userId,
                                                    );
                                                  },
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                backgroundColor: Color(0xFFFFFFFF),
                                                foregroundColor: Color(0xFF0B8043),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '섭취량 추이',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF555555),
                                                    ),
                                                    softWrap: false,
                                                    overflow: TextOverflow.visible,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.bar_chart, size: 18),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 두 번째 Container
                          Container(
                            margin: const EdgeInsets.only(left: 20, right: 20),
                            width: constraints.maxWidth > 300 ? (constraints.maxWidth - 16) : constraints.maxWidth,
                            height: 300,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('images/yellow_back.png'),
                                fit: BoxFit.cover, // 이미지가 컨테이너를 꽉 채우도록 설정
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10),
                                      Text(
                                        '입력한 쌀 섭취량으로 알아보세요!',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '오늘 먹은 총 칼로리 섭취량',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF000000),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                                // 영양소 정보 rows
                                Container(
                                  width: constraints.maxWidth > 300 ? (constraints.maxWidth - 32) : constraints.maxWidth - 32,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF8E1), // 연한 노란색 배경
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 쌀 row
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 0),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 16),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF007130),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              '쌀',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Spacer(),
                                            Text(
                                              '총',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF555555),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              NumberFormat('#,###').format((totalRice * 1.46).round()),
                                              style: TextStyle(
                                                fontSize: 24,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'kcal',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF555555),
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              '(',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              NumberFormat('#,###').format((totalRice).round()),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              'g)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context).size.width * 0.8,
                                            child: CustomPaint(
                                              painter: DashedLinePainter(color: Color(0xFFFED144)),
                                              size: Size(double.infinity, 1), // 높이를 1로 설정
                                            ),
                                          ),
                                        ],
                                      ),

                                      // 탄수화물 row
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 0),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 16),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF00914B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              '탄수화물',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Spacer(),
                                            Text(
                                              '총',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF555555),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              NumberFormat('#,###').format(carbCalories.round()),
                                              style: TextStyle(
                                                fontSize: 24,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'kcal',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF555555),
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              '(',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              NumberFormat('#,###').format((carbCalories / 4).round()),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              'g)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context).size.width * 0.8,
                                            child: CustomPaint(
                                              painter: DashedLinePainter(color: Color(0xFFFED144)),
                                              size: Size(double.infinity, 1), // 높이를 1로 설정
                                            ),
                                          ),
                                        ],
                                      ),

                                      // 단백질 row
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 0),
                                        child: Row(
                                          children: [
                                            SizedBox(width: 16),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF9D895B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              '단백질',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Spacer(),
                                            Text(
                                              '총',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF555555),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              NumberFormat('#,###').format(proteinCalories.round()),
                                              style: TextStyle(
                                                fontSize: 24,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              ' kcal',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF555555),
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              '(',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              NumberFormat('#,###').format((proteinCalories / 4).round()),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              'g)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF000000),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  // 탄수화물/단백질 섭취누적량
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 탄수화물 카드
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(left: 16),
                          constraints: BoxConstraints(
                            minWidth: 175, // 최소 너비
                            maxWidth: 300, // 최대 너비 (원하는 값으로 조정 가능)
                          ),
                          height: 180, // 적절한 높이 설정
                          child: Card(
                            color: Colors.black, // 검은색 배경
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 10),
                                  Text(
                                    '탄수화물\n섭취누적량',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.02,
                                    ),
                                  ),
                                  Spacer(),
                                  Center(
                                    child: SizedBox(
                                      width: 135,
                                      height: 42,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return MetricChartDialog(title: '탄수화물 섭취량(g)', code: 'carbsIntake', userId: userId);
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '섭취량 추이',
                                              style: TextStyle(
                                                color: Color(0xFF555555),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.bar_chart, color: Colors.green),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 단백질 카드
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          constraints: BoxConstraints(
                            minWidth: 175, // 최소 너비
                            maxWidth: 300, // 최대 너비 (원하는 값으로 조정 가능)
                          ), // 적절한 너비 설정
                          height: 180, // 적절한 높이 설정
                          child: Card(
                            color: Colors.grey[700], // 회색 배경
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 10),
                                  Text(
                                    '단백질\n섭취누적량',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.02,
                                    ),
                                  ),
                                  Spacer(),
                                  Center(
                                    child: SizedBox(
                                      width: 135,
                                      height: 42,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return MetricChartDialog(title: '단백질 섭취량(g)', code: 'proteinIntake', userId: userId);
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '섭취량 추이',
                                              style: TextStyle(
                                                color: Color(0xFF555555),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.bar_chart, color: Colors.green),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 칼로리 그리드
                  // 칼로리 그리드 섹션
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, top: 48),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 섹션 제목
                        Text(
                          '${userData?["userNm"] ?? ""} 님이 오늘 하루 한 끼에',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                            letterSpacing: -0.04,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '섭취해야 할 ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF000000),
                                      letterSpacing: -0.04,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '권장 칼로리',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '는?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF000000),
                                      letterSpacing: -0.04,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFABE00),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4), // 동그라미와 텍스트 사이 간격
                                Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: Text(
                                    '섭취완료',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // 그리드 레이아웃
                        Container(
                          clipBehavior: Clip.antiAlias, // 모서리 부분 클리핑 처리
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Table(
                            border: TableBorder.all(
                              color: Colors.grey[300]!,
                              width: 1,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            // defaultVerticalAlignment: TableCellVerticalAlignment.fill,
                            children: [
                              // 헤더 행 (이제 첫 번째 열이 됨)
                              TableRow(
                                children: [
                                  // _buildTableHeader('${NumberFormat('#,###').format(recDailyEnergy)}'),
                                  _buildTableHeader('${NumberFormat('#,###').format(recDailyEnergy.round())}'),
                                  _buildTableCell('한끼  권장\n칼   로   리', isHeader: true),
                                  _buildTableCell('탄수화물\n필  요  량', isHeader: true),
                                  _buildTableCell('단  백  질\n필  요  량', isHeader: true),
                                ],
                              ),
                              // 아침 행
                              TableRow(
                                children: [
                                  _buildTableHeader('아침'),
                                  _buildTableCell('${(recBreakfastEnergy).round()}', str: 'breakfastTotalRecKcal'),
                                  _buildTableCell('${(recBreakfastCarbs).round()}', str: 'recBreakfastCarbs'),
                                  _buildTableCell('${(recBreakfastProtein).round()}', str: 'recBreakfastProtein'),
                                ],
                              ),
                              // 점심 행
                              TableRow(
                                children: [
                                  _buildTableHeader('점심'),
                                  _buildTableCell('${(recLunchEnergy).round()}', str: 'lunchTotalRecKcal'),
                                  _buildTableCell('${(recLunchCarbs).round()}', str: 'recLunchCarbs'),
                                  _buildTableCell('${(recLunchProtein).round()}', str: 'recLunchProtein'),
                                ],
                              ),
                              // 저녁 행
                              TableRow(
                                children: [
                                  _buildTableHeader('저녁'),
                                  _buildTableCell('${(recDinnerEnergy).round()}', str: 'dinnerTotalRecKcal'),
                                  _buildTableCell('${(recDinnerCarbs).round()}', str: 'recDinnerCarbs'),
                                  _buildTableCell('${(recDinnerProtein).round()}', str: 'recDinnerProtein'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        (breakfastRice != 0 && lunchRice != 0 && dinnerRice != 0) && (dailyCarbsLackCal != 0 || dailyProteinLackCal != 0)
                            ? Text(
                                '"탄수화물 ${dailyCarbsLackCal}kcal, 단백질 ${dailyProteinLackCal}kcal 부족해요. 근육과 건강을 위해 파이팅!"',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 16, right: 16, top: 36),
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${userData?["userNm"] ?? ""} 님의 권장 필요'
                              '\n에너지량에 따른 음식추천',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 첫 번째 추천 음식 섹션
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 26.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias, // 모서리 부분 잘라내기
                        child: ExpansionTile(
                          collapsedBackgroundColor: Colors.transparent, // 접혀있을 때의 배경색
                          backgroundColor: Colors.transparent, // 펼쳐졌을 때의 배경색
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black, // 기본 텍스트 색상
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '탄수화물',
                                        style: TextStyle(
                                            color: Color(0xFF00914B), // 초록색
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: '만 먼저 채우고 싶어요!',
                                        style: TextStyle(
                                            color: Color(0xFF000000), // 검정색
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(11, 0),
                                child: Container(
                                  width: 76,
                                  height: 24,
                                  padding: EdgeInsets.symmetric(horizontal: 0.6, vertical: 1.0),
                                  // margin: EdgeInsets.only(left: 24.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Color(0xFF00914B),
                                      width: 2, // 테두리 두께
                                    ),
                                  ),
                                  child: Text(
                                    '$strRec 추천음식',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00914B),
                                      fontSize: 11,
                                      letterSpacing: -0.04,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // Transform.translate(
                              //   offset: Offset(8, 0),
                              //   child: Container(
                              //     padding: EdgeInsets.zero,
                              //     child: Image.asset(
                              //       'images/arrow_down.png',
                              //       width: 24,
                              //       height: 24,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                          onExpansionChanged: (bool expanded) {
                            setState(() {
                              isExpanded1 = expanded;
                            });
                          },
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(thickness: 1.0),
                                  // 표 헤더
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '식품명',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '중량',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '탄수화물',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '단백질',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(flex: 2, child: SizedBox())
                                      // SizedBox(width: 40), // 버튼을 위한 공간
                                    ],
                                  ),
                                  Divider(thickness: 1.0),
                                  // 표 데이터 행들
                                  ...carbsFoodListData
                                      .map((food) => _buildTableRow(
                                            food['food_id'],
                                            food['food_name'],
                                            food['food_weight'],
                                            food['TOTAL_CARB_CAL'].round(),
                                            food['TOTAL_PROTEIN_CAL'].round(),
                                            // '식품명1', '500g','150kcal', '250kcal'
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 두 번째 추천 음식 섹션
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 26.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias, // 모서리 부분 잘라내기
                        child: ExpansionTile(
                          collapsedBackgroundColor: Colors.transparent, // 투명하게 설정하여 Container의 배경색이 보이도록
                          backgroundColor: Colors.transparent, // 투명하게 설정하여 Container의 배경색이 보이도록
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black, // 기본 텍스트 색상
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '단백질',
                                        style: TextStyle(color: Color(0xFF9D895B), fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: '만 먼저 채우고 싶어요!',
                                        style: TextStyle(
                                            color: Color(0xFF000000), // 검정색
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(11, 0),
                                child: Container(
                                  width: 76,
                                  height: 24,
                                  padding: EdgeInsets.symmetric(horizontal: 0.6, vertical: 1.0),
                                  // margin: EdgeInsets.only(left: 16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Color(0xFF9D895B),
                                      width: 2, // 테두리 두께
                                    ),
                                  ),
                                  child: Text(
                                    '$strRec 추천음식',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9D895B),
                                      fontSize: 11,
                                      letterSpacing: -0.04,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // Transform.translate(
                              //   offset: Offset(8, 0),
                              //   child: Container(
                              //     padding: EdgeInsets.zero,
                              //     child: Image.asset(
                              //       'images/arrow_down.png',
                              //       width: 24,
                              //       height: 24,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                          onExpansionChanged: (bool expanded) {
                            setState(() {
                              isExpanded2 = expanded;
                            });
                          },
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(thickness: 1.0),
                                  // 표 헤더
                                  Container(
                                    // decoration: BoxDecoration(
                                    //   color: Color(0xFFE8F5E9), // 연한 초록색 배경
                                    //   borderRadius: BorderRadius.circular(4), // 선택적: 모서리를 둥글게
                                    // ),
                                    padding: EdgeInsets.zero,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '식품명',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '중량',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '탄수화물',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '단백질',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(flex: 2, child: SizedBox())
                                        // SizedBox(width: 40), // 버튼을 위한 공간
                                      ],
                                    ),
                                  ),
                                  Divider(thickness: 1.0),
                                  // 표 데이터 행들
                                  ...proteinFoodListData
                                      .map((food) => _buildTableRow(
                                            food['food_id'],
                                            food['food_name'],
                                            food['food_weight'],
                                            food['TOTAL_CARB_CAL'].round(),
                                            food['TOTAL_PROTEIN_CAL'].round(),
                                            // '식품명1', '500g','150kcal', '250kcal'
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Container(
                    color: Color(0xFFf5f4f9),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: TextLarge(text: '${userData?["userNm"] ?? ""} 님의 \n운동등급에 따른 운동추천'),
                          ),
                        ),
                        Card(
                          elevation: 4,
                          margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                          color: const Color(0xFF616161),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            //width: 300,
                            //height: screenHeight / 1200 * 280,
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextLarge(text: '헬스케어 기기 연동', color: Colors.white),
                                SizedBox(height: screenHeight * 0.04),
                                RoundButton(
                                  text: '장치연결',
                                  onPressed: () async {
                                    await userModel.set_local_saved_data();
                                    userModel.set_datas(
                                      g003: msmt003Grade.toDouble(),
                                      g008: msmt008Grade.toDouble(),
                                      g011: msmt011Grade.toDouble(),
                                      g012: msmt012Grade.toDouble(),
                                      g013: msmt013Grade.toDouble(),
                                      avg: gradeAvg.toDouble(),
                                      age: muscleAge,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => PageConnectBLE()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        Card(
                          elevation: 4,
                          margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                          color: const Color(0xFF616161),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            //width: 300,
                            //height: screenHeight / 1200 * 280,
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextLarge(text: '헬스케어 기기 연동', color: Colors.white),
                                SizedBox(height: screenHeight * 0.04),
                                RoundButton(
                                  text: '통계화면',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StatisticsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80)
                ],
              ),
            )
          : _selectedIndex == 1
              // ? userInfoContainer(context, userData)
              ? MyPage(
                  userData: userData,
                  onProfileImageChange: updateProfileImage, // 콜백 함수 전달
                  onActivityLevelChange: updateActivityLevl,
                )
              : _selectedIndex == 0
                  ? Column(
                      children: [
                        Expanded(
                          child: ScreenHealthInfo(
                            healthData: userHlthData, // 기존 전달된 데이터
                            healthInfoItemsFuture: healthInfoItemsFuture, // Future 객체 전달
                            userId: userId, // 사용자 ID 전달
                            initializeData: _initializeData, // 초기화 함수 전달
                            msmtItemData: msmtItemData,
                          ),
                        ),
                        //Expanded(child: pscpInfoContainer(context, userPscpData)),
                      ],
                    )
                  : const NewsBoard(), // 건강정보&처방 탭일 때,
      bottomNavigationBar: TabBar(
        indicatorColor: Colors.transparent,
        labelColor: Colors.black,
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 2) {
              // 건강정보&처방 탭을 눌렀을 때
              setState(() {
                _selectedIndex = 0; // 홈 탭으로 상태 변경
                _tabController.animateTo(0); // 탭 컨트롤러를 홈 탭으로 이동
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewsBoard(),
                ),
              );
            }
          });
        },
        tabs: <Widget>[
          Tab(
            icon: _selectedIndex == 0 ? Image.asset('images/nav_home.png', width: 24, height: 24) : Image.asset('images/nav_home_off.png', width: 24, height: 24),
            text: "홈",
          ),
          Tab(
            icon: _selectedIndex == 1 ? Image.asset('images/nav_my.png', width: 24, height: 24) : Image.asset('images/nav_my_off.png', width: 24, height: 24),
            text: "마이페이지",
          ),
          Tab(
            icon: _selectedIndex == 2 ? Image.asset('images/nav_news.png', width: 24, height: 24) : Image.asset('images/nav_news_off.png', width: 24, height: 24),
            text: "건강뉴스",
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String code) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Row(
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.bar_chart),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return MetricChartDialog(title: title, code: code, userId: userId);
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container tabContainer(BuildContext context, Color tabColor, String tabText) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: tabColor,
      padding: const EdgeInsets.all(16.0),
      // 전체 화면에 여백 추가
      child: (tabText == "홈")
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 첫 번째 줄: "나의 건강 정보 이력" & "나의 영양 상태 평가 및 식단 추천"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isLogIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HisHealth()),
                            );
                          } else {
                            _showLoginPrompt();
                          }
                        },
                        child: const Text(
                          '나의 건강 정보 이력',
                          style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isLogIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyNutriCheck()),
                            );
                          } else {
                            _showLoginPrompt();
                          }
                        },
                        child: const Text(
                          '나의 영양 상태 평가 및 식단 추천',
                          style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 두 번째 줄: "식품별 영양 정보" & "Q&A"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FoodInfo()),
                          );
                        },
                        child: const Text(
                          '식품별 영양 정보',
                          style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isLogIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Qna()),
                            );
                          } else {
                            _showLoginPrompt();
                          }
                        },
                        child: const Text(
                          'Q&A',
                          style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 세 번째 줄: "나의 건강 정보 입력 및 자동 처방 신청"
                ElevatedButton(
                  onPressed: () {
                    if (_isLogIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InputInfoScreen(),
                        ),
                      );
                    } else {
                      _showLoginPrompt();
                    }
                  },
                  child: const Text(
                    '나의 건강 정보 입력 및 자동 처방 신청',
                    style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                  ),
                ),
              ],
            )
          : (tabText == "마이페이지")
              // ? userInfoContainer(context, userData)
              ? MyPage(
                  userData: userData,
                  onProfileImageChange: updateProfileImage, // 콜백 함수 전달
                  onActivityLevelChange: updateActivityLevl,
                )
              : (tabText == "건강정보&처방")
                  ? Column(
                      children: [
                        Expanded(
                          child: ScreenHealthInfo(
                            healthData: userHlthData, // 기존 전달된 데이터
                            healthInfoItemsFuture: healthInfoItemsFuture, // Future 객체 전달
                            userId: userId, // 사용자 ID 전달
                            initializeData: _initializeData, // 초기화 함수 전달
                            msmtItemData: msmtItemData,
                          ),
                        ),
                        Expanded(
                          child: pscpInfoContainer(context, userPscpData),
                        ),
                      ],
                    )
                  : Container(),
    );
  }

// 상태 변수 추가 (클래스의 필드로)
  String currentActivityLevel = "LOW";

  // 업로드 메서드 수정
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

// 이미지 삭제 처리
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
        });
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

// 회원 정보 컨테이너
  Container userInfoContainer(BuildContext context, Map<String, dynamic>? userData) {
    // 함수 시작시 현재 활동량 설정
    currentActivityLevel = userData?["activityLevel"] ?? "LOW";

    return Container(
      color: Colors.blueGrey,
      child: (userData == null)
          ? Center(
              child: Text(
                '회원 정보가 없습니다.',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '회원 정보',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                // 프로필 사진 섹션 추가
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // 프로필 이미지
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: _buildProfileImage(),
                          ),
                          // 편집 버튼
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        ListTile(
                                          leading: Icon(Icons.photo_library),
                                          title: Text('갤러리에서 선택'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            try {
                                              final ImagePicker picker = ImagePicker();
                                              final XFile? image = await picker.pickImage(
                                                source: ImageSource.gallery,
                                              );
                                              if (image != null) {
                                                setState(() {
                                                  _profileImage = image; // XFile 직접 저장
                                                });
                                                await _uploadImage(image);
                                              }
                                            } catch (e) {
                                              if (e is UnimplementedError) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('이 기능은 현재 플랫폼에서 지원되지 않습니다.')),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.photo_camera),
                                          title: Text('카메라로 촬영'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            try {
                                              final ImagePicker picker = ImagePicker();
                                              final XFile? image = await picker.pickImage(
                                                source: ImageSource.camera,
                                              );
                                              if (image != null) {
                                                setState(() {
                                                  _profileImage = image; // File 대신 XFile 사용
                                                });
                                                await _uploadImage(image);
                                              }
                                            } catch (e) {
                                              if (e is UnimplementedError) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('카메라 기능은 현재 플랫폼에서 지원되지 않습니다.')),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('카메라 사용 중 오류가 발생했습니다.')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        if (_profileImage != null)
                                          ListTile(
                                            leading: Icon(Icons.delete),
                                            title: Text('프로필 사진 삭제'),
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
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isLoading)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      _buildUserInfoCard(
                        title: '회원 아이디',
                        value: userData["userId"] ?? "N/A",
                      ),
                      _buildUserInfoCard(
                        title: '회원 이름',
                        value: userData["userNm"] ?? "N/A",
                      ),
                      _buildUserInfoCard(
                        title: '생년월일',
                        value: userData["bym"] ?? "N/A",
                      ),
                      _buildUserInfoCard(
                        title: '성별',
                        value: userData?["sex"] == "M" ? "남성" : "여성",
                      ),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '활동량 구분',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: DropdownButton<String>(
                                      value: currentActivityLevel,
                                      items: [
                                        DropdownMenuItem(value: 'LOW', child: Text('좌업자')),
                                        DropdownMenuItem(value: 'NORMAL', child: Text('보통활동')),
                                        DropdownMenuItem(value: 'HIGH', child: Text('육체활동')),
                                      ],
                                      onChanged: (String? value) async {
                                        if (value != null && currentActivityLevel != value) {
                                          // 확인 다이얼로그
                                          bool? confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('활동량 변경'),
                                                content: Text('활동량을 변경하시겠습니까?'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: Text('취소'),
                                                    onPressed: () => Navigator.of(context).pop(false),
                                                  ),
                                                  TextButton(
                                                    child: Text('확인'),
                                                    onPressed: () => Navigator.of(context).pop(true),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm == true) {
                                            try {
                                              ApiService apiService = ApiService();
                                              Map<String, dynamic> result = await apiService.updateUserActivityLevel(
                                                userData["userId"],
                                                value,
                                              );

                                              if (result['result'] == 1) {
                                                setState(() {
                                                  currentActivityLevel = value;
                                                  // userData도 함께 업데이트
                                                  userData?["activityLevel"] = value;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('활동량이 업데이트되었습니다.'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('활동량 업데이트에 실패했습니다.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print('Error updating activity level: $e');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      isExpanded: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

// 회원 정보 카드 빌더
  Widget _buildUserInfoCard({required String title, required String value}) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Container pscpInfoContainer(BuildContext context, List<Map<String, dynamic>> pscpData) {
    return Container(
      color: Colors.blueGrey,
      child: (pscpData.isEmpty)
          ? Center(
              child: Text(
                '처방 정보가 없습니다.',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '처방 정보',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: pscpData.map((item) {
                      return _buildInfoCard(
                        title: item['hlthFoodNm'] ?? '항목명 없음',
                        value: '${item['pscpDose']}',
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  // 공통 카드 빌더
  Widget _buildInfoCard({required String title, required String value}) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
