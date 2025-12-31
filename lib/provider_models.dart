import 'dart:convert';

import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:Vincere/page_home/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutModel extends ChangeNotifier {
  // intensity : 1ma -> 16ma : 0.5ma = 1level
  // ex 6 = 1ma + 6*0.5ma = 4ma
  final Map<dynamic, dynamic> _muscle_setting = {
    'scenario1': {
      1: {
        'name': '강화모드',
        '상완근': {'mode': '100hz', 'intensity': 6, 'duration': 3, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '100hz', 'intensity': 2, 'duration': 3, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '100hz', 'intensity': 8, 'duration': 3, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 2, 'duration': 3, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 8, 'duration': 3, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
      2: {
        'name': '건강모드',
        '상완근': {'mode': '100hz', 'intensity': 6, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '100hz', 'intensity': 2, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '100hz', 'intensity': 8, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 2, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 8, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
      3: {
        'name': '예방모드',
        '상완근': {'mode': '60hz', 'intensity': 5, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 2, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 7, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 2, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 7, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
      4: {
        'name': '관리모드',
        '상완근': {'mode': '60hz', 'intensity': 5, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 2, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 6, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 2, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 6, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
      5: {
        'name': '집중모드',
        '상완근': {'mode': '60hz', 'intensity': 4, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 1, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 6, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 1, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 6, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
    },
    'scenario2': {
      1: {
        'name': '강화모드',
        '상완근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '100hz', 'intensity': 13, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 13, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
      2: {
        'name': '건강모드',
        '상완근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '100hz', 'intensity': 13, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 12, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
      3: {
        'name': '예방모드',
        '상완근': {'mode': '60hz', 'intensity': 8, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 12, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 12, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
      4: {
        'name': '관리모드',
        '상완근': {'mode': '60hz', 'intensity': 7, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 8, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 11, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 8, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 11, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
      5: {
        'name': '집중모드',
        '상완근': {'mode': '60hz', 'intensity': 7, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 7, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 11, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
        '척추기립근': {'mode': '100hz', 'intensity': 7, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/척추기립근.png'},
        '대퇴이두근': {'mode': '100hz', 'intensity': 13, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴이두근.png'}
      },
    }
  };
  Map<String, dynamic> get_workout_config(String muscle_name, int grade) {
    String workout_name = _muscle_setting['scenario1'][grade]['name'];
    print(grade);
    Map<String, dynamic> workout_config1 = _muscle_setting['scenario1'][grade][muscle_name];
    Map<String, dynamic> workout_config2 = _muscle_setting['scenario2'][grade][muscle_name];
    return {
      'name': workout_name,
      'scenario1': workout_config1,
      'scenario2': workout_config2,
    };
  }

  //
  //
  //
  Map<dynamic, dynamic> workoutInfoTemplate = {
    '60hz': {
      '상완근': {'intensitySum': 0, 'duration': 0, 'type': 'free'},
      '삼각근': {'intensitySum': 0, 'duration': 0, 'type': 'free'},
      '대퇴근': {'intensitySum': 0, 'duration': 0, 'type': 'free'},
      '척추기립근': {'intensitySum': 0, 'duration': 0, 'type': 'paid'},
      '대퇴이두근': {'intensitySum': 0, 'duration': 0, 'type': 'paid'},
    },
    '100hz': {
      '상완근': {'intensitySum': 0, 'duration': 0, 'type': 'free'},
      '삼각근': {'intensitySum': 0, 'duration': 0, 'type': 'free'},
      '대퇴근': {'intensitySum': 0, 'duration': 0, 'type': 'free'},
      '척추기립근': {'intensitySum': 0, 'duration': 0, 'type': 'paid'},
      '대퇴이두근': {'intensitySum': 0, 'duration': 0, 'type': 'paid'},
    },
  };
  Map<dynamic, dynamic> _workoutInfo = {};
  Future<Map> get_workout_info(String userId) async {
    // 오늘 데이터가 조회된다면 조회
    // 오늘 데이터가 없다면 insert -> 조회
    ApiService apiService = ApiService();
    List<dynamic> response = (await apiService.selectWorkoutRecent(userId))['result'];

    if (response.length == 0) {
      print('new user insert.. today workout info');
      _workoutInfo = workoutInfoTemplate;
      await apiService.insertWorkout(userId, _workoutInfo);
      return _workoutInfo;
    }

    //
    Map<dynamic, dynamic> result = response[0];
    DateTime st = DateTime.fromMillisecondsSinceEpoch(result['START_TIME']); //.toUtc();
    DateTime now = DateTime.now();
    print("$st, $now");
    if ((st.year == now.year) && (st.month == now.month) && (st.day == now.day)) {
      print('load.. today workout info');
      final metaRaw = result['META_INFO'];
      if (metaRaw != null && metaRaw.toString().isNotEmpty) {
        Map<dynamic, dynamic> temp = jsonDecode(metaRaw);
        _workoutInfo = temp;
      }
    } else {
      print('insert.. today workout info');
      _workoutInfo = workoutInfoTemplate;
      await apiService.insertWorkout(userId, _workoutInfo);
    }
    print(_workoutInfo);
    return _workoutInfo;
  }

  //
  //
  //
  Future<void> update_workout_info(String userId, String muscleName, int intensity) async {
    String workoutHz = _workoutLevel == 'mode1' ? '100hz' : '60hz';
    _workoutInfo[workoutHz][muscleName]['intensitySum'] += intensity;
    _workoutInfo[workoutHz][muscleName]['duration'] += 1;
    ApiService apiService = ApiService();
    print(_workoutInfo);
    await apiService.updateWorkout(userId, _workoutInfo);
  }

  //
  //
  //
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? get writeChar => _writeChar;
  void set_write_char(WebBluetoothRemoteGATTCharacteristic writeChar) {
    _writeChar = writeChar;
  }

  //
  //
  //
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;
  WebBluetoothRemoteGATTCharacteristic? get notifyChar => _notifyChar;
  void set_notify_char(WebBluetoothRemoteGATTCharacteristic notifyChar) {
    _notifyChar = notifyChar;
  }

  //
  //
  //
  String _workoutMode = "passive";
  String get workoutMode => _workoutMode;
  void set_workout_mode(String workoutMode) {
    _workoutMode = workoutMode;
  }

  //
  //
  //
  String _workoutLevel = "mode2";
  String get workoutLevel => _workoutLevel;
  void set_workout_level(double userGrade) {
    int grade = userGrade.toInt();
    if (grade <= 2) {
      _workoutLevel = "mode1"; // 100hz
    } else {
      _workoutLevel = "mode2"; // 60hz
    }

    print(_workoutLevel);
  }

  //
  //
  //
  List<String> _workoutPlan = [];
  List<String> get workoutPlan => _workoutPlan;
  void set_workout_plan(List<String> workoutPlan) {
    _workoutPlan = workoutPlan;
    _currentWorkout = 0;
    notifyListeners();
  }

  //
  //
  //
  int _currentWorkout = 0;
  int get currentWorkout => _currentWorkout;
  void set_current_workout(int idx) {
    _currentWorkout = idx;
    notifyListeners();
  }
}

//
//
//
//
//
//
//
//
//
//
class UserModel extends ChangeNotifier {
  bool _isLogin = false;
  String _userId = '';
  String _password = '';
  bool get isLogin => _isLogin;
  void set_user_id(String user_id) {
    _userId = user_id;
  }

  void set_password(String password) {
    _password = password;
  }

  void set_islogin(bool isLogin) {
    _isLogin = isLogin;
  }

  String get password => _password;
  String get userId => _userId;
  Future<void> set_login_data() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    _password = prefs.getString('password') ?? '';
    if (_userId != "" && _password != "") {
      _isLogin = true;
      print("login process done...");
    } else {
      _isLogin = false;
      print("login process fail...");
    }
  }

//
//
//
//
//
//
//
//
//
  double _gradeAvg = 0.0;
  String _profileImageUrl = '';
  Map<String, dynamic>? _userInfo = {};
  Map<String, dynamic>? _userHealthData = {};
  List<Map<String, dynamic>> _muscleAgeData = [];

  double get gradeAvg => _gradeAvg;
  String? get profileImageUrl => _profileImageUrl;
  Map<String, dynamic>? get userInfo => _userInfo;
  Map<String, dynamic>? get userHealthData => _userHealthData;
  List<Map<String, dynamic>> get muscleAgeData => _muscleAgeData;
  Future<void> set_user_info() async {
    try {
      //
      // get user info
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetUserInfo(_userId.toString());
      _userInfo = result["userOne"];
      _userInfo?['age'] = get_birth_to_age(_userInfo?['bym']);
      print(_userInfo);

      //
      // get profile image
      Map<String, dynamic> profileRes = await apiService.fetchProfileImage(_userId.toString());
      if (profileRes['success'] == true && profileRes['imageUrl'] != null) {
        _profileImageUrl = profileRes['imageUrl'];
      } else {
        print('Failed to get profile image: ${profileRes['message']}');
      }

      //
      // get user health
      ApiServiceFast apiServicFast = ApiServiceFast();
      _userHealthData = (await apiServicFast.selectUserHealth(_userId.toString()))['result'];
      _gradeAvg = _userHealthData?['grade_average'] ?? 3;

      //
      // get daliy workout
      String planName = _userHealthData?['workout_plan'] ?? "sample_plan";
      int planIdx = _userHealthData?['workout_plan_idx'] ?? 0;
      dynamic planData = (await apiServicFast.select_workout_plan(planName))['result'];
      Map dailyWorkout = planData['items'][planIdx];
      _userHealthData?['daliyWorkoutPlan'] = dailyWorkout;
      print(dailyWorkout);

      //
      // get daliy plate
      planName = _userHealthData?['plate_plan'] ?? "sample_plan";
      planIdx = _userHealthData?['plate_plan_idx'] ?? 0;
      planData = (await apiServicFast.select_plate_plan(planName))['result'];
      Map dailyPlate = planData['items'][planIdx];
      _userHealthData?['daliyPlatePlan'] = dailyPlate;
      print(dailyPlate);

      //
    } catch (e) {
      print('Error: $e');
    }
    print("userdata : ${_userInfo}");
    print("userHealthData : ${_userHealthData}");
  }

  //
  //
  //
  //
  Map<String, dynamic> _surveyAnswers = {};
  List<Map<String, dynamic>> _surveyQuestions = [];
  Map<String, dynamic> get surveyAnswers => _surveyAnswers;
  List<Map<String, dynamic>> get surveyQuestions => _surveyQuestions;
  Future<void> set_survey_info(int surveyId) async {
    try {
      ApiServiceFast apiService = ApiServiceFast();
      _surveyQuestions = (await apiService.select_survey_questions(surveyId));
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }

  void save_answer(String answer_key, dynamic answer_value) {
    try {
      _surveyAnswers[answer_key] = answer_value;
      print(_surveyAnswers);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }

  dynamic get_answer(String answer_key) {
    try {
      print(_surveyAnswers[answer_key]);
      return _surveyAnswers[answer_key];
    } catch (e) {
      print('Error: $e');
    }
  }

//
//
//
//
  Map<String, dynamic> _plateData = {};
  Map<String, dynamic> get plateData => _plateData;

  Future<void> set_food_plate_data() async {
    try {
      double weight = _userHealthData?['표준체중'][0] ?? 0.0;
      String activityLevel = _userInfo?['activityLevel'] ?? 'LOW';
      Map activityFactor = {'a': 0, 'b': 0};
      if (weight <= 0) {
        print('Invalid standard weight');
        return;
      }
      if (activityLevel == 'LOW') activityFactor = {'a': 25, 'b': 30};
      if (activityLevel == 'NORMAL') activityFactor = {'a': 30, 'b': 35};
      if (activityLevel == 'HIGH') activityFactor = {'a': 35, 'b': 40};
      _plateData['recDailyEnergy'] = ((weight * activityFactor['a']) - activityFactor['b']);

      if (_userHealthData?['기초대사량'][0] != null) {
        if (_userHealthData?['기초대사량'][0] != 0) {
          _plateData['recDailyEnergy'] = _userHealthData?['기초대사량'][0];
        }
      }

      //
      //
      //
      // 쌀 섭취량 데이터 가져오기
      Map<String, dynamic> riceIntake = await getRiceIntake(_userId);

      // 아침/점심/저녁 섭취량을 double로 변환 (null이면 0으로 처리)
      _plateData['breakfastRice'] = double.tryParse(riceIntake['BREAKFAST']?.toString() ?? '0') ?? 0;
      _plateData['lunchRice'] = double.tryParse(riceIntake['LUNCH']?.toString() ?? '0') ?? 0;
      _plateData['dinnerRice'] = double.tryParse(riceIntake['DINNER']?.toString() ?? '0') ?? 0;
      _plateData['totalRice'] = _plateData['breakfastRice'] + _plateData['lunchRice'] + _plateData['dinnerRice']; // 총 쌀 섭취량 계산

      // 탄수화물과 단백질 칼로리 계산
      // 쌀의 탄수화물 비율 37%, 탄수화물 1g당 4kcal // 단백질 1g당 4kcal 쌀의 단백질 비율 2.5%,
      _plateData['carbCalories'] = _plateData['totalRice'] * 1.32;
      _plateData['proteinCalories'] = _plateData['totalRice'] * 0.092;
      _plateData['totalCalories'] = _plateData['carbCalories'] + _plateData['proteinCalories'];

      _plateData['recBreakfastCal'] = _plateData['recDailyEnergy'] / 3;
      _plateData['recLunchCal'] = _plateData['recDailyEnergy'] / 3;
      _plateData['recDinnerCal'] = _plateData['recDailyEnergy'] / 3;

      //
      //
      //
      // 추천 칼로리 계산
      _plateData['recEnergy'] = _plateData['recDailyEnergy'] / 3; // 한끼 권장 칼로리
      _plateData['recCarbs'] = _plateData['recDailyEnergy'] / 3 * 0.55; // 탄수화물 일일권장량
      _plateData['recProtein'] = _plateData['recDailyEnergy'] / 3 * 0.3; // 단백질 일일권장량

      // 아침 권장량
      _plateData['recBreakfastEnergy'] = _plateData['recEnergy'] - _plateData['breakfastRice'] * 1.46;
      _plateData['recBreakfastCarbs'] = _plateData['recCarbs'] - _plateData['breakfastRice'] * 1.32;
      _plateData['recBreakfastProtein'] = _plateData['recProtein'] - _plateData['breakfastRice'] * 0.092;

      // 점심 권장량
      _plateData['recLunchEnergy'] = _plateData['recEnergy'] - (_plateData['lunchRice'] * 1.46);
      _plateData['recLunchCarbs'] = _plateData['recCarbs'] - (_plateData['lunchRice'] * 1.32);
      _plateData['recLunchProtein'] = _plateData['recProtein'] - (_plateData['lunchRice'] * 0.092);

      // 저녁 권장량
      _plateData['recDinnerEnergy'] = _plateData['recEnergy'] - (_plateData['dinnerRice'] * 1.46);
      _plateData['recDinnerCarbs'] = _plateData['recCarbs'] - (_plateData['dinnerRice'] * 1.32);
      _plateData['recDinnerProtein'] = _plateData['recProtein'] - (_plateData['dinnerRice'] * 0.092);

      if (_plateData['breakfastRice'] != 0) {
        // 아침 섭취량이 입력된 경우 - 점심, 저녁에 각각 아침의 부족 초과분/2 추가
        _plateData['recLunchEnergy'] = _plateData['recLunchEnergy'] + _plateData['recBreakfastEnergy'] / 2;
        _plateData['recLunchCarbs'] = _plateData['recLunchCarbs'] + _plateData['recBreakfastCarbs'] / 2;
        _plateData['recLunchProtein'] = _plateData['recLunchProtein'] + _plateData['recBreakfastProtein'] / 2;

        _plateData['recDinnerEnergy'] = _plateData['recDinnerEnergy'] + _plateData['recBreakfastEnergy'] / 2;
        _plateData['recDinnerCarbs'] = _plateData['recDinnerCarbs'] + _plateData['recBreakfastCarbs'] / 2;
        _plateData['recDinnerProtein'] = _plateData['recDinnerProtein'] + _plateData['recBreakfastProtein'] / 2;
      }

      if (_plateData['lunchRice'] != 0) {
        // 점심 섭취량이 입력된 경우 - 저녁에 각각 점심 부족 초과분 추가
        _plateData['recDinnerEnergy'] = _plateData['recDinnerEnergy'] + _plateData['recLunchEnergy'];
        _plateData['recDinnerCarbs'] = _plateData['recDinnerCarbs'] + _plateData['recLunchCarbs'];
        _plateData['recDinnerProtein'] = _plateData['recDinnerProtein'] + _plateData['recLunchProtein'];
      }

      if (_plateData['dinnerRice'] != 0) {
        // 저녁 섭취량이 입력된 경우, 부족 칼로리 계산 진행
        // 일일 에너지 권장량 - 아침/점심/저녁 섭취 칼로리
        _plateData['dailyCarbsLackCal'] = _plateData['recDailyEnergy'] * 0.55 - _plateData['totalRice'] * 1.32;
        _plateData['dailyCarbsLackCal'] = _plateData['dailyCarbsLackCal'] > 0 ? _plateData['dailyCarbsLackCal'].round() as double : 0;

        _plateData['dailyProteinLackCal'] = _plateData['recDailyEnergy'] * 0.3 - _plateData['totalRice'] * 0.092;
        _plateData['dailyProteinLackCal'] = _plateData['dailyProteinLackCal'] > 0 ? _plateData['dailyProteinLackCal'].round() as double : 0;
      }

      //
      //
      //
      // 끼니별 쌀 섭취량이 0이 아닐 경우에는 권장량 대신 섭취량 출력
      _plateData['recBreakfastEnergy'] = _plateData['breakfastRice'] != 0 ? _plateData['breakfastRice'] * 1.46 : _plateData['recBreakfastEnergy'];
      _plateData['recBreakfastCarbs'] = _plateData['breakfastRice'] != 0 ? _plateData['breakfastRice'] * 1.32 : _plateData['recBreakfastCarbs'];
      _plateData['recBreakfastProtein'] = _plateData['breakfastRice'] != 0 ? _plateData['breakfastRice'] * 0.092 : _plateData['recBreakfastProtein'];

      _plateData['recLunchEnergy'] = _plateData['lunchRice'] != 0 ? _plateData['lunchRice'] * 1.46 : _plateData['recLunchEnergy'];
      _plateData['recLunchCarbs'] = _plateData['lunchRice'] != 0 ? _plateData['lunchRice'] * 1.32 : _plateData['recLunchCarbs'];
      _plateData['recLunchProtein'] = _plateData['lunchRice'] != 0 ? _plateData['lunchRice'] * 0.092 : _plateData['recLunchProtein'];

      _plateData['recDinnerEnergy'] = _plateData['dinnerRice'] != 0 ? _plateData['dinnerRice'] * 1.46 : _plateData['recDinnerEnergy'];
      _plateData['recDinnerCarbs'] = _plateData['dinnerRice'] != 0 ? _plateData['dinnerRice'] * 1.32 : _plateData['recDinnerCarbs'];
      _plateData['recDinnerProtein'] = _plateData['dinnerRice'] != 0 ? _plateData['dinnerRice'] * 0.092 : _plateData['recDinnerProtein'];

      //
      //
      //
      // 추천식품을 위한 탄수화물, 단백질 필요 칼로리

      if (_plateData['breakfastRice'] == 0) {
        // 아침 섭취량이 입력 X
        _plateData['foodRecCarbsCal'] = _plateData['recBreakfastCarbs'];
        _plateData['foodRecProteinCal'] = _plateData['recBreakfastProtein'];
        _plateData['strRec'] = "아침";
      }
      if (_plateData['breakfastRice'] != 0) {
        // 아침 섭취량이 입력된 경우 // 점심 권장 영양을 기준으로 함
        _plateData['foodRecCarbsCal'] = _plateData['recLunchCarbs'];
        _plateData['foodRecProteinCal'] = _plateData['recLunchProtein'];
        _plateData['strRec'] = "점심";
      }

      if (_plateData['lunchRice'] != 0) {
        // 점심 섭취량이 입력된 경우 녁 권장 탄수화물 칼로리를 기준으로 함
        _plateData['foodRecCarbsCal'] = _plateData['recDinnerCarbs'];
        _plateData['foodRecProteinCal'] = _plateData['recDinnerProtein'];
        _plateData['strRec'] = "저녁";
      }
      if (_plateData['dinnerRice'] != 0) {
        // 저녁 섭취량이 입력된 경우
        _plateData['foodRecCarbsCal'] = 0;
        _plateData['foodRecProteinCal'] = 0;
        _plateData['strRec'] = "";
      }

      //
      //
      //
      // 추천식품 API
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetRcmdFoodList(
        _plateData['foodRecCarbsCal'],
        _plateData['foodRecProteinCal'],
      );
      print("_getRcmdFoodList result : $result");
      if (result.containsKey('carbsFoodMap')) {
        _plateData['carbsFoodListData'] = List<Map<String, dynamic>>.from(result["carbsFoodMap"]);
      }
      if (result.containsKey('proteinFoodMap')) {
        _plateData['proteinFoodListData'] = List<Map<String, dynamic>>.from(result["proteinFoodMap"]);
      }

      print("_plateData : ${_plateData}");
    } catch (e) {
      print('Error calculating energy: $e');
    }
    notifyListeners();
  }

  notifyListeners();
}

//
//
//
//
//
//
//
//
//
Future<Map<String, dynamic>> getRiceIntake(String userId) async {
  try {
    ApiService apiService = ApiService();
    Map<String, dynamic> result = await apiService.fetchRiceIntake(userId.toString());
    print("getRiceIntake : $result");
    if (result != null) {
      return result;
    }
    return {};
  } catch (e) {
    print('Error getting rice intake: $e');
    return {};
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

// 쌀 섭취량 입력
Future<void> insertRiceIntake(UserModel userModel, String mealType, double amount) async {
  try {
    ApiService apiService = ApiService();
    Map<String, dynamic> result = await apiService.insertRiceIntake(
      userModel.userId.toString(),
      mealType,
      amount,
    );
  } catch (e) {
    print('Error inserting rice intake: $e');
  }
}
