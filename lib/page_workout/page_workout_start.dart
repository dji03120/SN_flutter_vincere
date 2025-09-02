import 'package:Vincere/component/header.dart';
import 'package:Vincere/component/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/component/bottomsheet_workout_start.dart';
import 'package:Vincere/component/progress_donut.dart';
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
              TextLarge(text: '{사진|동영상}과 같이 장치를 부착한 뒤,\n 시작버튼을 눌러주세요'),
              SizedBox(height: screenHeight * 0.03),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                    centerText: "${(20 * 1).toInt()}min",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: BottomsheetWorkoutStart(),
    );
  }
}
