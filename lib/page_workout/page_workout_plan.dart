import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/workout/workout_provider.dart';
import 'package:Vincere/custom_widget/custom_button.dart';
import 'package:Vincere/custom_widget/custom_text.dart';
import 'package:Vincere/workout/page_workout_start.dart';

class WorkoutPlan extends StatefulWidget {
  final String explainText;
  const WorkoutPlan({super.key, this.explainText = '준비가 되셨다면 시작을 눌러주세요.'});

  @override
  State<WorkoutPlan> createState() => WorkoutPlanState();
}

class WorkoutPlanState extends State<WorkoutPlan> {
  @override
  Widget build(BuildContext context) {
    final workoutModel = Provider.of<WorkoutModel>(context); // 상태 접근
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
                      color: (workoutModel.currentWorkout != idx)
                          ? Colors.white
                          : Color(0xFFB3E5FC),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              SizedBox(
                width: screenWidth * 0.75,
                child: RoundButton(
                  text: '운동시작',
                  onPressed: () {
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
