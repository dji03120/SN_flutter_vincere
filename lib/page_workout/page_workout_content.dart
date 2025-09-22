import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/component/custom_drawer.dart';
import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:Vincere/page_workout/page_statistics.dart';
import 'package:Vincere/page_workout/page_workout_plan.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/component/progress_donut.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:Vincere/component/custom_text.dart'; // 추가

class WorkoutContent extends StatefulWidget {
  const WorkoutContent({super.key});

  @override
  State<WorkoutContent> createState() => Component3State();
}

class Component3State extends State<WorkoutContent> {
  double _progress = 1;
  Timer? _timer;
  late VideoPlayerController _videoController; // 동영상 컨트롤러
  late Future<void> _initializeVideoPlayerFuture;
  bool isWorkoutDone = false;
  int intense_value = 0;
  int workout_min = 10;
  int workout_sec = 0;
  int step_count = 0;
  int mlt = 100;

  Map<String, dynamic> workoutSetting = {};
  int scenario_idx = 1;

  @override
  void initState() {
    super.initState();
    workout_sec = workout_min * 60;

    // VideoController 초기화
    _videoController = VideoPlayerController.asset('assets/videos/sample.mp4');
    _initializeVideoPlayerFuture = _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.play();
    _startProgress();
  }

  void _startProgress() async {
    double step = 1 * mlt / workout_sec; // 1%씩 증가
    Duration interval = const Duration(milliseconds: 1000); // 0.1초 간격
    ApiService apiService = ApiService();
    final userModel = Provider.of<UserModel>(context, listen: false);
    final workoutModel = Provider.of<WorkoutModel>(context, listen: false);

    String currentWorkout = workoutModel.workouts[workoutModel.currentWorkout];
    workoutSetting = workoutModel.get_workout_config(currentWorkout, userModel.gradeAvg.toInt());
    print(workoutSetting);

    for (int i = 0; i < workoutSetting['scenario1']['intensity']; i++) {
      intense_value += 1;
      await sendCommand(workoutModel.writeChar, ble_commands["intense_up"]!); // 다시시작
    }

    _timer = Timer.periodic(interval, (timer) async {
      if (_progress != 0) {
        _progress -= step;
        step_count += mlt;
        print(step_count);
        if (step_count > workoutSetting['scenario${scenario_idx}']['duration'] * 60) {
          print(workoutSetting);
          scenario_idx += 1;
          try {
            int intensity_prev = workoutSetting['scenario${scenario_idx - 1}']['intensity'];
            int intensity_curr = workoutSetting['scenario${scenario_idx}']['intensity'];
            if (intensity_curr > intensity_prev) {
              for (int i = 0; i < intensity_curr - intensity_prev; i++) {
                intense_value += 1;
                await sendCommand(workoutModel.writeChar, ble_commands["intense_up"]!);
              }
            } else {
              for (int i = 0; i < intensity_curr - intensity_prev; i++) {
                intense_value -= 1;
                await sendCommand(workoutModel.writeChar, ble_commands["intense_dw"]!);
              }
            }
          } catch (e) {
            _progress = 0;
            isWorkoutDone = true;
          }
        }
        if (_progress <= 0) {
          _progress = 0;
          isWorkoutDone = true;
        }
        // DB update는 await 없이 Future 처리 - 1분마다 갱신
        if (step_count % 600 == 599) {
          apiService.updateWorkoutEnd(userModel.userId).then((_) {
            print('DB update 완료');
          }).catchError((e) {
            print('DB update 실패: $e');
          });
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Widget controlButton(IconData iconData, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(iconData, color: Colors.black, size: 30),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ApiService apiService = ApiService();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final workoutModel = Provider.of<WorkoutModel>(context);
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: true),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        child: Container(
          color: Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),
              TextCustom(text: '동작 A : example'),
              SizedBox(height: screenHeight * 0.06),
              Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: DonutProgress(
                    progress: _progress,
                    strokeWidth: 12,
                    size: Size(screenWidth * 0.3, screenWidth * 0.3),
                    centerText: "${(workout_min * _progress).toInt()}min",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        width: screenWidth,
        height: screenHeight * 0.25,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 111, 163, 27),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(30),
        child: isWorkoutDone == false
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TextCustom(
                        text: '세기',
                        color: Colors.white,
                        fontSize: 24,
                      ),
                      const SizedBox(width: 30), // 간격
                      controlButton(Icons.remove, () async {
                        await sendCommand(workoutModel.writeChar, ble_commands["intense_dw"]!);
                        intense_value -= 1;
                        if (intense_value <= 0) intense_value = 0;
                        setState(() {});
                      }),
                      const SizedBox(width: 12), // 간격
                      TextCustom(text: '$intense_value/30', color: Colors.white),
                      const SizedBox(width: 12), // 간격
                      controlButton(Icons.add, () async {
                        await sendCommand(workoutModel.writeChar, ble_commands["intense_up"]!);
                        intense_value += 1;
                        if (intense_value >= 30) intense_value = 30;
                        setState(() {});
                      }),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextCustom(
                    text: '운동이 종료되었습니다',
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  RoundButton(
                    text: '다음운동',
                    onPressed: () async {
                      if (workoutModel.writeChar != null) {
                      } else {
                        print("writeChar is null, BLE not connected");
                      }
                      int nextWorkoutIdx = workoutModel.currentWorkout + 1;
                      if (nextWorkoutIdx >= workoutModel.workouts.length) {
                        await sendCommand(workoutModel.writeChar, ble_commands["stop"]!);
                        await apiService.updateWorkoutEnd(userModel.userId);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsPage(),
                          ),
                        );
                      } else {
                        // reset ble value
                        int intense_value_copy = intense_value;
                        for (int i = 0; i < intense_value; i++) {
                          await sendCommand(workoutModel.writeChar, ble_commands["intense_dw"]!);
                          intense_value_copy -= 1;
                          print('intense ${intense_value_copy}');
                          setState(() {});
                        }
                        await sendCommand(workoutModel.writeChar, ble_commands["pause"]!);
                        workoutModel.set_current_workout(nextWorkoutIdx);
                        await apiService.updateWorkoutEnd(userModel.userId);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkoutPlan(
                              explainText: '다음 운동을 진행하시려면\n 시작버튼을 눌러주세요',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
