import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/component/custom_drawer.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/services/page_workout/page_statistics.dart';
import 'package:Vincere/services/page_workout/page_workout_plan.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/utils/component/progress_donut.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class WorkoutContentPassive extends StatefulWidget {
  const WorkoutContentPassive({super.key});

  @override
  State<WorkoutContentPassive> createState() => Component3State();
}

//
//
//
class Component3State extends State<WorkoutContentPassive> {
  double _progress = 1;
  Timer? _timer;
  bool isWorkoutDone = false;
  int intenseValue = 0;
  int workout_min = 10;
  int workout_sec = 0;
  int step_count = 0;
  int mlt = 1;
  String image_url = '';
  Map<String, dynamic> workoutSetting = {};
  int scenario_idx = 1;

  @override
  void initState() {
    super.initState();
    workout_sec = workout_min * 60;
    _startProgress();
  }

  //
  //
  // providar, restful api, blutooth가 결합되어 번거로움
  void _startProgress() async {
    Duration interval = const Duration(milliseconds: 1000);
    ApiService apiService = ApiService();
    final userModel = Provider.of<UserModel>(context, listen: false);
    final workoutModel = Provider.of<WorkoutModel>(context, listen: false);

    //
    //setting workout
    String userId = userModel.userId;
    String muscleName = workoutModel.workoutPlan[workoutModel.currentWorkout];
    workoutSetting = workoutModel.get_workout_config(muscleName, userModel.gradeAvg.toInt());
    image_url = workoutSetting['scenario1']['asset_url'];
    print('$workoutSetting, $image_url');

    //
    // 운동 강도 초기 세팅
    for (int i = 0; i < workoutSetting['scenario1']['intensity']; i++) {
      intenseValue += 1;
      await sendCommandElexir(workoutModel.writeChar, elexir_commands["intense_up"]!); // 다시시작
    }

    //
    // start workout timer
    _timer = Timer.periodic(interval, (timer) async {
      if (step_count % 60 == 0) {
        print("update db"); // DB update는 await 없이 Future 처리 - 1분마다 갱신
        await workoutModel.update_workout_info(userId, muscleName, intenseValue);
        await apiService.updateWorkoutEnd(userId).then((_) {
          print('DB update 완료');
        }).catchError((e) {
          print('DB update 실패: $e');
        });
      }

      //
      // check next workout time
      if (step_count > workoutSetting['scenario${scenario_idx}']['duration'] * 60) {
        print(workoutSetting);
        scenario_idx += 1;
        if (!workoutSetting.containsKey('scenario$scenario_idx')) {
          // workoutSetting에 다음 시나리오가 없을 경우 운동 완료로 취급
          _progress = 0; // end of workout
          isWorkoutDone = true;
        }
        // 운동강도 갱신
        try {
          int intensity_prev = workoutSetting['scenario${scenario_idx - 1}']['intensity'];
          int intensity_curr = workoutSetting['scenario${scenario_idx}']['intensity'];
          if (intensity_curr > intensity_prev) {
            for (int i = 0; i < intensity_curr - intensity_prev; i++) {
              await sendCommandElexir(workoutModel.writeChar, elexir_commands["intense_up"]!);
              intenseValue += 1;
            }
          } else {
            for (int i = 0; i < intensity_curr - intensity_prev; i++) {
              await sendCommandElexir(workoutModel.writeChar, elexir_commands["intense_dw"]!);
              intenseValue -= 1;
            }
          }
        } catch (e) {
          _progress = 0;
          isWorkoutDone = true;
        }
      }

      // update progress
      if (_progress <= 0) {
        _progress = 0; // end of workout
        isWorkoutDone = true;
      }
      _progress = 1 - step_count / workout_sec;
      step_count += mlt;
      setState(() {});
    });
  }

  //
  //
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  //
  //
  @override
  Widget build(BuildContext context) {
    ApiService apiService = ApiService();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final workoutModel = Provider.of<WorkoutModel>(context);
    final userModel = Provider.of<UserModel>(context);
    String currentWorkout = workoutModel.workoutPlan[workoutModel.currentWorkout];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: true),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        color: const Color(0xFFf5f4f9),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.04),
            TextCustom(text: '$currentWorkout $scenario_idx'),
            SizedBox(height: screenHeight * 0.03),

            // Stack으로 이미지와 DonutProgress 겹치기
            Container(
              height: screenHeight * 0.7,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        height: screenHeight * 0.35,
                        child: Image.asset(image_url, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Positioned(
                      top: screenHeight * 0.35,
                      left: 20,
                      child: DonutProgress(
                        progress: _progress,
                        strokeWidth: 10,
                        size: Size(screenWidth * 0.3, screenWidth * 0.3),
                        centerText: "${(workout_min * _progress).toInt()}min",
                      )),
                ],
              ),
            ),
          ],
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
                  SizedBox(height: screenHeight * 0.04),
                  RoundButton(
                    text: '운동 스킵',
                    onPressed: () async {
                      if (workoutModel.writeChar != null) {
                      } else {
                        print("writeChar is null, BLE not connected");
                      }
                      //
                      int nextWorkoutIdx = workoutModel.currentWorkout + 1;
                      if (nextWorkoutIdx >= workoutModel.workoutPlan.length) {
                        await sendCommandElexir(workoutModel.writeChar, elexir_commands["mode2"]!);
                        await sendCommandElexir(workoutModel.writeChar, elexir_commands["stop"]!);
                        await apiService.updateWorkoutEnd(userModel.userId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsPage(),
                          ),
                        );
                        //
                      } else {
                        // reset ble value
                        int intense_value_copy = intenseValue;
                        for (int i = 0; i < intenseValue; i++) {
                          await sendCommandElexir(workoutModel.writeChar, elexir_commands["intense_dw"]!);
                          intense_value_copy -= 1;
                          print('intense ${intense_value_copy}');
                          setState(() {});
                        }
                        //
                        await sendCommandElexir(workoutModel.writeChar, elexir_commands["pause"]!);
                        workoutModel.set_current_workout(nextWorkoutIdx);
                        await apiService.updateWorkoutEnd(userModel.userId);
                        Navigator.push(
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
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextCustom(text: '운동이 종료되었습니다', color: Colors.white, fontSize: 20),
                  SizedBox(height: screenHeight * 0.02),
                  RoundButton(
                    text: '다음운동',
                    onPressed: () async {
                      if (workoutModel.writeChar != null) {
                      } else {
                        print("writeChar is null, BLE not connected");
                      }
                      int nextWorkoutIdx = workoutModel.currentWorkout + 1;
                      if (nextWorkoutIdx >= workoutModel.workoutPlan.length) {
                        await sendCommandElexir(workoutModel.writeChar, elexir_commands["mode2"]!);
                        await sendCommandElexir(workoutModel.writeChar, elexir_commands["stop"]!);
                        await apiService.updateWorkoutEnd(userModel.userId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StatisticsPage()),
                        );
                        //
                      } else {
                        // reset ble value
                        int intense_value_copy = intenseValue;
                        for (int i = 0; i < intenseValue; i++) {
                          await sendCommandElexir(workoutModel.writeChar, elexir_commands["intense_dw"]!);
                          intense_value_copy -= 1;
                          print('intense ${intense_value_copy}');
                          setState(() {});
                        }
                        await sendCommandElexir(workoutModel.writeChar, elexir_commands["pause"]!);
                        workoutModel.set_current_workout(nextWorkoutIdx);
                        await apiService.updateWorkoutEnd(userModel.userId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkoutPlan(
                              explainText: '다음 운동을 진행하시려면\n 시작버튼을 눌러주세요',
                            ),
                          ),
                        );
                        //
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
