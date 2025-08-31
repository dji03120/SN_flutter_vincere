import 'package:Vincere/component/header.dart';
import 'package:Vincere/custom_widget/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/custom_widget/custom_button.dart';
import 'package:Vincere/custom_widget/custom_text.dart';
import 'package:Vincere/page_workout/page_workout_plan.dart';

class SelectMuscle extends StatefulWidget {
  const SelectMuscle({super.key});

  @override
  State<SelectMuscle> createState() => Component3State();
}

class Component3State extends State<SelectMuscle> {
  // 체크된 항목을 저장할 리스트
  List<String> selectedWorkouts = [];

  // 체크박스 항목 목록
  final List<String> workouts = [
    '상완근 10min',
    '이두근 10min',
    '삼각근 10min',
    '대흉근 10min',
    '대퇴근 10min',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final workoutModel = Provider.of<WorkoutModel>(context); // 상태 접근

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
              TextLarge(text: '운동을 수행 할 부위를 선택해주세요'),
              SizedBox(height: screenHeight * 0.08),
              // 체크 버튼들
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return RoundCheckButton(
                      text: workout,
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                      onChanged: (bool isChecked) {
                        setState(() {
                          if (isChecked) {
                            selectedWorkouts.add(workout);
                          } else {
                            selectedWorkouts.remove(workout);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                width: screenWidth / 4 * 3,
                child: RoundButton(
                  text: '운동시작',
                  onPressed: () {
                    // 선택된 항목 확인 가능
                    workoutModel.set_workouts(selectedWorkouts);
                    workoutModel.set_current_workout(0);
                    if (selectedWorkouts.length != 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutPlan(
                            explainText: '운동 계획이 설정되었습니다.\n준비가 되셨다면 시작버튼을 눌러주세요',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('운동을 한 개 이상 선택해주세요')),
                      );
                    }
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
