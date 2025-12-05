import 'dart:convert';

import 'package:Vincere/http/webReqSpring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
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
class UserModel extends ChangeNotifier {
  bool _isLogin = false;
  String _password = '';
  bool get isLogin => _isLogin;
  String get password => _password;
  Future<void> set_local_saved_data() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    _password = prefs.getString('password') ?? '';
    if (_userId.isNotEmpty && _password.isNotEmpty) {
      _isLogin = true;
    }
    notifyListeners();
  }

  String _userId = '';
  String get userId => _userId;
  void set_user_id(String userId) {
    _userId = userId;
    notifyListeners();
  }

  Map<dynamic, dynamic> _userInfo = {};
  Map<dynamic, dynamic> get userInfo => _userInfo;
  void set_user_info(Map<dynamic, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  String _muscleAge = '';
  double _gradeAvg = 0.0;
  double _msmt003Grade = 0.0;
  double _msmt008Grade = 0.0;
  double _msmt011Grade = 0.0;
  double _msmt012Grade = 0.0;
  double _msmt013Grade = 0.0;
  String get muscleAge => _muscleAge;
  double get gradeAvg => _gradeAvg;
  double get msmt003Grade => _msmt003Grade;
  double get msmt008Grade => _msmt008Grade;
  double get msmt011Grade => _msmt011Grade;
  double get msmt012Grade => _msmt012Grade;
  double get msmt013Grade => _msmt013Grade;
  void set_datas({
    double? g003,
    double? g008,
    double? g011,
    double? g012,
    double? g013,
    double? avg,
    String? age,
  }) {
    if (g003 != null) _msmt003Grade = g003;
    if (g008 != null) _msmt008Grade = g008;
    if (g011 != null) _msmt011Grade = g011;
    if (g012 != null) _msmt012Grade = g012;
    if (g013 != null) _msmt013Grade = g013;
    if (avg != null) _gradeAvg = avg;
    if (age != null) _muscleAge = age;

    notifyListeners();
  }
}
