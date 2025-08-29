import 'package:flutter/material.dart';
import 'package:Vincere/component/bottomsheet_workout_content.dart';
import 'package:Vincere/component/progress_donut.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:Vincere/custom_widget/custom_text.dart'; // 추가

class WorkoutContent extends StatefulWidget {
  const WorkoutContent({super.key});

  @override
  State<WorkoutContent> createState() => Component3State();
}

class Component3State extends State<WorkoutContent> {
  double _progress = 1;
  Timer? _timer;
  late VideoPlayerController _videoController; // 동영상 컨트롤러
  bool isWorkoutDone = false;

  @override
  void initState() {
    super.initState();

    // VideoController 초기화
    _videoController = VideoPlayerController.asset('assets/videos/sample.mp4')
      ..initialize().then((_) {
        _startProgress();
        setState(() {}); // 초기화 완료 후 UI 갱신
        _videoController.setLooping(true); // 반복 재생
        _videoController.play(); // 자동 재생
      });
  }

  void _startProgress() {
    const step = 0.01; // 1%씩 증가
    Duration interval = Duration(milliseconds: 30); // 0.1초 간격

    _timer = Timer.periodic(interval, (timer) {
      if (_progress != 0) {
        setState(() {
          _progress -= step;
          if (_progress <= 0) {
            _progress = 0;
            isWorkoutDone = true;
          }
        });
      }
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
      appBar: AppBar(title: const Text("운동 화면")),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        child: Container(
          color: Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),
              TextTitle(text: '동작 A : example'),
              SizedBox(height: screenHeight * 0.06),
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
                    progress: _progress,
                    strokeWidth: 12,
                    size: Size(screenWidth * 0.3, screenWidth * 0.3),
                    centerText: "${(20 * _progress).toInt()}min",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: BottomsheetWorkoutContent(
        value: 3,
        isWorkoutDone: isWorkoutDone,
      ),
    );
  }
}
