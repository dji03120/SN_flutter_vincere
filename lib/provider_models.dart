import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutModel extends ChangeNotifier {
  List<String> _workouts = [];
  int _currentWorkout = 0;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  List<String> get workouts => _workouts;
  int get currentWorkout => _currentWorkout;
  WebBluetoothRemoteGATTCharacteristic? get writeChar => _writeChar;
  WebBluetoothRemoteGATTCharacteristic? get notifyChar => _notifyChar;

  void set_write_char(WebBluetoothRemoteGATTCharacteristic writeChar) {
    _writeChar = writeChar;
    print(writeChar);
  }

  void set_notify_char(WebBluetoothRemoteGATTCharacteristic notifyChar) {
    _notifyChar = notifyChar;
    print(notifyChar);
  }

  void set_workouts(List<String> workouts) {
    _workouts = workouts;
    notifyListeners();
  }

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
