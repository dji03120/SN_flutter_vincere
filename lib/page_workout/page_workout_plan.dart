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
  @override
  Widget build(BuildContext context) {
    ApiService apiService = ApiService();
    final workoutModel = Provider.of<WorkoutModel>(context); // 상태 접근
    final userModel = Provider.of<UserModel>(context); // 상태 접근
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
              TextLarge(text: widget.explainText),
              SizedBox(height: screenHeight * 0.08),
              // 운동 버튼 리스트
              Expanded(
                child: ListView(
                  children: workoutModel.workouts.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var exercise = entry.value;
                    return RoundButton(
                      text: '${idx + 1}. $exercise',
                      margin: EdgeInsets.fromLTRB(20, 0, 20, 15),
                      onPressed: () {},
                      color: (workoutModel.currentWorkout != idx) ? Colors.white : Color(0xFFB3E5FC),
                    );
                  }).toList(),
                ),
              ),
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
                      text: workoutModel.workoutLevel == "mode1" ? "  (급성모드)" : "  (예방모드)",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF007130)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.04),
              SizedBox(
                width: screenWidth * 0.75,
                child: RoundButton(
                  text: '운동시작',
                  onPressed: () async {
                    await apiService.insertWorkout(
                      userModel.userId,
                      {
                        "mode": workoutModel.workoutMode,
                        "intensity": workoutModel.workoutLevel == "mode1" ? "급성모드" : "예방모드",
                        "muscle": workoutModel.workouts[workoutModel.currentWorkout],
                      }, // intensity mode1 100hz, mode2 60hz
                    );

                    // set mode intensity
                    print(workoutModel.workoutLevel);
                    await sendCommand(workoutModel.writeChar, ble_commands[workoutModel.workoutLevel]!);
                    await sendCommand(workoutModel.writeChar, ble_commands["pause"]!);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => WorkoutStart()),
                    );
                  },
                  borderRadius: 10,
                ),
              ),
              SizedBox(height: screenHeight * 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
