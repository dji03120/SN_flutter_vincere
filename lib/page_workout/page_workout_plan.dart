import 'package:Vincere/component/header.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/component/custom_text.dart';
import 'package:Vincere/page_workout/page_workout_start.dart';
import 'package:Vincere/http/webReq.dart';

class WorkoutPlan extends StatefulWidget {
  final String explainText;
  const WorkoutPlan({super.key, this.explainText = '준비가 되셨다면 시작을 눌러주세요.'});

  @override
  State<WorkoutPlan> createState() => WorkoutPlanState();
}

class WorkoutPlanState extends State<WorkoutPlan> {
  final ScrollController _scrollController = ScrollController();
  void _scrollToIndex(int index) {
    final position = index * 85.0; // 아이템의 높이를 고려 (정확하게 계산 필요)
    _scrollController.animateTo(
      position,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(Provider.of<WorkoutModel>(context, listen: false).currentWorkout);
    });
  }

  @override
  Widget build(BuildContext context) {
    ApiService apiService = ApiService();
    final workoutModel = Provider.of<WorkoutModel>(context); // 상태 접근
    final userModel = Provider.of<UserModel>(context); // 상태 접근
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    String currentWorkout = workoutModel.workoutPlan[workoutModel.currentWorkout];
    Map<String, dynamic> workoutSetting = workoutModel.get_workout_config(currentWorkout, userModel.gradeAvg.toInt());

    return Scaffold(
      appBar: const Header(),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        child: Container(
          color: Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.08),
              TextCustom(text: widget.explainText, fontSize: 20),
              SizedBox(height: screenHeight * 0.06),
              // 운동 버튼 리스트
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: workoutModel.workoutPlan.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var exercise = entry.value;
                    return Container(
                      height: 70,
                      margin: EdgeInsets.fromLTRB(30, 0, 30, 15),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 6, // ✅ 그림자 높이
                          shadowColor: Colors.black.withOpacity(1),
                          backgroundColor: (workoutModel.currentWorkout != idx) ? Colors.white : Color(0xFFB3E5FC),
                          foregroundColor: Colors.black, // 글자 검정
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // round 수치
                          ),
                        ),
                        child: Text('${idx + 1}. $exercise'),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              const Text('추천 운동 강도', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: userModel.gradeAvg.toString(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF007130)),
                    ),
                    const TextSpan(text: ' 등급 ', style: TextStyle(fontSize: 22, color: Color(0xFF000000))),
                    TextSpan(
                      text: workoutSetting['name'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF007130)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),
              SizedBox(
                width: screenWidth * 0.75,
                child: RoundButton(
                  text: '운동시작',
                  onPressed: () async {
                    await apiService.updateWorkoutEnd(userModel.userId).then((_) {
                      print('DB update 완료');
                    }).catchError((e) {
                      print('DB update 실패: $e');
                    });

                    // set mode intensity
                    print(workoutModel.workoutLevel);
                    await sendCommand(workoutModel.writeChar, ble_commands[workoutModel.workoutLevel]!);
                    await sendCommand(workoutModel.writeChar, ble_commands["pause"]!);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WorkoutStart()));
                  },
                  borderRadius: 10,
                ),
              ),
              SizedBox(height: screenHeight * 0.07),
            ],
          ),
        ),
      ),
    );
  }
}
