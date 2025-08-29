import 'package:flutter/material.dart';

class WorkoutModel extends ChangeNotifier {
  List<String> _workouts = [];
  int _currentWorkout = 0;

  List<String> get workouts => _workouts;
  int get currentWorkout => _currentWorkout;

  void set_workouts(List<String> workouts) {
    _workouts = workouts;
    notifyListeners();
  }

  void set_current_workout(int idx) {
    _currentWorkout = idx;
    notifyListeners();
  }
}
