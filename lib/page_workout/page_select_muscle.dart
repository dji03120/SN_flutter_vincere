import 'package:Vincere/component/header.dart';
import 'package:Vincere/component/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/component/custom_text.dart';
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
  final List<dynamic> workouts = [
    {'name': '상완근', 'service_type': '무료'},
    {'name': '삼각근', 'service_type': '무료'},
    {'name': '대퇴근', 'service_type': '무료'},
    {'name': '척추기립근', 'service_type': '유료'},
    {'name': '대퇴이두근', 'service_type': '유료'},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final workoutModel = Provider.of<WorkoutModel>(context); // 상태 접근

    return Scaffold(
      appBar: const Header(),
      //drawer: CustomDrawer(isLogin: true),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        child: Container(
          color: Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.06),
              TextCustom(text: '운동을 수행 할 부위를 선택해주세요', fontSize: 20),

              SizedBox(height: screenHeight * 0.03),
              // 체크 버튼들
              RichText(
                text: TextSpan(
                  children: [
                    if (workoutModel.workoutMode == "passive")
                      TextSpan(
                        text: workoutModel.workoutMode,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.lightBlue,
                        ),
                      ),
                    if (workoutModel.workoutMode == "active")
                      TextSpan(
                        text: workoutModel.workoutMode,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.08),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    bool isDisabled = workout['service_type'] == '유료';
                    if (isDisabled) {
                      return RoundButton(
                        text: workout['name'],
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                        onPressed: () {
                          if (workoutModel.workoutMode == "active") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('해당 서비스는 준비 중에 있습니다. \n관리자에게 요청해주세요.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('해당 서비스는 유료 모드 입니다. \n관리자에게 요청해주세요.')),
                            );
                          }
                        },
                        color: Colors.grey,
                      );
                    } else {
                      return RoundCheckButton(
                        text: workout['name'],
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        onChanged: isDisabled
                            ? null
                            : (bool isChecked) {
                                print(workout);
                                setState(() {
                                  if (isChecked) {
                                    selectedWorkouts.add(workout['name']);
                                  } else {
                                    selectedWorkouts.remove(workout['name']);
                                  }
                                });
                              },
                      );
                    }
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
                      Navigator.push(
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
              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
