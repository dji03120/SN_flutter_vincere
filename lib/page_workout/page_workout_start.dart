import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/component/custom_drawer.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:Vincere/page_workout/page_workout_content_active.dart';
import 'package:Vincere/page_workout/page_workout_content_passive.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/component/progress_donut.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:Vincere/component/custom_text.dart'; // 추가

class WorkoutStart extends StatefulWidget {
  const WorkoutStart({super.key});

  @override
  State<WorkoutStart> createState() => Component3State();
}

class Component3State extends State<WorkoutStart> {
  Timer? _timer;
  late VideoPlayerController _videoController; // 동영상 컨트롤러

  @override
  void initState() {
    super.initState();

    // VideoController 초기화
    _videoController = VideoPlayerController.asset('assets/videos/sample.mp4')
      ..initialize().then((_) {
        setState(() {}); // 초기화 완료 후 UI 갱신
        //_videoController.setLooping(true); // 반복 재생
        //_videoController.play(); // 자동 재생
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final workoutModel = Provider.of<WorkoutModel>(context);
    final userModel = Provider.of<UserModel>(context);
    String currentWorkout = workoutModel.workouts[workoutModel.currentWorkout];
    Map workoutSetting = workoutModel.get_workout_config(currentWorkout, userModel.gradeAvg.toInt());
    String image_url = workoutSetting['scenario1']['asset_url'];
    print('$workoutSetting, $image_url');

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
              if (workoutModel.workoutMode == "active") TextCustom(text: '영상과 같이 장치를 부착한 뒤', fontSize: 20),
              if (workoutModel.workoutMode == "passive") TextCustom(text: '사진과 같이 장치를 부착한 뒤', fontSize: 20),
              TextCustom(text: '시작버튼을 눌러주세요', fontSize: 20),
              SizedBox(height: screenHeight * 0.03),
              if (workoutModel.workoutMode == 'active')
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                      width: double.infinity,
                      child: _videoController.value.isInitialized
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: _videoController.value.aspectRatio,
                                  child: VideoPlayer(_videoController),
                                ),
                                if (!_videoController.value.isPlaying)
                                  IconButton(
                                    iconSize: 64,
                                    color: Colors.white70,
                                    icon: const Icon(Icons.play_circle),
                                    onPressed: () {
                                      setState(() {
                                        _videoController.play();
                                      });
                                    },
                                  ),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: DonutProgress(
                          progress: 1,
                          strokeWidth: 12,
                          size: Size(screenWidth * 0.3, screenWidth * 0.3),
                          centerText: "${(10 * 1).toInt()}min",
                        ),
                      ),
                    ),
                  ],
                ),
              if (workoutModel.workoutMode == 'passive')
                Container(
                  height: screenHeight * 0.45,
                  child: Image.asset(
                    image_url,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomSheet: SafeArea(
        child: Container(
          width: screenWidth,
          height: screenHeight * 0.25,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 111, 163, 27),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(text: '남은 운동 개수 : n ', color: Colors.white, fontSize: 18),
                  TextCustom(text: '남은 운동 시간 : n Min', color: Colors.white, fontSize: 18),
                  SizedBox(height: screenHeight * 0.02),
                  RoundButton(
                    text: "운동시작",
                    onPressed: () async {
                      if (workoutModel.writeChar != null) {
                        await sendCommand(workoutModel.writeChar, ble_commands["pause"]!);
                        await sendCommand(workoutModel.writeChar, ble_commands["continue"]!); // 다시시작
                      } else {
                        print("writeChar is null, BLE not connected");
                      }
                      // 운동 페이지로 이동
                      if (workoutModel.workoutMode == 'passive') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WorkoutContentPassive()));
                      }
                      if (workoutModel.workoutMode == 'active') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WorkoutContentActive()));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
