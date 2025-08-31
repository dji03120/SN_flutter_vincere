import 'package:Vincere/component/header.dart';
import 'package:Vincere/custom_widget/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/custom_widget/custom_button.dart';
import 'package:Vincere/custom_widget/custom_text.dart';
import 'package:Vincere/page_workout/page_workout_start.dart';

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
    final userModel = Provider.of<UserModel>(context); // 상태 접근
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
              SizedBox(height: screenHeight * 0.08),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 근육 나이 텍스트
                  Container(
                    alignment: Alignment.centerLeft,
                    width: MediaQuery.of(context).size.width * 0.6,
                    margin: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.06,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '내 근육 나이',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: userModel.muscleAge,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF007130),
                                ),
                              ),
                              const TextSpan(
                                text: ' 세',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 오른쪽: 이미지
                  Container(
                    width: 60,
                    height: 60,
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.06,
                    ),
                    child: Image.asset(
                      'images/body.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

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
