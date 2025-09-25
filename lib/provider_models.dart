import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutModel extends ChangeNotifier {
  // intensity : 1ma -> 16ma : 0.5ma = 1level
  // ex 6 = 1ma + 6*0.5ma = 4ma
  final Map<dynamic, dynamic> _muscle_setting_passive = {
    'scenario1': {
      1: {
        'name': '강화모드',
        '상완근': {'mode': '100hz', 'intensity': 6, 'duration': 3, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '100hz', 'intensity': 2, 'duration': 3, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '100hz', 'intensity': 8, 'duration': 3, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
      2: {
        'name': '건강모드',
        '상완근': {'mode': '100hz', 'intensity': 6, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '100hz', 'intensity': 2, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '100hz', 'intensity': 8, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
      3: {
        'name': '예방모드',
        '상완근': {'mode': '60hz', 'intensity': 5, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 2, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 7, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
      4: {
        'name': '관리모드',
        '상완근': {'mode': '60hz', 'intensity': 5, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 2, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 6, 'duration': 5, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
      5: {
        'name': '집중모드',
        '상완근': {'mode': '60hz', 'intensity': 4, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 1, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 6, 'duration': 6, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
    },
    'scenario2': {
      1: {
        'name': '강화모드',
        '상완근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '100hz', 'intensity': 13, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
      2: {
        'name': '건강모드',
        '상완근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '100hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '100hz', 'intensity': 13, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
      3: {
        'name': '예방모드',
        '상완근': {'mode': '60hz', 'intensity': 8, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 9, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 12, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
      4: {
        'name': '관리모드',
        '상완근': {'mode': '60hz', 'intensity': 7, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 8, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 11, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'}
      },
      5: {
        'name': '집중모드',
        '상완근': {'mode': '60hz', 'intensity': 7, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/상완근.png'},
        '삼각근': {'mode': '60hz', 'intensity': 7, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/삼각근.png'},
        '대퇴근': {'mode': '60hz', 'intensity': 11, 'duration': 10, 'asset_url': 'assets/images/workout_elexir/대퇴근.png'},
      },
    }
  };
  Map<String, dynamic> get_workout_config(String muscle_name, int grade) {
    String workout_name = _muscle_setting_passive['scenario1'][grade]['name'];
    print(grade);
    Map<String, dynamic> workout_config1 = _muscle_setting_passive['scenario1'][grade][muscle_name];
    Map<String, dynamic> workout_config2 = _muscle_setting_passive['scenario2'][grade][muscle_name];
    return {
      'name': workout_name,
      'scenario1': workout_config1,
      'scenario2': workout_config2,
    };
  }

  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? get writeChar => _writeChar;
  void set_write_char(WebBluetoothRemoteGATTCharacteristic writeChar) {
    _writeChar = writeChar;
  }

  WebBluetoothRemoteGATTCharacteristic? _notifyChar;
  WebBluetoothRemoteGATTCharacteristic? get notifyChar => _notifyChar;
  void set_notify_char(WebBluetoothRemoteGATTCharacteristic notifyChar) {
    _notifyChar = notifyChar;
  }

  String _workoutMode = "passive";
  String get workoutMode => _workoutMode;
  void set_workout_mode(String workoutMode) {
    _workoutMode = workoutMode;
  }

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

  List<String> _workouts = [];
  List<String> get workouts => _workouts;
  void set_workouts(List<String> workouts) {
    _workouts = workouts;
    _currentWorkout = 0;
    notifyListeners();
  }

  int _currentWorkout = 0;
  int get currentWorkout => _currentWorkout;
  void set_current_workout(int idx) {
    _currentWorkout = idx;
    notifyListeners();
  }
}

class UserModel extends ChangeNotifier {
  bool _isLogin = false;
  String _userId = '';
  String _password = '';
  bool get isLogin => _isLogin;
  String get userId => _userId;
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

  void set_user_id(String userId) {
    _userId = userId;
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

  // 여러 값 한 번에 세팅하는 메소드도 가능
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
