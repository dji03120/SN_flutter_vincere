import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/component/custom_drawer.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/services/page_workout/page_statistics.dart';
import 'package:Vincere/services/page_workout/page_workout_plan.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/page_home/utils.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/utils/component/progress_donut.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class WorkoutContentActive extends StatefulWidget {
  const WorkoutContentActive({super.key});

  @override
  State<WorkoutContentActive> createState() => Component3State();
}

class Component3State extends State<WorkoutContentActive> {
  double _progress = 1;
  Timer? _timer;
  late VideoPlayerController _videoController; // 동영상 컨트롤러
  bool isWorkoutDone = false;
  int intenseValue = 0;
  int workout_min = 10;
  int workout_sec = 0;
  int step_count = 0;
  int mlt = 1;
  String image_url = '';

  Map<String, dynamic> workoutSetting = {};
  int scenario_idx = 1;

  //
  //
  //
  @override
  void initState() {
    super.initState();
    workout_sec = workout_min * 60;
    _initVideoController();
    _startProgress();
  }

  //
  //
  //video
  Future<void> _initVideoController() async {
    // VideoController 초기화
    _videoController = VideoPlayerController.asset('assets/videos/sample.mp4');
    await _videoController.initialize(); // ✅ 비동기 초기화
    _videoController.setLooping(true);
    _videoController.play();
    setState(() {}); // ✅ 초기화 완료 후 다시 그리기
  }

  //
  //
  // timer
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

      _progress = 1 - step_count / workout_sec; // progress update
      step_count += mlt;
      if (_progress <= 0) {
        _progress = 0; // end of workout
        isWorkoutDone = true;
      }
      setState(() {});
    });
  }

  //
  //
  //
  @override
  void dispose() {
    _videoController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  //
  //
  //
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final workoutModel = Provider.of<WorkoutModel>(context);
    final userModel = Provider.of<UserModel>(context);
    ApiService apiService = ApiService();
    String currentWorkout = workoutModel.workoutPlan[workoutModel.currentWorkout];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      appBar: const Header(),
      drawer: const CustomDrawer(isLogin: true),
      body: Stack(children: [
        Container(
            width: screenWidth,
            height: screenHeight,
            color: Color(0xFFf5f4f9),
            child: Column(children: [
              SizedBox(height: 40),
              TextCustom(text: '$currentWorkout $scenario_idx'),
              SizedBox(height: 30),
              Column(children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  width: double.infinity,
                  child: _videoController.value.isInitialized
                      ? Stack(alignment: Alignment.center, children: [
                          AspectRatio(aspectRatio: _videoController.value.aspectRatio, child: VideoPlayer(_videoController)),
                          if (!_videoController.value.isPlaying)
                            IconButton(
                                iconSize: 64,
                                color: Colors.white70,
                                icon: const Icon(Icons.play_circle),
                                onPressed: () {
                                  _videoController.play();
                                  setState(() {});
                                })
                        ])
                      : const Center(child: CircularProgressIndicator()),
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: DonutProgress(
                          progress: _progress,
                          strokeWidth: 10,
                          size: Size(screenWidth * 0.3, screenWidth * 0.3),
                          centerText: "${(workout_min * _progress).toInt()}min",
                        )))
              ])
            ])),

        // bottom sheet
        DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.25,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 111, 163, 27),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    )),
                padding: const EdgeInsets.all(30),
                child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        if (isWorkoutDone == false) workout_panel(workoutModel, context, apiService, userModel),
                        if (isWorkoutDone == true) workout_end_panel(workoutModel, context, apiService, userModel),
                      ],
                    )),
              );
            }),
      ]),
    );
  }

  //
  //
  //
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
            )));
  }

  //
  //
  //
  Widget workout_panel(
    WorkoutModel workoutModel,
    BuildContext context,
    ApiService apiService,
    UserModel userModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 손잡이 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(10),
                )),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 12), // 간격
            const TextCustom(text: '세기', color: Colors.white, fontSize: 24),
            const SizedBox(width: 30), // 간격
            controlButton(Icons.remove, () async {
              await sendCommandElexir(userModel.writeChar, elexir_commands["intense_dw"]!);
              intenseValue -= 1;
              if (intenseValue <= 0) intenseValue = 0;
              setState(() {});
            }),
            const SizedBox(width: 12), // 간격
            TextCustom(text: '$intenseValue/30', color: Colors.white),
            const SizedBox(width: 12), // 간격
            controlButton(Icons.add, () async {
              await sendCommandElexir(userModel.writeChar, elexir_commands["intense_up"]!);
              intenseValue += 1;
              if (intenseValue >= 30) intenseValue = 30;
              setState(() {});
            }),
          ],
        ),
        SizedBox(height: 10),
        buildDivider(context),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 12), // 간격
            const TextCustom(text: '시간', color: Colors.white, fontSize: 24),
            const SizedBox(width: 30), // 간격
            controlButton(Icons.remove, () async {
              workout_sec -= 60;
              workout_min -= 1;
              setState(() {});
            }),
            const SizedBox(width: 12), // 간격
            TextCustom(text: '${(step_count / 60).toInt()}/$workout_min', color: Colors.white),
            const SizedBox(width: 12), // 간격
            controlButton(Icons.add, () async {
              workout_sec += 60;
              workout_min += 1;
              setState(() {});
            }),
          ],
        ),
        SizedBox(height: 10),
        buildDivider(context),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 12), // 간격
            const TextCustom(text: '모드', color: Colors.white, fontSize: 24),
            SizedBox(width: 50), // 간격격

            if (workoutModel.workoutLevel == "mode1") TextCustom(text: '100hz', color: Colors.white),
            if (workoutModel.workoutLevel == "mode2") TextCustom(text: '60hz', color: Colors.white),
            SizedBox(width: 20), // 간격격
            Container(
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  await sendCommandElexir(userModel.writeChar, elexir_commands["pause"]!);
                  if (workoutModel.workoutLevel == "mode2") {
                    workoutModel.set_workout_level(1);
                    await sendCommandElexir(userModel.writeChar, elexir_commands[workoutModel.workoutLevel]!);
                  } else if (workoutModel.workoutLevel == "mode1") {
                    workoutModel.set_workout_level(5);
                    await sendCommandElexir(userModel.writeChar, elexir_commands[workoutModel.workoutLevel]!);
                  }
                  await sendCommandElexir(userModel.writeChar, elexir_commands["continue"]!);
                },
                style: ElevatedButton.styleFrom(
                  elevation: 6, // 그림자 높이
                  shadowColor: Colors.black.withOpacity(1),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('변경'),
              ),
            ),
          ],
        ),
        SizedBox(height: 30),
        RoundButton(
            text: '운동스킵',
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 5),
            onPressed: () async {
              if (userModel.writeChar != null) {
              } else {
                print("writeChar is null, BLE not connected");
              }
              int nextWorkoutIdx = workoutModel.currentWorkout + 1;
              if (nextWorkoutIdx >= workoutModel.workoutPlan.length) {
                await sendCommandElexir(userModel.writeChar, elexir_commands["mode2"]!);
                await sendCommandElexir(userModel.writeChar, elexir_commands["stop"]!);
                await apiService.updateWorkoutEnd(userModel.userId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsPage(),
                  ),
                );
              } else {
                // reset ble value
                int intense_value_copy = intenseValue;
                for (int i = 0; i < intenseValue; i++) {
                  await sendCommandElexir(userModel.writeChar, elexir_commands["intense_dw"]!);
                  intense_value_copy -= 1;
                  print('intense ${intense_value_copy}');
                  setState(() {});
                }
                await sendCommandElexir(userModel.writeChar, elexir_commands["pause"]!);
                workoutModel.set_current_workout(nextWorkoutIdx);
                await apiService.updateWorkoutEnd(userModel.userId);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WorkoutPlan(
                              explainText: '다음 운동을 진행하시려면\n 시작버튼을 눌러주세요',
                            )));
              }
            })
      ],
    );
  }

  //
  //
  //
  Widget workout_end_panel(
    WorkoutModel workoutModel,
    BuildContext context,
    ApiService apiService,
    UserModel userModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextCustom(
          text: '운동이 종료되었습니다',
          color: Colors.white,
          fontSize: 20,
        ),
        SizedBox(height: 10),
        RoundButton(
          text: '다음운동',
          onPressed: () async {
            if (userModel.writeChar != null) {
            } else {
              print("writeChar is null, BLE not connected");
            }
            int nextWorkoutIdx = workoutModel.currentWorkout + 1;
            if (nextWorkoutIdx >= workoutModel.workoutPlan.length) {
              await sendCommandElexir(userModel.writeChar, elexir_commands["mode2"]!);
              await sendCommandElexir(userModel.writeChar, elexir_commands["stop"]!);
              await apiService.updateWorkoutEnd(userModel.userId);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsPage()));
            } else {
              // reset ble value
              for (int i = 0; i < intenseValue; i++) {
                await sendCommandElexir(userModel.writeChar, elexir_commands["intense_dw"]!);
                setState(() {});
              }
              await sendCommandElexir(userModel.writeChar, elexir_commands["pause"]!);
              workoutModel.set_current_workout(nextWorkoutIdx);
              await apiService.updateWorkoutEnd(userModel.userId);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutPlan(explainText: '다음 운동을 진행하시려면\n 시작버튼을 눌러주세요')),
              );
            }
          },
        ),
      ],
    );
  }
}
